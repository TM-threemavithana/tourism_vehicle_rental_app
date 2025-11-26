# 🚀 Quick Test Commands Reference

## Prerequisites
Ensure server is running: `npm run start:dev`

---

## 🔧 Upload Service Testing

### Quick Test (Automated)
```powershell
.\test-upload-service.ps1
```

### Manual Tests
```powershell
# Get upload configuration
Invoke-RestMethod http://localhost:3000/api/upload/info

# Check health
Invoke-RestMethod http://localhost:3000/api/health
```

**Expected Results:**
- ✅ Server responds with upload limits
- ✅ Max size: 5MB, Max files: 10
- ✅ Allowed types: JPEG, PNG, WebP

---

## 📦 Migration Testing

### 1. Check Statistics
```powershell
.\test-migration.ps1 -Stats
```
Shows record counts in Firebase and PostgreSQL

### 2. Validate Readiness
```powershell
.\test-migration.ps1 -Validate
```
Checks if system is ready for migration

### 3. Export Backup
```powershell
.\test-migration.ps1 -Export
```
Creates JSON backup of Firebase data

### 4. Dry Run (Test Only)
```powershell
# Test all collections
.\test-migration.ps1 -DryRun

# Test specific collection
.\test-migration.ps1 -DryRun -Collection users
```

### 5. Execute Migration
```powershell
# Migrate all
.\test-migration.ps1 -Execute

# Migrate specific collection
.\test-migration.ps1 -Execute -Collection users
```

**Migration Order (recommended):**
```powershell
.\test-migration.ps1 -Execute -Collection users
.\test-migration.ps1 -Execute -Collection vehicles
.\test-migration.ps1 -Execute -Collection bookings
.\test-migration.ps1 -Execute -Collection favorites
.\test-migration.ps1 -Execute -Collection reviews
```

---

## 🔄 Integration Testing

### Quick Test (Automated)
```powershell
.\test-integration.ps1
```

### Manual Tests
```powershell
# Get all vehicles
Invoke-RestMethod http://localhost:3000/api/vehicles

# Search vehicles
Invoke-RestMethod "http://localhost:3000/api/vehicles/search?city=Boston&make=Toyota"

# Get available vehicles
Invoke-RestMethod http://localhost:3000/api/vehicles/available

# Get specific vehicle
Invoke-RestMethod http://localhost:3000/api/vehicles/<vehicle-id>
```

---

## 📊 Testing Workflow

### First Time Setup
```powershell
# 1. Start server
npm run start:dev

# 2. Run upload service test
.\test-upload-service.ps1

# 3. Check migration stats
.\test-migration.ps1 -Stats

# 4. Validate migration readiness
.\test-migration.ps1 -Validate

# 5. Backup data
.\test-migration.ps1 -Export

# 6. Dry run migration
.\test-migration.ps1 -DryRun

# 7. If dry run succeeds, execute migration
.\test-migration.ps1 -Execute

# 8. Run integration tests
.\test-integration.ps1

# 9. Verify final state
.\test-migration.ps1 -Stats
```

---

## 🔍 Quick Checks

### Server Health
```powershell
curl http://localhost:3000/api/health
```

### Database Connection
```powershell
# PostgreSQL
Invoke-RestMethod http://localhost:3000/api/users

# Should return user list or empty array
```

### Cache Connection
```powershell
# Make same request twice
Invoke-RestMethod http://localhost:3000/api/vehicles
Invoke-RestMethod http://localhost:3000/api/vehicles

# Second request should be faster (cached)
```

### Firebase Connection
```powershell
.\test-migration.ps1 -Stats

# Should show Firebase collection counts
```

---

## ⚡ Common Commands

### Create Test Vehicle
```powershell
$data = @{
    make = "Toyota"
    model = "Camry"
    year = 2023
    licensePlate = "TEST-123"
    dailyRate = 50.00
    seats = 5
    transmission = "Automatic"
    fuelType = "Gasoline"
    categoryId = "00000000-0000-0000-0000-000000000001"
    locationCity = "Boston"
    locationAddress = "123 Main St"
    locationLat = 42.3601
    locationLng = -71.0589
    description = "Test vehicle"
    features = @("GPS", "AC")
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/vehicles?ownerId=test-owner" -Method POST -Body $data -ContentType "application/json"
```

### Update Vehicle
```powershell
$update = @{ dailyRate = 60.00 } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:3000/api/vehicles/<id>" -Method PATCH -Body $update -ContentType "application/json"
```

### Delete Vehicle
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/vehicles/<id>" -Method DELETE
```

### Search Vehicles
```powershell
# By city
Invoke-RestMethod "http://localhost:3000/api/vehicles/search?city=Boston"

# By make
Invoke-RestMethod "http://localhost:3000/api/vehicles/search?make=Toyota"

# By price range
Invoke-RestMethod "http://localhost:3000/api/vehicles/search?minPrice=30&maxPrice=70"

# By seats
Invoke-RestMethod "http://localhost:3000/api/vehicles/search?seats=5"

# Combined filters
Invoke-RestMethod "http://localhost:3000/api/vehicles/search?city=Boston&make=Toyota&minPrice=40&maxPrice=60&seats=5"
```

---

## 🐛 Troubleshooting

### Server Won't Start
```powershell
# Check dependencies
npm install

# Check environment
Get-Content .env

# Check logs
npm run start:dev
# Look for specific error messages
```

### Migration Fails
```powershell
# Check Firebase config
.\test-migration.ps1 -Validate

# Check database connection
psql $env:DATABASE_URL

# Retry with specific collection
.\test-migration.ps1 -Execute -Collection users
```

### Upload Fails
```powershell
# Check configuration
Invoke-RestMethod http://localhost:3000/api/upload/info

# Check file size
Get-Item image.jpg | Select-Object Length

# Verify file type
file --mime-type image.jpg
```

---

## 📝 Expected Test Results

### Upload Service Test
```
✓ Server is running
✓ Test image created
✓ Health check passed
✓ Upload info retrieved
✓ Test vehicle created
✓ Upload endpoint exists
✓ Vehicle retrieved
✓ Vehicle search successful
```

### Migration Test (Stats)
```
Firebase Collections:
  users: 150 records
  vehicles: 85 records
  bookings: 320 records

PostgreSQL Tables:
  users: 150 records
  vehicles: 85 records
  bookings: 320 records
```

### Integration Test
```
✓ Server is healthy
✓ Created: test-vehicle-1.jpg
✓ Vehicle created: <uuid>
✓ Vehicle retrieved
✓ Vehicle found in search
✓ Upload endpoint exists
✓ Availability updated
✓ Vehicle updated
✓ Cache is working
```

---

## 📚 Additional Resources

- **Complete Testing Guide:** `COMPLETE_TESTING_GUIDE.md`
- **Migration Guide:** `MIGRATION_QUICK_START.md`
- **Upload Service Docs:** `UPLOAD_SERVICE_TESTING.md`
- **Vehicle Integration:** `VEHICLE_UPLOAD_INTEGRATION.md`

---

## ✅ Success Checklist

- [ ] Server starts without errors
- [ ] Upload service test passes
- [ ] Migration validation succeeds
- [ ] Dry run completes without errors
- [ ] Migration executes successfully
- [ ] Integration test passes
- [ ] All API endpoints respond correctly
- [ ] Cache improves performance
- [ ] Search and filters work
- [ ] Data integrity verified

---

**Quick Start:** Just run these three commands:
```powershell
.\test-upload-service.ps1
.\test-migration.ps1 -DryRun
.\test-integration.ps1
```

If all pass ✅ → Ready for `.\test-migration.ps1 -Execute`
