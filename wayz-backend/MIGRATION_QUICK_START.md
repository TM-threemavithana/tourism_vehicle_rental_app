# Firebase to PostgreSQL Migration - Quick Start

## 🚀 Quick Start (5 Minutes)

### 1. Download Firebase Service Account

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** → **Service Accounts**
4. Click **Generate New Private Key**
5. Save the JSON file as `firebase-service-account.json` in the backend root

### 2. Configure Environment

Add to `wayz-backend/.env`:

```env
# Firebase Configuration
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

### 3. Backup Your Data

```bash
cd wayz-backend

# Export Firestore data (recommended before migration)
npm run migrate:export
```

This creates `firestore-backup.json` with all your data.

### 4. Test Migration (Dry Run)

```bash
# See what would be migrated without writing to database
npm run migrate:dry-run
```

Review the output to ensure everything looks correct.

### 5. Run Migration

```bash
# Migrate all data
npm run migrate:all
```

### 6. Validate Migration

```bash
# Check data integrity
npm run migrate:validate

# View statistics
npm run migrate:stats
```

---

## 📊 Expected Output

### Dry Run Output
```
🚀 Firebase to PostgreSQL migration...
🔍 DRY RUN MODE - No data will be written

📦 Migrating collection: users
  Processing batch 1/2 (100 documents)
  Processing batch 2/2 (50 documents)
✅ users: 150/150 migrated, 0 failed

📦 Migrating collection: vehicles
  Processing batch 1/1 (89 documents)
✅ vehicles: 89/89 migrated, 0 failed

🎉 Migration completed!
Total: 534/534 documents migrated
Duration: 45.32s
```

### Stats Output
```
📊 Migration Statistics:

users:
  Total: 150
  Migrated: 150 (100.0%)

vehicles:
  Total: 89
  Migrated: 89 (100.0%)

bookings:
  Total: 234
  Migrated: 234 (100.0%)
```

---

## ⚡ Common Commands

```bash
# Full migration
npm run migrate:all

# Dry run (test without writing)
npm run migrate:dry-run

# Migrate specific collection
npm run migrate:collection users

# View statistics
npm run migrate:stats

# Validate data integrity
npm run migrate:validate

# Export/backup Firestore
npm run migrate:export

# Help
npm run migrate help
```

---

## 🔧 Advanced Options

### Custom Batch Size
```bash
npm run migrate:all -- --batch-size=50
```

### Specific Collections Only
```bash
npm run migrate:all -- --collections=users,vehicles
```

### Custom Export Path
```bash
npm run migrate:export -- --output=./backups/firestore-2024.json
```

---

## ⚠️ Important Notes

1. **Always backup first!** Run `npm run migrate:export` before migration
2. **Test with dry run:** Use `npm run migrate:dry-run` to preview
3. **Migrate in order:** The default order respects foreign key dependencies
4. **Check validation:** Run `npm run migrate:validate` after migration
5. **Monitor logs:** Watch for any errors or warnings

---

## 🆘 Troubleshooting

### "FIREBASE_SERVICE_ACCOUNT_PATH not set"
- Ensure you downloaded the service account JSON
- Add `FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json` to `.env`

### "User not found for booking"
- Migrate `users` collection first
- Use default order: `npm run migrate:all`

### "Connection refused"
- Check PostgreSQL is running
- Verify `DATABASE_*` variables in `.env`

### Out of Memory
- Reduce batch size: `npm run migrate:all -- --batch-size=25`
- Migrate one collection at a time

---

## 📖 Full Documentation

For complete details, see [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md)

---

## ✅ Migration Checklist

- [ ] Download Firebase service account JSON
- [ ] Add `FIREBASE_SERVICE_ACCOUNT_PATH` to `.env`
- [ ] Run `npm run migrate:export` (backup)
- [ ] Run `npm run migrate:dry-run` (test)
- [ ] Run `npm run migrate:all` (actual migration)
- [ ] Run `npm run migrate:validate` (check integrity)
- [ ] Run `npm run migrate:stats` (view results)
- [ ] Test application with PostgreSQL
- [ ] Monitor for issues

---

**Total Time:** ~5-10 minutes for typical dataset (< 1000 documents)

**Support:** See [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md) for detailed documentation
