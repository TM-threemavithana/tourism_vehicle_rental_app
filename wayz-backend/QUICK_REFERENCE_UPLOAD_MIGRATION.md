# 🚀 Quick Reference - Upload & Migration

## 📦 One-Command Quick Start

```bash
# 1. Install & Start
cd wayz-backend && npm install && npm run start:dev

# 2. Test Upload
curl -X POST http://localhost:3000/api/v1/upload/image -F "file=@test.jpg"

# 3. Run Migration
npm run migrate:backup && npm run migrate:dry-run && npm run migrate:run
```

---

## 🖼️ Upload Service Endpoints

```bash
# Upload single image
POST /api/v1/upload/image

# Upload multiple images
POST /api/v1/upload/images

# Delete image
DELETE /api/v1/upload/:filename

# Get stats
GET /api/v1/upload/stats

# Health check
GET /api/v1/upload/health
```

---

## 🔄 Migration Commands

```bash
# Backup Firestore data
npm run migrate:backup

# Test migration (no DB changes)
npm run migrate:dry-run

# Run actual migration
npm run migrate:run

# Validate migrated data
npm run migrate:validate

# Get statistics
npm run migrate:stats

# Export data
npm run migrate:export
```

---

## 🚗 Vehicle Image Endpoints

```bash
# Create vehicle with images
POST /api/v1/vehicles
Body: { "images": ["url1", "url2"], ... }

# Add images to vehicle
POST /api/v1/vehicles/:id/images
Form: files (multipart)

# Update vehicle images
PATCH /api/v1/vehicles/:id/images
Form: files (multipart)

# Delete vehicle images
DELETE /api/v1/vehicles/:id/images
```

---

## 🧪 Quick Test Commands

```powershell
# Windows PowerShell

# Test upload
curl -X POST http://localhost:3000/api/v1/upload/image `
  -F "file=@test-car.jpg"

# Test multiple upload
curl -X POST http://localhost:3000/api/v1/upload/images `
  -F "files=@car1.jpg" `
  -F "files=@car2.jpg"

# Create vehicle
curl -X POST http://localhost:3000/api/v1/vehicles `
  -H "Content-Type: application/json" `
  -d '{
    "make": "Toyota",
    "model": "Camry",
    "year": 2022,
    "dailyRate": 75.00,
    "images": ["http://localhost:3000/uploads/vehicles/image.jpg"]
  }'
```

---

## 📁 Important Files

```
wayz-backend/
├── .env                           # Environment variables
├── firebase-service-account.json  # Firebase credentials
├── uploads/                       # Uploaded images
├── backups/                       # Migration backups
└── src/
    ├── upload/                    # Upload service
    ├── migrations/                # Migration system
    └── vehicles/                  # Vehicles module
```

---

## ⚙️ Environment Variables

```env
# Required for Upload
UPLOAD_DESTINATION=./uploads
MAX_FILE_SIZE=10485760

# Required for Migration
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com

# Database
DATABASE_HOST=pg-4a2bf3f-wayz.k.aivencloud.com
DATABASE_PORT=17019
DATABASE_USERNAME=avnadmin
DATABASE_PASSWORD=AVNS_Yg1A9GQmC6P0ErX8msM
DATABASE_NAME=defaultdb
```

---

## 🔍 Troubleshooting

```bash
# Check server status
curl http://localhost:3000/api/v1/upload/health

# View server logs
npm run start:dev

# Rebuild dependencies
npm install
npm rebuild sharp

# Check upload directory
ls uploads/

# Check migration backups
ls backups/
```

---

## 📚 Full Documentation

- **COMPLETE_INTEGRATION_TESTING_GUIDE.md** - Complete testing guide
- **FIREBASE_SERVICE_ACCOUNT_SETUP.md** - Firebase setup
- **UPLOAD_TESTING_GUIDE.md** - Upload service testing
- **MIGRATION_QUICK_START.md** - Migration quick start
- **MIGRATION_GUIDE.md** - Complete migration guide

---

## ✅ Pre-Flight Checklist

Before running migration:

- [ ] `.env` file configured
- [ ] Firebase service account setup
- [ ] PostgreSQL database accessible
- [ ] Server running (`npm run start:dev`)
- [ ] Upload directory created
- [ ] Backup completed
- [ ] Dry run successful

---

## 🎯 Success Indicators

### Upload Service ✅
- Health endpoint returns `{"status":"ok"}`
- Images upload successfully
- Thumbnails generated
- Files in `uploads/vehicles/`

### Migration ✅
- Backup files in `backups/` directory
- Dry run shows record counts
- Migration completes with 95%+ success
- Validation passes

### Integration ✅
- Vehicles created with images
- API returns image URLs
- Images accessible via URL

---

## 🚨 Quick Fixes

```bash
# Module not found
npm install

# Sharp issues
npm rebuild sharp

# Permission denied
chmod +x uploads

# Port in use
# Change PORT in .env

# Firebase connection
# Check FIREBASE_* variables in .env
```

---

## 📞 Need Help?

1. Check [COMPLETE_INTEGRATION_TESTING_GUIDE.md](./COMPLETE_INTEGRATION_TESTING_GUIDE.md)
2. Review server logs
3. Test individual components
4. Check .env configuration

---

**Quick Start: [COMPLETE_INTEGRATION_TESTING_GUIDE.md](./COMPLETE_INTEGRATION_TESTING_GUIDE.md)**
