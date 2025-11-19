# PowerShell script to start the NestJS server with Aiven database
# Make sure we're in the correct directory and run the server

Write-Host "🚀 Starting Tourism Vehicle Rental Backend with Aiven.io Database" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green

# Ensure we're in the wayz-backend directory
$targetPath = "c:\Users\User\tourism_vehicle_rental_app\wayz-backend"
Set-Location $targetPath

Write-Host "Current Directory: $(Get-Location)" -ForegroundColor Yellow
Write-Host "Checking package.json exists: $(Test-Path 'package.json')" -ForegroundColor Yellow

if (Test-Path "package.json") {
    Write-Host "✅ Found package.json - Starting NestJS server..." -ForegroundColor Green
    
    # Show available scripts
    Write-Host "`nAvailable npm scripts:" -ForegroundColor Cyan
    npm run --silent
    
    Write-Host "`nStarting development server..." -ForegroundColor Green
    npm run start:dev
} else {
    Write-Host "❌ package.json not found in current directory" -ForegroundColor Red
    Write-Host "Current files:" -ForegroundColor Yellow
    Get-ChildItem | Select-Object Name
}
