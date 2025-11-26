# Firebase to PostgreSQL Migration Guide

This guide covers the complete process of migrating data from Firebase Firestore to PostgreSQL.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Setup](#setup)
3. [Migration Process](#migration-process)
4. [CLI Commands](#cli-commands)
5. [API Endpoints](#api-endpoints)
6. [Troubleshooting](#troubleshooting)
7. [Rollback Strategy](#rollback-strategy)

---

## Prerequisites

### Required Files

1. **Firebase Service Account JSON**
   - Download from Firebase Console → Project Settings → Service Accounts
   - Save as `firebase-service-account.json` in the backend root directory

2. **Environment Variables**
   ```env
   # Add to .env file
   FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
   ```

### Database Setup

Ensure your PostgreSQL database is running and properly configured:
```env
DATABASE_HOST=your-host
DATABASE_PORT=5432
DATABASE_NAME=your-db-name
DATABASE_USER=your-username
DATABASE_PASSWORD=your-password
```

---

## Setup

### 1. Install Dependencies

Already installed:
- `firebase-admin` - For Firebase Admin SDK
- `@nestjs/typeorm` - For database operations
- `typeorm` - ORM
- `pg` - PostgreSQL driver

### 2. Initialize Firebase Admin SDK

The migration service automatically initializes Firebase using your service account JSON.

### 3. Add Migration Module to App

Update `src/app.module.ts`:

```typescript
import { MigrationModule } from './migrations/migration.module';

@Module({
  imports: [
    // ... other imports
    MigrationModule,
  ],
})
export class AppModule {}
```

---

## Migration Process

### Step 1: Backup Firebase Data

**Always backup your Firestore data before migration!**

```bash
# Export all Firestore collections to JSON
npm run migrate export

# Export specific collections
npm run migrate export --collections=users,vehicles --output=./backup.json
```

### Step 2: Dry Run

Test the migration without writing to PostgreSQL:

```bash
# Dry run all collections
npm run migrate all --dry-run

# Dry run specific collections
npm run migrate all --dry-run --collections=users,vehicles
```

### Step 3: Run Migration

Migrate data in the recommended order (respects foreign key dependencies):

```bash
# Migrate all collections (recommended order)
npm run migrate all

# Migrate with custom batch size
npm run migrate all --batch-size=50

# Migrate specific collections
npm run migrate all --collections=users,vehicles,bookingRequests
```

**Default Migration Order:**
1. `users` - User accounts
2. `vehicles` - Vehicle listings
3. `bookingRequests` - Booking data
4. `favorites` - User favorites
5. `ratings` - Reviews and ratings

### Step 4: Validate Migration

Check data integrity after migration:

```bash
npm run migrate validate
```

This checks for:
- Users without Firebase UID
- Orphaned bookings (missing user or vehicle)
- Orphaned vehicles (missing owner)

### Step 5: Check Statistics

View migration statistics:

```bash
npm run migrate stats
```

---

## CLI Commands

### Migrate All Collections

```bash
npm run migrate all [options]
```

**Options:**
- `--dry-run` - Run without writing to database
- `--batch-size=<number>` - Set batch size (default: 100)
- `--collections=<list>` - Comma-separated collection names

**Examples:**
```bash
# Standard migration
npm run migrate all

# Dry run
npm run migrate all --dry-run

# Custom batch size
npm run migrate all --batch-size=50

# Specific collections only
npm run migrate all --collections=users,vehicles
```

### Migrate Single Collection

```bash
npm run migrate collection <collection-name> [--dry-run]
```

**Examples:**
```bash
npm run migrate collection users
npm run migrate collection vehicles --dry-run
```

### Show Statistics

```bash
npm run migrate stats
```

Shows:
- Total documents per collection
- Migrated documents count
- Migration percentage

### Validate Migration

```bash
npm run migrate validate
```

Performs integrity checks on migrated data.

### Export Firestore Data

```bash
npm run migrate export [options]
```

**Options:**
- `--output=<path>` - Output file path (default: `./firestore-backup.json`)
- `--collections=<list>` - Collections to export

**Examples:**
```bash
# Export all collections
npm run migrate export

# Export to custom path
npm run migrate export --output=./backups/firestore-2024.json

# Export specific collections
npm run migrate export --collections=users,vehicles
```

### Help

```bash
npm run migrate help
```

---

## API Endpoints

### Migrate All Data

**POST** `/migration/migrate-all`

```bash
curl -X POST http://localhost:3000/migration/migrate-all \
  -H "Content-Type: application/json" \
  -d '{
    "batchSize": 100,
    "dryRun": false,
    "collections": ["users", "vehicles"]
  }'
```

**Response:**
```json
{
  "startTime": "2024-01-15T10:00:00.000Z",
  "endTime": "2024-01-15T10:05:30.000Z",
  "duration": 330000,
  "collections": [
    {
      "collection": "users",
      "total": 150,
      "migrated": 150,
      "failed": 0,
      "errors": []
    }
  ],
  "totalDocuments": 150,
  "totalMigrated": 150,
  "totalFailed": 0,
  "status": "completed"
}
```

### Migrate Single Document

**POST** `/migration/migrate-document`

```bash
curl -X POST http://localhost:3000/migration/migrate-document \
  -H "Content-Type: application/json" \
  -d '{
    "collection": "users",
    "documentId": "firebase-uid-123"
  }'
```

### Get Migration Statistics

**GET** `/migration/stats`

```bash
curl http://localhost:3000/migration/stats
```

**Response:**
```json
{
  "users": [{ "total": "150", "migrated": "150" }],
  "vehicles": [{ "total": "89", "migrated": "89" }],
  "bookings": [{ "total": "234", "migrated": "230" }]
}
```

### Validate Migration

**GET** `/migration/validate`

```bash
curl http://localhost:3000/migration/validate
```

**Response:**
```json
{
  "isValid": false,
  "issues": [
    {
      "type": "bookings",
      "message": "4 orphaned bookings found"
    }
  ]
}
```

### Export Firestore to JSON

**POST** `/migration/export-firestore?outputPath=./backup.json`

```bash
curl -X POST "http://localhost:3000/migration/export-firestore?outputPath=./backup.json" \
  -H "Content-Type: application/json" \
  -d '{ "collections": ["users", "vehicles"] }'
```

---

## Data Mapping

### Firebase ↔ PostgreSQL Field Mapping

#### Users Collection

| Firebase Field | PostgreSQL Field | Type | Notes |
|---------------|------------------|------|-------|
| `uid` | `firebase_uid` | varchar(255) | Unique identifier |
| `email` | `email` | varchar(255) | Unique |
| `displayName` | `first_name`, `last_name` | varchar(100) | Split on space |
| `phoneNumber` | `phone_number` | varchar(20) | |
| `photoURL` | `profile_image_url` | text | |
| `role` | `role` | enum | Mapped to customer/owner/admin |
| `emailVerified` | `email_verified`, `is_email_verified` | boolean | |
| `createdAt` | `created_at` | timestamptz | |

#### Vehicles Collection

| Firebase Field | PostgreSQL Field | Type | Notes |
|---------------|------------------|------|-------|
| `docId` | `firebase_doc_id` | varchar(255) | Document ID |
| `make` | `make` | varchar(50) | |
| `model` | `model` | varchar(100) | |
| `year` | `year` | integer | |
| `vehicleNo` | `license_plate` | varchar(20) | |
| `ownerId` (Firebase UID) | `owner_id` (UUID) | uuid | Resolved via users table |
| `collectionPoint.city` | `location_city` | varchar(100) | |
| `collectionPoint.address` | `location_address` | text | |
| `dailyPricing.baseRate` | `daily_rate` | decimal(10,2) | |
| `images[]` | `images` | jsonb | Array of URLs |
| `isAvailable` | `is_available` | boolean | |

#### Bookings Collection

| Firebase Field | PostgreSQL Field | Type | Notes |
|---------------|------------------|------|-------|
| `docId` | `firebase_doc_id` | varchar(255) | |
| `userId` (Firebase UID) | `user_id` (UUID) | uuid | Resolved |
| `vehicleId` (Firebase doc ID) | `vehicle_id` (UUID) | uuid | Resolved |
| `startDate` | `start_date` | timestamptz | |
| `endDate` | `end_date` | timestamptz | |
| `status` | `status` | enum | Mapped to enum values |
| `paymentStatus` | `payment_status` | enum | Mapped to enum values |
| `totalAmount` | `total_amount` | decimal(10,2) | |

---

## Troubleshooting

### Common Issues

#### 1. Firebase Service Account Error

**Error:** `FIREBASE_SERVICE_ACCOUNT_PATH not set`

**Solution:**
1. Download service account JSON from Firebase Console
2. Add to `.env`:
   ```env
   FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
   ```

#### 2. Orphaned Records

**Error:** `User not found for booking`

**Solution:**
- Migrate `users` collection first
- Check Firebase UIDs match between collections
- Use `npm run migrate validate` to find orphaned records

#### 3. Date Parsing Errors

**Error:** `Invalid date format`

**Solution:**
- The migrator handles multiple Firebase timestamp formats
- Check the `parseDate()` function in migrators
- Verify timestamp field names in Firebase

#### 4. Duplicate Key Violations

**Error:** `duplicate key value violates unique constraint`

**Solution:**
- The migrator checks for existing records before inserting
- Clear PostgreSQL tables if re-running migration
- Use `--dry-run` to test first

#### 5. Out of Memory

**Error:** `JavaScript heap out of memory`

**Solution:**
- Reduce batch size: `--batch-size=50`
- Migrate collections one at a time
- Increase Node.js memory: `NODE_OPTIONS=--max-old-space-size=4096 npm run migrate all`

### Enable Debug Logging

Add to `.env`:
```env
LOG_LEVEL=debug
```

---

## Rollback Strategy

### Before Migration

1. **Backup Firebase Data**
   ```bash
   npm run migrate export --output=./pre-migration-backup.json
   ```

2. **Backup PostgreSQL Database**
   ```bash
   pg_dump -U your_user -d your_db > backup.sql
   ```

### Rollback PostgreSQL

```bash
# Drop all migrated data
psql -U your_user -d your_db -c "TRUNCATE users, vehicles, bookings, favorites, reviews CASCADE;"

# Or restore from backup
psql -U your_user -d your_db < backup.sql
```

### Re-migration

If migration fails or needs to be rerun:

1. Clear PostgreSQL tables
2. Fix the issue
3. Run migration again (migrator will skip existing records)

---

## Post-Migration Steps

### 1. Verify Data Integrity

```bash
npm run migrate validate
```

### 2. Update Application Configuration

Switch your application to use PostgreSQL:

```typescript
// Before (Firebase)
const users = await firebase.firestore().collection('users').get();

// After (PostgreSQL)
const users = await this.userRepository.find();
```

### 3. Dual-Write Period (Optional)

Consider running both Firebase and PostgreSQL in parallel for a transition period:
- Write to both databases
- Read from PostgreSQL
- Compare data periodically
- Decommission Firebase when confident

### 4. Monitor Performance

- Watch PostgreSQL query performance
- Add indexes as needed
- Monitor memory and CPU usage
- Set up alerts for errors

---

## Package.json Scripts

Add these scripts to `wayz-backend/package.json`:

```json
{
  "scripts": {
    "migrate": "ts-node src/migrate.ts",
    "migrate:all": "ts-node src/migrate.ts all",
    "migrate:collection": "ts-node src/migrate.ts collection",
    "migrate:stats": "ts-node src/migrate.ts stats",
    "migrate:validate": "ts-node src/migrate.ts validate",
    "migrate:export": "ts-node src/migrate.ts export"
  }
}
```

---

## Support

For issues or questions:
1. Check this guide's troubleshooting section
2. Review the migration logs
3. Check Firebase and PostgreSQL connection status
4. Verify service account permissions

---

## Migration Checklist

- [ ] Backup Firebase data
- [ ] Backup PostgreSQL database
- [ ] Set `FIREBASE_SERVICE_ACCOUNT_PATH` in `.env`
- [ ] Test connection to both databases
- [ ] Run dry run migration
- [ ] Review dry run results
- [ ] Run actual migration
- [ ] Validate migration
- [ ] Check migration statistics
- [ ] Test application with PostgreSQL
- [ ] Monitor for issues
- [ ] Decommission Firebase (when ready)

---

**Last Updated:** January 2025
