# 🧪 Upload Service Testing Guide

## Prerequisites

1. ✅ Backend server running
2. ✅ User account created (with OWNER or ADMIN role)
3. ✅ JWT token obtained from login
4. ✅ Test images ready

---

## Step 1: Start the Backend Server

```bash
cd wayz-backend
npm run start:dev
```

Wait for: `Application is running on: http://[::1]:3000`

---

## Step 2: Get Authentication Token

### Option A: Using Swagger UI (Easiest)

1. Open: http://localhost:3000/api/v1/docs
2. Click **"Authorize"** button (top right)
3. Login using `/auth/login` endpoint:
   ```json
   {
     "email": "your-email@example.com",
     "password": "your-password"
   }
   ```
4. Copy the `accessToken` from response
5. Paste in Authorize dialog

### Option B: Using cURL

```bash
# Register a new owner account
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "owner@example.com",
    "password": "SecurePass123!",
    "firstName": "John",
    "lastName": "Doe",
    "phoneNumber": "+1234567890",
    "role": "owner"
  }'

# Login to get token
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "owner@example.com",
    "password": "SecurePass123!"
  }'

# Save the accessToken from response
export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

---

## Step 3: Test Single Image Upload

### Using Swagger UI (Recommended)

1. Navigate to: http://localhost:3000/api/v1/docs
2. Find: `POST /upload/image`
3. Click **"Try it out"**
4. Click **"Choose File"** and select an image
5. Click **"Execute"**

### Using cURL

```bash
# Create a test image directory
mkdir -p ~/test-images

# Upload single image
curl -X POST http://localhost:3000/upload/image \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/path/to/your/image.jpg"
```

### Expected Response

```json
{
  "filename": "abc123-def456-vehicle.jpg",
  "originalName": "image.jpg",
  "url": "http://localhost:3000/uploads/abc123-def456-vehicle.jpg",
  "size": 245678,
  "mimetype": "image/jpeg",
  "thumbnails": {
    "small": "http://localhost:3000/uploads/thumbnails/small-abc123-def456-vehicle.jpg",
    "medium": "http://localhost:3000/uploads/thumbnails/medium-abc123-def456-vehicle.jpg",
    "large": "http://localhost:3000/uploads/thumbnails/large-abc123-def456-vehicle.jpg"
  }
}
```

### Verify Upload

```bash
# Check if file exists
ls -lh wayz-backend/uploads/

# Check thumbnails
ls -lh wayz-backend/uploads/thumbnails/

# View image in browser
open http://localhost:3000/uploads/abc123-def456-vehicle.jpg
```

---

## Step 4: Test Multiple Image Upload

### Using Swagger UI

1. Navigate to: `POST /upload/images`
2. Click **"Try it out"**
3. Select multiple images (up to 10)
4. Click **"Execute"**

### Using cURL

```bash
# Upload multiple images
curl -X POST http://localhost:3000/upload/images \
  -H "Authorization: Bearer $TOKEN" \
  -F "files=@/path/to/image1.jpg" \
  -F "files=@/path/to/image2.jpg" \
  -F "files=@/path/to/image3.jpg"
```

### Expected Response

```json
{
  "uploaded": [
    {
      "filename": "abc123-vehicle.jpg",
      "url": "http://localhost:3000/uploads/abc123-vehicle.jpg",
      ...
    },
    {
      "filename": "def456-vehicle.jpg",
      "url": "http://localhost:3000/uploads/def456-vehicle.jpg",
      ...
    }
  ],
  "totalUploaded": 2,
  "failed": []
}
```

---

## Step 5: Test Image Deletion

### Using Swagger UI

1. Navigate to: `DELETE /upload/:filename`
2. Enter filename from upload response
3. Click **"Execute"**

### Using cURL

```bash
# Delete single image
curl -X DELETE http://localhost:3000/upload/abc123-vehicle.jpg \
  -H "Authorization: Bearer $TOKEN"
```

### Expected Response

```json
{
  "message": "File deleted successfully",
  "filename": "abc123-vehicle.jpg"
}
```

---

## Step 6: Test Image Serving

### View Uploaded Images

```bash
# Open in browser
open http://localhost:3000/uploads/abc123-vehicle.jpg

# Or use cURL to download
curl http://localhost:3000/uploads/abc123-vehicle.jpg --output test-download.jpg
```

### View Thumbnails

```bash
# Small thumbnail (200x200)
open http://localhost:3000/uploads/thumbnails/small-abc123-vehicle.jpg

# Medium thumbnail (400x400)
open http://localhost:3000/uploads/thumbnails/medium-abc123-vehicle.jpg

# Large thumbnail (800x800)
open http://localhost:3000/uploads/thumbnails/large-abc123-vehicle.jpg
```

---

## Step 7: Test Error Handling

### Test File Size Limit (5MB)

```bash
# Create large test file (6MB)
dd if=/dev/zero of=large-image.jpg bs=1M count=6

# Try to upload (should fail)
curl -X POST http://localhost:3000/upload/image \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@large-image.jpg"
```

Expected error:
```json
{
  "statusCode": 413,
  "message": "File too large. Maximum size is 5MB"
}
```

### Test Invalid File Type

```bash
# Try to upload PDF
curl -X POST http://localhost:3000/upload/image \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@document.pdf"
```

Expected error:
```json
{
  "statusCode": 400,
  "message": "Invalid file type. Only JPEG, PNG, and WebP images are allowed"
}
```

### Test Unauthorized Access

```bash
# Try without token
curl -X POST http://localhost:3000/upload/image \
  -F "file=@image.jpg"
```

Expected error:
```json
{
  "statusCode": 401,
  "message": "Unauthorized"
}
```

---

## Step 8: Performance Testing

### Upload Multiple Large Images

```bash
# Create test images
for i in {1..5}; do
  curl -X POST http://localhost:3000/upload/image \
    -H "Authorization: Bearer $TOKEN" \
    -F "file=@test-image-$i.jpg"
done
```

### Check Processing Time

Watch server logs for processing times:
```
[UploadService] Processing image: test-image.jpg
[ImageProcessingService] Optimizing image...
[ImageProcessingService] Generated thumbnail small (200x200) in 45ms
[ImageProcessingService] Generated thumbnail medium (400x400) in 67ms
[ImageProcessingService] Generated thumbnail large (800x800) in 89ms
[UploadService] Image processed successfully in 234ms
```

---

## Step 9: Integration Test with Vehicles

### Create Vehicle with Images

```bash
# 1. Upload images first
RESPONSE=$(curl -s -X POST http://localhost:3000/upload/images \
  -H "Authorization: Bearer $TOKEN" \
  -F "files=@image1.jpg" \
  -F "files=@image2.jpg")

# Extract URLs from response
IMAGE_URLS=$(echo $RESPONSE | jq -r '.uploaded[].url')

# 2. Create vehicle with image URLs
curl -X POST http://localhost:3000/vehicles \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"make\": \"Toyota\",
    \"model\": \"Camry\",
    \"year\": 2023,
    \"dailyRate\": 75,
    \"images\": $(echo $IMAGE_URLS | jq -R -s -c 'split("\n") | map(select(length > 0))')
  }"
```

---

## Automated Test Script

Save as `test-upload-service.sh`:

```bash
#!/bin/bash

# Upload Service Test Script
echo "🧪 Testing Upload Service..."

# Configuration
BASE_URL="http://localhost:3000"
TEST_IMAGE="test-vehicle.jpg"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

# Function to run test
run_test() {
    local test_name=$1
    local command=$2
    local expected_code=$3
    
    echo -n "Testing: $test_name... "
    
    response=$(eval $command)
    status=$?
    
    if [ $status -eq 0 ] && [ -n "$expected_code" ]; then
        http_code=$(echo "$response" | tail -1)
        if [ "$http_code" = "$expected_code" ]; then
            echo -e "${GREEN}✓ PASSED${NC}"
            ((PASSED++))
        else
            echo -e "${RED}✗ FAILED${NC} (Expected: $expected_code, Got: $http_code)"
            ((FAILED++))
        fi
    elif [ $status -eq 0 ]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((FAILED++))
    fi
}

# 1. Check if server is running
run_test "Server Health Check" \
    "curl -s -o /dev/null -w '%{http_code}' $BASE_URL/health" \
    "200"

# 2. Login and get token
echo -n "Getting authentication token... "
TOKEN=$(curl -s -X POST $BASE_URL/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"owner@example.com","password":"SecurePass123!"}' \
    | jq -r '.accessToken')

if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Failed to get token${NC}"
    exit 1
fi

# 3. Create test image
if [ ! -f "$TEST_IMAGE" ]; then
    echo "Creating test image..."
    convert -size 800x600 xc:blue $TEST_IMAGE 2>/dev/null || \
    curl -s "https://via.placeholder.com/800x600" -o $TEST_IMAGE
fi

# 4. Test single upload
run_test "Single Image Upload" \
    "curl -s -X POST $BASE_URL/upload/image \
        -H 'Authorization: Bearer $TOKEN' \
        -F 'file=@$TEST_IMAGE' \
        -w '%{http_code}' -o /dev/null" \
    "201"

# 5. Test multiple upload
run_test "Multiple Image Upload" \
    "curl -s -X POST $BASE_URL/upload/images \
        -H 'Authorization: Bearer $TOKEN' \
        -F 'files=@$TEST_IMAGE' \
        -F 'files=@$TEST_IMAGE' \
        -w '%{http_code}' -o /dev/null" \
    "201"

# 6. Test unauthorized access
run_test "Unauthorized Access (should fail)" \
    "curl -s -X POST $BASE_URL/upload/image \
        -F 'file=@$TEST_IMAGE' \
        -w '%{http_code}' -o /dev/null" \
    "401"

# Summary
echo ""
echo "========================"
echo "Test Summary:"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo "========================"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed! ✓${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed! ✗${NC}"
    exit 1
fi
```

Run the test script:
```bash
chmod +x test-upload-service.sh
./test-upload-service.sh
```

---

## Troubleshooting

### Issue: "Cannot find module 'sharp'"

**Solution:**
```bash
cd wayz-backend
npm install sharp
npm run start:dev
```

### Issue: "ENOENT: no such file or directory, open './uploads/...'"

**Solution:**
```bash
# Create uploads directory
mkdir -p wayz-backend/uploads/thumbnails
```

### Issue: "401 Unauthorized"

**Solution:**
- Verify token is valid and not expired
- Check user role is 'owner' or 'admin'
- Re-login to get fresh token

### Issue: "File too large"

**Solution:**
- Check file size: `ls -lh image.jpg`
- Compress image before uploading
- Or increase limit in `.env`: `MAX_FILE_SIZE=10485760` (10MB)

---

## Success Criteria

✅ **Upload service is working when:**
- Single image uploads successfully
- Multiple images upload successfully
- Thumbnails are generated (3 sizes)
- Images are viewable in browser
- File deletion works
- Proper error messages for invalid inputs
- Authentication/authorization works

---

## Next Steps

After successful testing:
1. ✅ Integrate with vehicles module
2. ✅ Run migration from Firebase
3. 🚀 Deploy to production

**Ready to move to integration!** 🎉
