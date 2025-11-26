# 🚀 Complete Integration & Testing Guide

This guide covers testing the upload service, running the migration, and integrating everything together.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Upload Service Testing](#upload-service-testing)
3. [Migration System Testing](#migration-system-testing)
4. [Integration Testing](#integration-testing)
5. [Production Checklist](#production-checklist)

---

## 🎯 Prerequisites

### 1. Environment Setup

Ensure your `.env` file has all required variables:

```bash
# Check .env file
cat wayz-backend/.env
```

Required variables:
- ✅ PostgreSQL connection (DATABASE_*)
- ✅ Redis connection (REDIS_*)
- ✅ JWT secrets (JWT_*)
- ✅ Firebase credentials (FIREBASE_*)
- ✅ Upload configuration (UPLOAD_DESTINATION, MAX_FILE_SIZE)

### 2. Install Dependencies

```bash
cd wayz-backend
npm install
```

### 3. Start the Server

```bash
# Development mode with hot reload
npm run start:dev
```

Verify server is running:
- Server should start on http://localhost:3000
- Swagger docs at http://localhost:3000/api

### 4. Create Upload Directory

```bash
# Windows PowerShell
New-Item -ItemType Directory -Force -Path "wayz-backend\uploads"
New-Item -ItemType Directory -Force -Path "wayz-backend\uploads\vehicles"
New-Item -ItemType Directory -Force -Path "wayz-backend\uploads\thumbnails"

# Linux/Mac
mkdir -p wayz-backend/uploads/vehicles
mkdir -p wayz-backend/uploads/thumbnails
```

---

## 🖼️ Upload Service Testing

### Test 1: Health Check

```bash
# Test upload service health
curl http://localhost:3000/api/v1/upload/health

# Expected response:
# {
#   "status": "ok",
#   "storage": "local",
#   "uploadDir": "./uploads"
# }
```

### Test 2: Storage Stats

```bash
# Get storage statistics
curl http://localhost:3000/api/v1/upload/stats

# Expected response:
# {
#   "totalFiles": 0,
#   "totalSize": 0,
#   "avgFileSize": 0
# }
```

### Test 3: Single Image Upload

**Using curl (Windows PowerShell):**

```powershell
# Prepare a test image
# Download or use any image file, save as test-car.jpg

# Upload single image
curl -X POST http://localhost:3000/api/v1/upload/image `
  -H "Content-Type: multipart/form-data" `
  -F "file=@test-car.jpg"
```

**Using curl (Linux/Mac):**

```bash
curl -X POST http://localhost:3000/api/v1/upload/image \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test-car.jpg"
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "filename": "1234567890-abcdef-test-car.jpg",
    "path": "./uploads/vehicles/1234567890-abcdef-test-car.jpg",
    "url": "http://localhost:3000/uploads/vehicles/1234567890-abcdef-test-car.jpg",
    "thumbnailUrl": "http://localhost:3000/uploads/thumbnails/thumb-1234567890-abcdef-test-car.jpg",
    "size": 123456,
    "width": 1920,
    "height": 1080
  }
}
```

### Test 4: Multiple Images Upload

```powershell
# Windows PowerShell
curl -X POST http://localhost:3000/api/v1/upload/images `
  -H "Content-Type: multipart/form-data" `
  -F "files=@test-car-1.jpg" `
  -F "files=@test-car-2.jpg" `
  -F "files=@test-car-3.jpg"
```

```bash
# Linux/Mac
curl -X POST http://localhost:3000/api/v1/upload/images \
  -H "Content-Type: multipart/form-data" \
  -F "files=@test-car-1.jpg" \
  -F "files=@test-car-2.jpg" \
  -F "files=@test-car-3.jpg"
```

### Test 5: Using Postman

1. **Open Postman**
2. **Create New Request**
   - Method: `POST`
   - URL: `http://localhost:3000/api/v1/upload/image`

3. **Set Headers**
   - Remove `Content-Type` (Postman sets it automatically)

4. **Body Tab**
   - Select "form-data"
   - Key: `file` (change type to "File")
   - Value: Select your image file

5. **Send Request**

### Test 6: With Authentication (Optional)

Once auth is set up, test with JWT:

```bash
# Get JWT token first (login)
TOKEN="your-jwt-token-here"

# Upload with authentication
curl -X POST http://localhost:3000/api/v1/upload/image \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@test-car.jpg"
```

### Test 7: Delete Image

```bash
# Delete an uploaded image
curl -X DELETE http://localhost:3000/api/v1/upload/image-filename.jpg
```

---

## 🔄 Migration System Testing

### Step 1: Setup Firebase Service Account

**Follow the detailed guide:**
See [FIREBASE_SERVICE_ACCOUNT_SETUP.md](./FIREBASE_SERVICE_ACCOUNT_SETUP.md)

**Quick setup:**
1. Download service account JSON from Firebase Console
2. Save as `wayz-backend/firebase-service-account.json`
3. Update `.env` with Firebase credentials

### Step 2: Backup Firestore Data

```bash
# Create backup of all Firestore data
npm run migrate:backup

# Output location: wayz-backend/backups/backup-YYYYMMDD-HHMMSS/
```

**Verify backup:**
```bash
# Check backup directory
ls wayz-backend/backups/

# Should contain:
# - users.json
# - vehicles.json
# - bookings.json
# - favorites.json
# - reviews.json
```

### Step 3: Dry Run Migration

**Test migration without affecting database:**

```bash
npm run migrate:dry-run

# This will:
# ✓ Read from Firebase
# ✓ Transform data
# ✓ Log what would be migrated
# ✗ NOT save to PostgreSQL
```

**Review dry run output:**
```
📊 Migration Dry Run Statistics:
- Users: 150 records ready to migrate
- Vehicles: 45 records ready to migrate
- Bookings: 200 records ready to migrate
- Favorites: 89 records ready to migrate
- Reviews: 120 records ready to migrate
```

### Step 4: Run Actual Migration

**⚠️ IMPORTANT: Backup PostgreSQL before running!**

```bash
# Backup PostgreSQL (recommended)
pg_dump -h pg-4a2bf3f-wayz.k.aivencloud.com \
  -p 17019 \
  -U avnadmin \
  -d defaultdb \
  > postgres-backup-before-migration.sql

# Run migration
npm run migrate:run
```

**Monitor migration progress:**
```
🚀 Starting Migration...
✅ Users: 150/150 migrated successfully
✅ Vehicles: 45/45 migrated successfully
✅ Bookings: 198/200 migrated (2 skipped - missing references)
✅ Favorites: 89/89 migrated successfully
✅ Reviews: 120/120 migrated successfully

📊 Migration Summary:
- Total: 602/604 records migrated
- Success Rate: 99.7%
- Duration: 45 seconds
```

### Step 5: Validate Migration

```bash
# Validate data integrity
npm run migrate:validate

# This checks:
# ✓ Record counts match
# ✓ Foreign keys are valid
# ✓ Required fields are present
# ✓ Data types are correct
```

**Expected output:**
```
✅ Validation passed!
- All record counts match
- All foreign keys valid
- No data corruption detected
```

### Step 6: Check Migration Statistics

```bash
# View detailed statistics
npm run migrate:stats
```

### Step 7: Export Data (Optional)

```bash
# Export PostgreSQL data for review
npm run migrate:export

# Output location: wayz-backend/exports/export-YYYYMMDD-HHMMSS/
```

---

## 🔗 Integration Testing

### Test 1: Create Vehicle with Images

**Step 1: Upload Images First**

```bash
# Upload vehicle images
curl -X POST http://localhost:3000/api/v1/upload/images \
  -F "files=@car-front.jpg" \
  -F "files=@car-side.jpg" \
  -F "files=@car-interior.jpg"
```

**Save the returned URLs:**
```json
{
  "success": true,
  "data": [
    {
      "url": "http://localhost:3000/uploads/vehicles/123-car-front.jpg",
      "thumbnailUrl": "http://localhost:3000/uploads/thumbnails/thumb-123-car-front.jpg"
    },
    {
      "url": "http://localhost:3000/uploads/vehicles/124-car-side.jpg",
      "thumbnailUrl": "http://localhost:3000/uploads/thumbnails/thumb-124-car-side.jpg"
    },
    {
      "url": "http://localhost:3000/uploads/vehicles/125-car-interior.jpg",
      "thumbnailUrl": "http://localhost:3000/uploads/thumbnails/thumb-125-car-interior.jpg"
    }
  ]
}
```

**Step 2: Create Vehicle with Image URLs**

```bash
curl -X POST http://localhost:3000/api/v1/vehicles \
  -H "Content-Type: application/json" \
  -d '{
    "make": "Toyota",
    "model": "Camry",
    "year": 2022,
    "color": "White",
    "dailyRate": 75.00,
    "seats": 5,
    "fuelType": "gasoline",
    "transmission": "automatic",
    "description": "Comfortable sedan perfect for city driving",
    "locationCity": "New York",
    "locationLat": 40.7128,
    "locationLng": -74.0060,
    "images": [
      "http://localhost:3000/uploads/vehicles/123-car-front.jpg",
      "http://localhost:3000/uploads/vehicles/124-car-side.jpg",
      "http://localhost:3000/uploads/vehicles/125-car-interior.jpg"
    ],
    "features": ["AC", "GPS", "Bluetooth", "USB"],
    "securityDeposit": 200.00,
    "rules": "No smoking, No pets"
  }'
```

### Test 2: Add Images to Existing Vehicle

```bash
# Get vehicle ID from previous step
VEHICLE_ID="your-vehicle-uuid"

# Upload and add more images
curl -X POST http://localhost:3000/api/v1/vehicles/$VEHICLE_ID/images \
  -F "files=@additional-car-photo.jpg"
```

### Test 3: Update Vehicle Images

```bash
# Replace all images
curl -X PATCH http://localhost:3000/api/v1/vehicles/$VEHICLE_ID/images \
  -F "files=@new-photo-1.jpg" \
  -F "files=@new-photo-2.jpg"
```

### Test 4: Delete Vehicle Images

```bash
# Remove all images from vehicle
curl -X DELETE http://localhost:3000/api/v1/vehicles/$VEHICLE_ID/images
```

### Test 5: Search Vehicles with Images

```bash
# Get all vehicles (includes images)
curl http://localhost:3000/api/v1/vehicles

# Search vehicles
curl "http://localhost:3000/api/v1/vehicles/search?city=New%20York&minPrice=50&maxPrice=100"
```

### Test 6: Get Single Vehicle with Images

```bash
curl http://localhost:3000/api/v1/vehicles/$VEHICLE_ID
```

---

## 🧪 Automated Testing Script

Create a PowerShell test script `test-integration.ps1`:

```powershell
# test-integration.ps1
$BASE_URL = "http://localhost:3000/api/v1"

Write-Host "🧪 Testing Upload Service..." -ForegroundColor Cyan

# Test 1: Health Check
Write-Host "`n✓ Test 1: Health Check" -ForegroundColor Green
$response = Invoke-RestMethod -Uri "$BASE_URL/upload/health"
Write-Host "  Status: $($response.status)"

# Test 2: Upload Image
Write-Host "`n✓ Test 2: Upload Image" -ForegroundColor Green
$form = @{
    file = Get-Item -Path "test-car.jpg"
}
$response = Invoke-RestMethod -Uri "$BASE_URL/upload/image" -Method Post -Form $form
$imageUrl = $response.data.url
Write-Host "  Image URL: $imageUrl"

# Test 3: Create Vehicle
Write-Host "`n✓ Test 3: Create Vehicle with Image" -ForegroundColor Green
$vehicleData = @{
    make = "Toyota"
    model = "Camry"
    year = 2022
    dailyRate = 75.00
    images = @($imageUrl)
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "$BASE_URL/vehicles" -Method Post `
    -ContentType "application/json" -Body $vehicleData
$vehicleId = $response.id
Write-Host "  Vehicle ID: $vehicleId"

# Test 4: Get Vehicle
Write-Host "`n✓ Test 4: Get Vehicle" -ForegroundColor Green
$response = Invoke-RestMethod -Uri "$BASE_URL/vehicles/$vehicleId"
Write-Host "  Images count: $($response.images.Length)"

Write-Host "`n✅ All tests passed!" -ForegroundColor Green
```

Run the script:
```powershell
.\test-integration.ps1
```

---

## ✅ Production Checklist

### Before Deploying to Production

- [ ] **Environment Variables**
  - [ ] All .env variables set correctly
  - [ ] Production database credentials
  - [ ] Strong JWT secrets
  - [ ] Production Firebase credentials

- [ ] **Storage**
  - [ ] Cloud storage configured (S3/Azure/GCS)
  - [ ] CDN setup for image serving
  - [ ] Backup strategy in place

- [ ] **Database**
  - [ ] PostgreSQL backup before migration
  - [ ] Migration dry run successful
  - [ ] Migration validation passed
  - [ ] Indexes created for performance

- [ ] **Security**
  - [ ] JWT authentication working
  - [ ] Role-based access control (RBAC) enabled
  - [ ] File upload size limits enforced
  - [ ] File type validation active
  - [ ] Rate limiting configured

- [ ] **Monitoring**
  - [ ] Error logging configured
  - [ ] Performance monitoring setup
  - [ ] Storage usage alerts
  - [ ] Database connection pool monitoring

- [ ] **Testing**
  - [ ] All upload endpoints tested
  - [ ] All vehicle endpoints tested
  - [ ] Migration validated
  - [ ] Load testing completed

### Post-Migration Tasks

- [ ] Verify all data migrated correctly
- [ ] Test critical user flows
- [ ] Monitor error rates
- [ ] Check storage usage
- [ ] Update API documentation
- [ ] Train team on new endpoints

---

## 🐛 Troubleshooting

### Upload Service Issues

**Issue: "MulterError: Unexpected field"**
```
Solution: Check form field name is 'file' or 'files'
```

**Issue: "File too large"**
```
Solution: Adjust MAX_FILE_SIZE in .env
```

**Issue: "Sharp installation error"**
```bash
# Rebuild sharp
npm rebuild sharp
```

### Migration Issues

**Issue: "Firebase connection failed"**
```
Solution: Check FIREBASE_SERVICE_ACCOUNT_SETUP.md
```

**Issue: "Duplicate key error"**
```bash
# Clear PostgreSQL data and re-run
npm run migrate:run --force
```

**Issue: "Foreign key constraint failed"**
```
Solution: Migration handles this automatically,
check logs for skipped records
```

### Integration Issues

**Issue: "Vehicle images not showing"**
```
1. Check image URLs are stored correctly
2. Verify uploads directory is accessible
3. Check server static file serving
```

---

## 📊 Success Metrics

After completing all tests, you should see:

✅ Upload Service
- Health endpoint returning 200
- Images uploaded successfully
- Thumbnails generated
- Files stored in correct directories

✅ Migration System
- All Firestore data backed up
- 95%+ migration success rate
- Validation checks passing
- Foreign keys resolved

✅ Integration
- Vehicles created with images
- Images can be added/updated/deleted
- API responses include image URLs
- Frontend can display images

---

## 📚 Next Steps

1. **Frontend Integration**
   - Update Flutter app to use new upload endpoints
   - Implement image gallery UI
   - Add image upload flow

2. **Production Deployment**
   - Set up cloud storage (AWS S3/Azure Blob)
   - Configure CDN
   - Set up SSL certificates
   - Enable monitoring

3. **Advanced Features**
   - Image compression settings
   - Watermarking
   - Face detection/blurring
   - Image moderation

---

## 📞 Support

If you encounter issues:
1. Check server logs: `wayz-backend/logs/`
2. Review API documentation: `http://localhost:3000/api`
3. See troubleshooting guides in documentation folder

## 📖 Related Documentation

- [UPLOAD_TESTING_GUIDE.md](./UPLOAD_TESTING_GUIDE.md) - Upload service testing
- [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md) - Migration documentation
- [FIREBASE_SERVICE_ACCOUNT_SETUP.md](./FIREBASE_SERVICE_ACCOUNT_SETUP.md) - Firebase setup
- [API_REFERENCE_DAY4.md](./API_REFERENCE_DAY4.md) - API documentation

---

**Good luck! 🚀**
