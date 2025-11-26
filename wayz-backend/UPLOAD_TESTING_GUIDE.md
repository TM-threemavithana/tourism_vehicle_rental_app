# Quick Test Guide - Upload Service

## Prerequisites
1. Backend server running: `npm run start:dev`
2. Valid JWT token from login/register
3. Test images ready (JPEG, PNG, or WebP)

## Step-by-Step Testing

### 1. Start the Server
```powershell
cd wayz-backend
npm run start:dev
```

Wait for: `Application is running on: http://localhost:3000`

### 2. Get Authentication Token

First, register or login to get a JWT token:

**Register (if needed):**
```powershell
$body = @{
    email = "testowner@example.com"
    password = "Password123!"
    firstName = "Test"
    lastName = "Owner"
    phoneNumber = "+1234567890"
    role = "owner"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/register" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"

$token = $response.access_token
Write-Host "Token: $token"
```

**Or Login:**
```powershell
$body = @{
    email = "testowner@example.com"
    password = "Password123!"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"

$token = $response.access_token
Write-Host "Token: $token"
```

### 3. Test Single Image Upload

Create a test image or use an existing one:

```powershell
# Set your token
$token = "YOUR_TOKEN_HERE"

# Upload single image
$imagePath = "C:\path\to\your\test-image.jpg"
$boundary = [System.Guid]::NewGuid().ToString()

$headers = @{
    "Authorization" = "Bearer $token"
}

$response = Invoke-RestMethod -Uri "http://localhost:3000/api/upload/vehicle-image" `
    -Method Post `
    -Headers $headers `
    -InFile $imagePath `
    -ContentType "multipart/form-data"

$response | ConvertTo-Json -Depth 10
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Image uploaded successfully",
  "data": {
    "filename": "abc123-vehicle.jpg",
    "path": "/uploads/vehicles/abc123-vehicle.jpg",
    "url": "http://localhost:3000/uploads/vehicles/abc123-vehicle.jpg",
    "size": 245678,
    "mimetype": "image/jpeg",
    "thumbnailUrl": "http://localhost:3000/uploads/vehicles/thumb_abc123-vehicle.jpg"
  }
}
```

### 4. Verify Files Created

Check that files were created:
```powershell
Get-ChildItem "wayz-backend\uploads\vehicles" | Select-Object Name, Length, LastWriteTime
```

You should see:
- Original image: `{uuid}-vehicle.jpg`
- Thumbnail: `thumb_{uuid}-vehicle.jpg`

### 5. Test View Image in Browser

Open browser and go to:
```
http://localhost:3000/uploads/vehicles/abc123-vehicle.jpg
http://localhost:3000/uploads/vehicles/thumb_abc123-vehicle.jpg
```

### 6. Test Storage Statistics

```powershell
$response = Invoke-RestMethod -Uri "http://localhost:3000/api/upload/storage-stats" `
    -Method Get `
    -Headers @{ "Authorization" = "Bearer $token" }

$response | ConvertTo-Json
```

**Expected Response:**
```json
{
  "totalFiles": 2,
  "totalSize": 346789,
  "formattedSize": "338.66 KB"
}
```

### 7. Test Multiple Image Upload

```powershell
# This requires more complex multipart form data
# Use Postman or curl for easier testing
```

**Using curl (if installed):**
```bash
curl -X POST http://localhost:3000/api/upload/vehicle-images \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "images=@test1.jpg" \
  -F "images=@test2.jpg" \
  -F "images=@test3.jpg"
```

### 8. Test Delete Image

```powershell
$filename = "abc123-vehicle.jpg"  # Replace with actual filename

$response = Invoke-RestMethod -Uri "http://localhost:3000/api/upload/vehicle-image/$filename" `
    -Method Delete `
    -Headers @{ "Authorization" = "Bearer $token" }

$response | ConvertTo-Json
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Image deleted successfully",
  "filename": "abc123-vehicle.jpg"
}
```

### 9. Verify Deletion

```powershell
Get-ChildItem "wayz-backend\uploads\vehicles" | Select-Object Name
```

The deleted files should no longer appear.

## Using Postman (Recommended)

### Single Upload
1. Create new request: `POST http://localhost:3000/api/upload/vehicle-image`
2. Authorization tab: Type = "Bearer Token", Token = your JWT
3. Body tab: Select "form-data"
4. Add key: `image`, Type: "File", Value: select your image
5. Click Send

### Multiple Upload
1. Create new request: `POST http://localhost:3000/api/upload/vehicle-images`
2. Authorization: Same as above
3. Body: form-data
4. Add key: `images`, Type: "File", Value: select first image
5. Click `+` to add more `images` keys with different files
6. Click Send

## Common Issues & Solutions

### 1. "Unauthorized" Error
- **Problem:** Token expired or invalid
- **Solution:** Login again to get fresh token

### 2. "No file uploaded" Error
- **Problem:** Form field name doesn't match
- **Solution:** Ensure field name is exactly `image` (singular) or `images` (multiple)

### 3. "File too large" Error
- **Problem:** File exceeds 5MB limit
- **Solution:** Use smaller image or adjust MAX_FILE_SIZE in .env

### 4. Upload folder not created
- **Problem:** Permission issues
- **Solution:** Server creates it automatically, check file permissions

### 5. Thumbnail not generated
- **Problem:** Sharp installation issue
- **Solution:** Run `npm install sharp --save` again

## Integration with Vehicles

Once uploads work, integrate with vehicle creation:

```typescript
// In vehicles.controller.ts
@Post()
async create(@Body() createVehicleDto: CreateVehicleDto) {
  // 1. Upload images first
  // 2. Get filenames from upload response
  // 3. Create vehicle with image URLs
  
  createVehicleDto.images = [
    'http://localhost:3000/uploads/vehicles/abc123-vehicle.jpg',
    'http://localhost:3000/uploads/vehicles/def456-vehicle.jpg'
  ];
  
  return this.vehiclesService.create(createVehicleDto);
}
```

## Next Steps After Testing

1. ✅ Verify all endpoints work
2. ✅ Check images are optimized (smaller file size)
3. ✅ Confirm thumbnails generated
4. ✅ Test with various image formats
5. ✅ Integrate with vehicle CRUD operations
6. ✅ Add to Swagger documentation
7. ✅ Deploy to production

---

**Status**: Ready for testing
**Estimated Test Time**: 15-20 minutes
