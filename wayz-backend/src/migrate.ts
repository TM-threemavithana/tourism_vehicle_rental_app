#!/usr/bin/env node

/**
 * Firebase to PostgreSQL Migration CLI Tool
 * 
 * Usage:
 *   npm run migrate:all                    - Migrate all collections
 *   npm run migrate:all -- --dry-run       - Dry run (no data written)
 *   npm run migrate:collection users       - Migrate specific collection
 *   npm run migrate:stats                  - Show migration statistics
 *   npm run migrate:validate               - Validate migration integrity
 *   npm run migrate:export                 - Export Firestore to JSON backup
 */

import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { MigrationService } from './migrations/migration.service';
import * as dotenv from 'dotenv';

// Load environment variables
dotenv.config();

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error', 'warn', 'log'],
  });

  const migrationService = app.get(MigrationService);
  const args = process.argv.slice(2);
  const command = args[0];

  try {
    console.log('🚀 Firebase to PostgreSQL Migration Tool\n');

    switch (command) {
      case 'all':
      case 'migrate-all':
        await migrateAll(migrationService, args);
        break;

      case 'collection':
      case 'migrate-collection':
        await migrateCollection(migrationService, args);
        break;

      case 'stats':
      case 'statistics':
        await showStats(migrationService);
        break;

      case 'validate':
      case 'check':
        await validateMigration(migrationService);
        break;

      case 'export':
      case 'backup':
        await exportFirestore(migrationService, args);
        break;

      case 'help':
      case '--help':
      case '-h':
        showHelp();
        break;

      default:
        console.error(`❌ Unknown command: ${command}`);
        showHelp();
        process.exit(1);
    }

    await app.close();
    console.log('\n✅ Done!');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    await app.close();
    process.exit(1);
  }
}

async function migrateAll(migrationService: MigrationService, args: string[]) {
  const dryRun = args.includes('--dry-run') || args.includes('-d');
  const batchSize = parseInt(
    args.find((arg) => arg.startsWith('--batch-size='))?.split('=')[1] || '100',
  );
  const collections = args
    .find((arg) => arg.startsWith('--collections='))
    ?.split('=')[1]
    .split(',');

  console.log('📦 Starting full migration...');
  if (dryRun) {
    console.log('🔍 DRY RUN MODE - No data will be written\n');
  }

  const summary = await migrationService.migrateAll({
    batchSize,
    dryRun,
    collections,
  });

  console.log('\n📊 Migration Summary:');
  console.log(`Status: ${summary.status}`);
  console.log(`Duration: ${(summary.duration! / 1000).toFixed(2)}s`);
  console.log(`Total Documents: ${summary.totalDocuments}`);
  console.log(`Migrated: ${summary.totalMigrated}`);
  console.log(`Failed: ${summary.totalFailed}`);

  if (summary.totalFailed > 0) {
    console.log('\n⚠️  Failed Documents:');
    summary.collections.forEach((col) => {
      if (col.failed > 0) {
        console.log(`\n${col.collection}:`);
        col.errors.slice(0, 10).forEach((err) => {
          console.log(`  - ${err.docId}: ${err.error}`);
        });
        if (col.errors.length > 10) {
          console.log(`  ... and ${col.errors.length - 10} more`);
        }
      }
    });
  }
}

async function migrateCollection(
  migrationService: MigrationService,
  args: string[],
) {
  const collection = args[1];

  if (!collection) {
    console.error('❌ Please specify a collection name');
    console.log(
      'Usage: npm run migrate:collection <collection-name> [--dry-run]',
    );
    process.exit(1);
  }

  const dryRun = args.includes('--dry-run') || args.includes('-d');

  console.log(`📦 Migrating collection: ${collection}`);
  if (dryRun) {
    console.log('🔍 DRY RUN MODE\n');
  }

  await migrationService.migrateAll({
    collections: [collection],
    dryRun,
  });
}

async function showStats(migrationService: MigrationService) {
  console.log('📊 Migration Statistics:\n');

  const stats = await migrationService.getMigrationStats();

  Object.entries(stats).forEach(([collection, data]: [string, any]) => {
    const total = parseInt(data[0].total);
    const migrated = parseInt(data[0].migrated);
    const percentage = total > 0 ? ((migrated / total) * 100).toFixed(1) : '0';

    console.log(`${collection}:`);
    console.log(`  Total: ${total}`);
    console.log(`  Migrated: ${migrated} (${percentage}%)`);
    console.log('');
  });
}

async function validateMigration(migrationService: MigrationService) {
  console.log('🔍 Validating migration integrity...\n');

  const result = await migrationService.validateMigration();

  if (result.isValid) {
    console.log('✅ Migration validation passed!');
    console.log('No issues found.');
  } else {
    console.log('⚠️  Migration validation found issues:\n');
    result.issues.forEach((issue) => {
      console.log(`[${issue.type}] ${issue.message}`);
    });
    process.exit(1);
  }
}

async function exportFirestore(
  migrationService: MigrationService,
  args: string[],
) {
  const outputPath =
    args.find((arg) => arg.startsWith('--output='))?.split('=')[1] ||
    './firestore-backup.json';

  const collections = args
    .find((arg) => arg.startsWith('--collections='))
    ?.split('=')[1]
    .split(',');

  console.log(`📁 Exporting Firestore data to: ${outputPath}\n`);

  await migrationService.exportFirestoreToJson(outputPath, collections);

  console.log('✅ Export completed successfully!');
}

function showHelp() {
  console.log(`
Firebase to PostgreSQL Migration Tool

USAGE:
  npm run migrate <command> [options]

COMMANDS:
  all, migrate-all              Migrate all collections
  collection <name>             Migrate specific collection
  stats, statistics             Show migration statistics
  validate, check               Validate migration integrity
  export, backup                Export Firestore to JSON backup
  help, --help, -h              Show this help message

OPTIONS:
  --dry-run, -d                 Run without writing to database
  --batch-size=<number>         Set batch size (default: 100)
  --collections=<list>          Comma-separated list of collections
  --output=<path>               Output path for export (default: ./firestore-backup.json)

EXAMPLES:
  # Migrate all data
  npm run migrate all

  # Dry run to see what would be migrated
  npm run migrate all --dry-run

  # Migrate specific collections
  npm run migrate all --collections=users,vehicles

  # Migrate single collection
  npm run migrate collection users

  # Show statistics
  npm run migrate stats

  # Validate migration
  npm run migrate validate

  # Export Firestore data
  npm run migrate export --output=./backup.json

ENVIRONMENT VARIABLES:
  FIREBASE_SERVICE_ACCOUNT_PATH  Path to Firebase service account JSON file
  DATABASE_URL                   PostgreSQL connection string

For more information, see: README_BACKEND_MIGRATION.md
`);
}

bootstrap();
