import { Injectable, Logger } from '@nestjs/common';
import { DataSource, QueryRunner } from 'typeorm';
import { FirebaseService } from './firebase.service';

@Injectable()
export class DualWriteService {
  private readonly logger = new Logger(DualWriteService.name);

  constructor(
    private readonly dataSource: DataSource,
    private readonly firebaseService: FirebaseService,
  ) {}

  /**
   * Execute a dual-write operation that writes to both PostgreSQL and Firestore
   */
  async executeDualWrite<T>(
    operation: (queryRunner: QueryRunner) => Promise<T>,
    firebaseOperation?: () => Promise<void>,
  ): Promise<T> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // 1. Execute PostgreSQL operation first
      const result = await operation(queryRunner);

      // 2. Execute Firebase operation if provided and Firebase is initialized
      if (firebaseOperation && this.firebaseService.isInitialized) {
        try {
          await firebaseOperation();
          this.logger.log('Successfully wrote to both PostgreSQL and Firebase');
        } catch (firebaseError: unknown) {
          const errorMessage =
            firebaseError instanceof Error
              ? firebaseError.message
              : 'Unknown error';
          this.logger.warn(
            'PostgreSQL operation succeeded but Firebase operation failed:',
            errorMessage,
          );
        }
      } else if (firebaseOperation && !this.firebaseService.isInitialized) {
        this.logger.log(
          'Firebase not initialized. Writing only to PostgreSQL.',
        );
      }

      // 3. Commit PostgreSQL transaction
      await queryRunner.commitTransaction();
      return result;
    } catch (error) {
      // Rollback on PostgreSQL errors
      await queryRunner.rollbackTransaction();
      this.logger.error('Dual-write operation failed:', error);
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Create a record in both PostgreSQL and Firebase
   */
  async createDualWrite<T>(
    pgOperation: (queryRunner: QueryRunner) => Promise<T>,
    firebaseCollection: string,
    firebaseData: any,
    firebaseDocId?: string,
  ): Promise<T> {
    return this.executeDualWrite(pgOperation, async () => {
      await this.firebaseService.createFirestoreDocument(
        firebaseCollection,
        firebaseData,
        firebaseDocId,
      );
    });
  }

  /**
   * Update a record in both PostgreSQL and Firebase
   */
  async updateDualWrite<T>(
    pgOperation: (queryRunner: QueryRunner) => Promise<T>,
    firebaseCollection: string,
    firebaseDocId: string,
    firebaseData: any,
  ): Promise<T> {
    return this.executeDualWrite(pgOperation, async () => {
      await this.firebaseService.updateFirestoreDocument(
        firebaseCollection,
        firebaseDocId,
        firebaseData,
      );
    });
  }

  /**
   * Delete a record from both PostgreSQL and Firebase
   */
  async deleteDualWrite<T>(
    pgOperation: (queryRunner: QueryRunner) => Promise<T>,
    firebaseCollection: string,
    firebaseDocId: string,
  ): Promise<T> {
    return this.executeDualWrite(pgOperation, async () => {
      await this.firebaseService.deleteFirestoreDocument(
        firebaseCollection,
        firebaseDocId,
      );
    });
  }

  /**
   * Check if dual-write is enabled (Firebase is initialized)
   */
  get isDualWriteEnabled(): boolean {
    return this.firebaseService.isInitialized;
  }

  /**
   * Log dual-write status for debugging
   */
  logDualWriteStatus() {
    if (this.isDualWriteEnabled) {
      this.logger.log('✅ Dual-write enabled: PostgreSQL + Firebase');
    } else {
      this.logger.log('ℹ️  Dual-write disabled: PostgreSQL only');
    }
  }
}
