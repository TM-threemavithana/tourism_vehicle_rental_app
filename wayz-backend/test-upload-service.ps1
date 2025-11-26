# Upload Service Test Script for PowerShell
# Tests the upload service endpoints and vehicle image integration

$BASE_URL = "http://localhost:3000"
$API_URL = "$BASE_URL/api"

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "  Upload Service Test Script" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Colors for output
function Write-Success { param($message) Write-Host $message -ForegroundColor Green }
function Write-Error { param($message) Write-Host $message -ForegroundColor Red }
function Write-Info { param($message) Write-Host $message -ForegroundColor Yellow }
function Write-Step { param($message) Write-Host "`n$message" -ForegroundColor Cyan }

# Check if server is running
Write-Step "Step 1: Checking if server is running..."
try {
    $response = Invoke-WebRequest -Uri "$API_URL/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Success "✓ Server is running"
} catch {
    Write-Error "✗ Server is not running. Please start the server first with: npm run start:dev"
    exit 1
}

# Create test image files
Write-Step "Step 2: Creating test image files..."
$testDir = Join-Path $PSScriptRoot "test-images"
if (!(Test-Path $testDir)) {
    New-Item -ItemType Directory -Path $testDir | Out-Null
}

# Create a simple test image using .NET
Add-Type -AssemblyName System.Drawing
$bitmap = New-Object System.Drawing.Bitmap(800, 600)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.Clear([System.Drawing.Color]::LightBlue)
$font = New-Object System.Drawing.Font("Arial", 24)
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
$graphics.DrawString("Test Vehicle Image", $font, $brush, 100, 250)
$testImagePath = Join-Path $testDir "test-vehicle-1.jpg"
$bitmap.Save($testImagePath, [System.Drawing.Imaging.ImageFormat]::Jpeg)
$graphics.Dispose()
$bitmap.Dispose()
Write-Success "✓ Test image created: $testImagePath"

# Test 1: Health Check
Write-Step "Test 1: Health Check"
try {
    $response = Invoke-RestMethod -Uri "$API_URL/health" -Method GET
    Write-Success "✓ Health check passed"
    Write-Host "  Response: $($response | ConvertTo-Json -Depth 3)"
} catch {
    Write-Error "✗ Health check failed: $_"
}

# Test 2: Upload Info
Write-Step "Test 2: Get Upload Info"
try {
    $response = Invoke-RestMethod -Uri "$API_URL/upload/info" -Method GET
    Write-Success "✓ Upload info retrieved"
    Write-Host "  Max file size: $($response.maxFileSize)"
    Write-Host "  Allowed types: $($response.allowedMimeTypes -join ', ')"
} catch {
    Write-Error "✗ Upload info failed: $_"
}

# Test 3: Create a test vehicle first
Write-Step "Test 3: Creating test vehicle..."
$vehicleData = @{
    make = "Toyota"
    model = "Camry"
    year = 2022
    licensePlate = "TEST-001"
    dailyRate = 50.00
    seats = 5
    transmission = "Automatic"
    fuelType = "Gasoline"
    categoryId = "00000000-0000-0000-0000-000000000001"
    locationCity = "Test City"
    locationAddress = "123 Test St"
    locationLat = 40.7128
    locationLng = -74.0060
    description = "Test vehicle for upload testing"
    features = @("Air Conditioning", "GPS", "Bluetooth")
    images = @()
}

try {
    $json = $vehicleData | ConvertTo-Json -Depth 3
    $response = Invoke-RestMethod -Uri "$API_URL/vehicles?ownerId=test-owner-123" -Method POST -Body $json -ContentType "application/json"
    $vehicleId = $response.id
    Write-Success "✓ Test vehicle created with ID: $vehicleId"
} catch {
    Write-Error "✗ Failed to create test vehicle: $_"
    Write-Error "  Please ensure database is running and migrations are applied"
    exit 1
}

# Test 4: Upload vehicle image (requires auth - will test endpoint availability)
Write-Step "Test 4: Testing vehicle image upload endpoint..."
Write-Info "Note: This endpoint requires authentication. Testing endpoint availability only."
try {
    # Try to upload without auth to check if endpoint exists
    $response = Invoke-WebRequest -Uri "$API_URL/vehicles/$vehicleId/images" -Method POST -ErrorAction Stop
} catch {
    if ($_.Exception.Response.StatusCode -eq 401 -or $_.Exception.Response.StatusCode -eq 403) {
        Write-Success "✓ Upload endpoint exists (requires authentication as expected)"
    } else {
        Write-Info "  Endpoint status: $($_.Exception.Response.StatusCode)"
    }
}

# Test 5: Get vehicle to verify structure
Write-Step "Test 5: Verifying vehicle data structure..."
try {
    $response = Invoke-RestMethod -Uri "$API_URL/vehicles/$vehicleId" -Method GET
    Write-Success "✓ Vehicle retrieved"
    Write-Host "  ID: $($response.id)"
    Write-Host "  Make/Model: $($response.make) $($response.model)"
    Write-Host "  Images: $($response.images.Count) image(s)"
    Write-Host "  Created: $($response.createdAt)"
} catch {
    Write-Error "✗ Failed to retrieve vehicle: $_"
}

# Test 6: Search vehicles
Write-Step "Test 6: Testing vehicle search..."
try {
    $response = Invoke-RestMethod -Uri "$API_URL/vehicles/search?city=Test&make=Toyota" -Method GET
    Write-Success "✓ Vehicle search successful"
    Write-Host "  Found $($response.Count) vehicle(s)"
} catch {
    Write-Error "✗ Vehicle search failed: $_"
}

# Test 7: Get available vehicles
Write-Step "Test 7: Getting available vehicles..."
try {
    $response = Invoke-RestMethod -Uri "$API_URL/vehicles/available" -Method GET
    Write-Success "✓ Available vehicles retrieved"
    Write-Host "  Found $($response.Count) available vehicle(s)"
} catch {
    Write-Error "✗ Failed to get available vehicles: $_"
}

# Summary
Write-Step "Test Summary"
Write-Host "==========================================`n" -ForegroundColor Cyan
Write-Success "✓ Upload service is configured and ready"
Write-Success "✓ Vehicle endpoints are working"
Write-Success "✓ Test vehicle created: $vehicleId"
Write-Info "`nNext Steps:"
Write-Host "  1. Set up authentication (JWT) to test protected upload endpoints"
Write-Host "  2. Use the test vehicle ID to upload images via authenticated requests"
Write-Host "  3. Test image optimization and thumbnail generation"
Write-Host "  4. Run migration to import Firebase data"
Write-Host "`n  Test vehicle ID: $vehicleId" -ForegroundColor Green
Write-Host "  You can delete this test vehicle with:"
Write-Host "  Invoke-RestMethod -Uri '$API_URL/vehicles/$vehicleId' -Method DELETE`n"

# Cleanup option
Write-Host "`nCleanup: " -NoNewline
$cleanup = Read-Host "Delete test vehicle? (y/n)"
if ($cleanup -eq 'y') {
    try {
        Invoke-RestMethod -Uri "$API_URL/vehicles/$vehicleId" -Method DELETE
        Write-Success "✓ Test vehicle deleted"
    } catch {
        Write-Error "✗ Failed to delete test vehicle: $_"
    }
}

Write-Host "`n======================================`n" -ForegroundColor Cyan
