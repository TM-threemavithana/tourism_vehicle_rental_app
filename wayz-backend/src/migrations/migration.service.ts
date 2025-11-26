import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import * as admin from 'firebase-admin';
import { UserMigrator } from './migrators/user.migrator';
import { VehicleMigrator } from './migrators/vehicle.migrator';
import { BookingMigrator } from './migrators/booking.migrator';
import { FavoriteMigrator } from './migrators/favorite.migrator';
import { ReviewMigrator } from './migrators/review.migrator';

export interface MigrationProgress {
  collection: string;
  total: number;
  migrated: number;
  failed: number;
  errors: Array<{ docId: string; error: string }>;
}

export interface MigrationSummary {
  startTime: Date;
  endTime?: Date;
  duration?: number;
  collections: MigrationProgress[];
  totalDocuments: number;
  totalMigrated: number;
  totalFailed: number;
  status: 'in_progress' | 'completed' | 'failed';
}

@Injectable()
export class MigrationService {
  private readonly logger = new Logger(MigrationService.name);
  private firestore: admin.firestore.Firestore;

  constructor(
    private dataSource: DataSource,
    private userMigrator: UserMigrator,
    private vehicleMigrator: VehicleMigrator,
    private bookingMigrator: BookingMigrator,
    private favoriteMigrator: FavoriteMigrator,
    private reviewMigrator: ReviewMigrator,
  ) {
    this.initializeFirebase();
  }

  private initializeFirebase(): void {
    try {
      // Check if Firebase is already initialized
      if (admin.apps.length === 0) {
        // Initialize Firebase Admin SDK
        const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
        
        if (!serviceAccountPath) {
          this.logger.warn(
            'FIREBASE_SERVICE_ACCOUNT_PATH not set. Firebase migration will not be available.',
          );
          return;
        }

        admin.initializeApp({
          credential: admin.credential.cert(serviceAccountPath),
        });
        
        this.logger.log('✅ Firebase Admin SDK initialized successfully');
      }
      
      this.firestore = admin.firestore();
    } catch (error) {
      this.logger.error('Failed to initialize Firebase Admin SDK:', error);
      throw error;
    }
  }

  /**
   * Migrate all data from Firebase Firestore to PostgreSQL
   */
  async migrateAll(
    options: {
      batchSize?: number;
      dryRun?: boolean;
      collections?: string[];
    } = {},
  ): Promise<MigrationSummary> {
    const {
      batchSize = 100,
      dryRun = false,
      collections = ['users', 'vehicles', 'bookingRequests', 'favorites', 'ratings'],
    } = options;

    const summary: MigrationSummary = {
      startTime: new Date(),
      collections: [],
      totalDocuments: 0,
      totalMigrated: 0,
      totalFailed: 0,
      status: 'in_progress',
    };

    this.logger.log('🚀 Starting Firebase to PostgreSQL migration...');
    if (dryRun) {
      this.logger.log('🔍 DRY RUN MODE - No data will be written to PostgreSQL');
    }

    try {
      // Migrate in order to handle foreign key dependencies
      for (const collectionName of collections) {
        this.logger.log(`\n📦 Migrating collection: ${collectionName}`);
        
        const progress = await this.migrateCollection(
          collectionName,
          batchSize,
          dryRun,
        );
        
        summary.collections.push(progress);
        summary.totalDocuments += progress.total;
        summary.totalMigrated += progress.migrated;
        summary.totalFailed += progress.failed;

        this.logger.log(
          `✅ ${collectionName}: ${progress.migrated}/${progress.total} migrated, ${progress.failed} failed`,
        );
      }

      summary.endTime = new Date();
      summary.duration = summary.endTime.getTime() - summary.startTime.getTime();
      summary.status = summary.totalFailed > 0 ? 'completed' : 'completed';

      this.logger.log('\n🎉 Migration completed!');
      this.logger.log(`Total: ${summary.totalMigrated}/${summary.totalDocuments} documents migrated`);
      this.logger.log(`Duration: ${(summary.duration / 1000).toFixed(2)}s`);

      if (summary.totalFailed > 0) {
        this.logger.warn(`⚠️  ${summary.totalFailed} documents failed to migrate`);
      }

      return summary;
    } catch (error) {
      summary.status = 'failed';
      summary.endTime = new Date();
      summary.duration = summary.endTime.getTime() - summary.startTime.getTime();
      
      this.logger.error('❌ Migration failed:', error);
      throw error;
    }
  }

  /**
   * Migrate a specific collection
   */
  private async migrateCollection(
    collectionName: string,
    batchSize: number,
    dryRun: boolean,
  ): Promise<MigrationProgress> {
    const progress: MigrationProgress = {
      collection: collectionName,
      total: 0,
      migrated: 0,
      failed: 0,
      errors: [],
    };

    try {
      const snapshot = await this.firestore.collection(collectionName).get();
      progress.total = snapshot.size;

      if (progress.total === 0) {
        this.logger.log(`  ℹ️  No documents found in ${collectionName}`);
        return progress;
      }

      // Process in batches
      const batches = this.chunkArray(snapshot.docs, batchSize);

      for (let i = 0; i < batches.length; i++) {
        const batch = batches[i];
        this.logger.log(
          `  Processing batch ${i + 1}/${batches.length} (${batch.length} documents)`,
        );

        for (const doc of batch) {
          try {
            const data = doc.data();
            const migrator = this.getMigrator(collectionName);

            if (!migrator) {
              this.logger.warn(`  No migrator found for collection: ${collectionName}`);
              progress.failed++;
              continue;
            }

            if (!dryRun) {
              await migrator.migrate(doc.id, data as any);
            }

            progress.migrated++;
          } catch (error) {
            progress.failed++;
            progress.errors.push({
              docId: doc.id,
              error: error.message || 'Unknown error',
            });
            this.logger.error(`  ❌ Failed to migrate document ${doc.id}:`, error.message);
          }
        }
      }

      return progress;
    } catch (error) {
      this.logger.error(`Failed to migrate collection ${collectionName}:`, error);
      throw error;
    }
  }

  /**
   * Migrate a single document by collection and ID
   */
  async migrateSingleDocument(
    collectionName: string,
    documentId: string,
  ): Promise<void> {
    this.logger.log(`Migrating single document: ${collectionName}/${documentId}`);

    try {
      const doc = await this.firestore
        .collection(collectionName)
        .doc(documentId)
        .get();

      if (!doc.exists) {
        throw new Error(`Document not found: ${collectionName}/${documentId}`);
      }

      const migrator = this.getMigrator(collectionName);
      if (!migrator) {
        throw new Error(`No migrator found for collection: ${collectionName}`);
      }

      await migrator.migrate(doc.id, doc.data() as any);
      this.logger.log(`✅ Successfully migrated ${collectionName}/${documentId}`);
    } catch (error) {
      this.logger.error(
        `Failed to migrate document ${collectionName}/${documentId}:`,
        error,
      );
      throw error;
    }
  }

  /**
   * Get migration statistics from PostgreSQL
   */
  async getMigrationStats(): Promise<any> {
    const stats = {
      users: await this.dataSource.query(
        'SELECT COUNT(*) as total, COUNT(firebase_uid) as migrated FROM users',
      ),
      vehicles: await this.dataSource.query(
        'SELECT COUNT(*) as total, COUNT(firebase_doc_id) as migrated FROM vehicles',
      ),
      bookings: await this.dataSource.query(
        'SELECT COUNT(*) as total, COUNT(firebase_doc_id) as migrated FROM bookings',
      ),
      favorites: await this.dataSource.query('SELECT COUNT(*) as total FROM favorites'),
      reviews: await this.dataSource.query(
        'SELECT COUNT(*) as total, COUNT(firebase_doc_id) as migrated FROM reviews',
      ),
    };

    return stats;
  }

  /**
   * Validate migrated data integrity
   */
  async validateMigration(): Promise<{
    isValid: boolean;
    issues: Array<{ type: string; message: string }>;
  }> {
    const issues: Array<{ type: string; message: string }> = [];

    try {
      // Check for users without firebase_uid
      const usersWithoutFirebase = await this.dataSource.query(
        'SELECT COUNT(*) as count FROM users WHERE firebase_uid IS NULL',
      );
      if (usersWithoutFirebase[0].count > 0) {
        issues.push({
          type: 'users',
          message: `${usersWithoutFirebase[0].count} users without Firebase UID`,
        });
      }

      // Check for orphaned bookings (bookings without valid user or vehicle)
      const orphanedBookings = await this.dataSource.query(`
        SELECT COUNT(*) as count FROM bookings b
        WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = b.user_id)
           OR NOT EXISTS (SELECT 1 FROM vehicles v WHERE v.id = b.vehicle_id)
      `);
      if (orphanedBookings[0].count > 0) {
        issues.push({
          type: 'bookings',
          message: `${orphanedBookings[0].count} orphaned bookings found`,
        });
      }

      // Check for orphaned vehicles (vehicles without valid owner)
      const orphanedVehicles = await this.dataSource.query(`
        SELECT COUNT(*) as count FROM vehicles v
        WHERE v.owner_id IS NOT NULL 
          AND NOT EXISTS (SELECT 1 FROM users u WHERE u.id = v.owner_id)
      `);
      if (orphanedVehicles[0].count > 0) {
        issues.push({
          type: 'vehicles',
          message: `${orphanedVehicles[0].count} orphaned vehicles found`,
        });
      }

      return {
        isValid: issues.length === 0,
        issues,
      };
    } catch (error) {
      this.logger.error('Failed to validate migration:', error);
      throw error;
    }
  }

  /**
   * Get the appropriate migrator for a collection
   */
  private getMigrator(
    collectionName: string,
  ):
    | UserMigrator
    | VehicleMigrator
    | BookingMigrator
    | FavoriteMigrator
    | ReviewMigrator
    | null {
    switch (collectionName) {
      case 'users':
        return this.userMigrator;
      case 'vehicles':
        return this.vehicleMigrator;
      case 'bookingRequests':
      case 'bookings':
        return this.bookingMigrator;
      case 'favorites':
        return this.favoriteMigrator;
      case 'ratings':
      case 'reviews':
        return this.reviewMigrator;
      default:
        return null;
    }
  }

  /**
   * Split array into chunks
   */
  private chunkArray<T>(array: T[], size: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }

  /**
   * Export Firestore data to JSON (for backup)
   */
  async exportFirestoreToJson(
    outputPath: string,
    collections?: string[],
  ): Promise<void> {
    const collectionsToExport =
      collections || ['users', 'vehicles', 'bookingRequests', 'favorites', 'ratings'];

    const exportData: any = {};

    for (const collectionName of collectionsToExport) {
      this.logger.log(`Exporting collection: ${collectionName}`);
      const snapshot = await this.firestore.collection(collectionName).get();
      
      exportData[collectionName] = snapshot.docs.map((doc) => ({
        id: doc.id,
        data: doc.data(),
      }));

      this.logger.log(`  ✅ Exported ${snapshot.size} documents from ${collectionName}`);
    }

    const fs = await import('fs/promises');
    await fs.writeFile(outputPath, JSON.stringify(exportData, null, 2));
    this.logger.log(`\n📁 Export saved to: ${outputPath}`);
  }
}
