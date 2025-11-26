# Migration Test & Execution Script
# Safe testing and execution of Firebase to PostgreSQL migration

param(
    [switch]$DryRun,
    [switch]$Execute,
    [switch]$Stats,
    [switch]$Validate,
    [switch]$Export,
    [string]$Collection = "all"
)

$BASE_URL = "http://localhost:3000"
$API_URL = "$BASE_URL/api"

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "  Migration Test & Execution Script" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Colors
function Write-Success { param($message) Write-Host $message -ForegroundColor Green }
function Write-Error { param($message) Write-Host $message -ForegroundColor Red }
function Write-Info { param($message) Write-Host $message -ForegroundColor Yellow }
function Write-Step { param($message) Write-Host "`n$message" -ForegroundColor Cyan }

# Check prerequisites
Write-Step "Checking prerequisites..."

# 1. Check if server is running
try {
    $response = Invoke-WebRequest -Uri "$API_URL/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    Write-Success "✓ Server is running"
} catch {
    Write-Error "✗ Server is not running"
    Write-Host "  Start the server with: npm run start:dev"
    exit 1
}

# 2. Check Firebase configuration
Write-Info "Checking Firebase configuration..."
$envPath = Join-Path $PSScriptRoot ".env"
if (Test-Path $envPath) {
    $envContent = Get-Content $envPath
    $hasFirebaseConfig = $envContent | Where-Object { $_ -match "FIREBASE_" }
    if ($hasFirebaseConfig) {
        Write-Success "✓ Firebase configuration found"
    } else {
        Write-Error "✗ Firebase configuration missing in .env"
        exit 1
    }
} else {
    Write-Error "✗ .env file not found"
    exit 1
}

# 3. Check PostgreSQL connection
Write-Info "Checking PostgreSQL connection..."
try {
    $response = Invoke-RestMethod -Uri "$API_URL/users" -Method GET -ErrorAction Stop
    Write-Success "✓ PostgreSQL connected"
} catch {
    Write-Error "✗ PostgreSQL connection failed"
    Write-Host "  Check your database configuration"
    exit 1
}

# Display usage if no parameters
if (-not ($DryRun -or $Execute -or $Stats -or $Validate -or $Export)) {
    Write-Host "`nUsage:" -ForegroundColor Yellow
    Write-Host "  .\test-migration.ps1 -Stats              # Show migration statistics"
    Write-Host "  .\test-migration.ps1 -Validate           # Validate migration readiness"
    Write-Host "  .\test-migration.ps1 -Export             # Export Firebase data to JSON"
    Write-Host "  .\test-migration.ps1 -DryRun             # Test migration (no changes)"
    Write-Host "  .\test-migration.ps1 -Execute            # Execute migration"
    Write-Host "  .\test-migration.ps1 -DryRun -Collection users  # Test specific collection"
    Write-Host ""
    $action = Read-Host "What would you like to do? (stats/validate/export/dryrun/execute)"
    
    switch ($action.ToLower()) {
        "stats" { $Stats = $true }
        "validate" { $Validate = $true }
        "export" { $Export = $true }
        "dryrun" { $DryRun = $true }
        "execute" { $Execute = $true }
        default {
            Write-Error "Invalid option"
            exit 1
        }
    }
}

# Execute based on parameters
if ($Stats) {
    Write-Step "Getting migration statistics..."
    try {
        $response = Invoke-RestMethod -Uri "$API_URL/migrate/stats" -Method GET
        Write-Success "`n✓ Migration Statistics:"
        Write-Host "`nFirebase Collections:" -ForegroundColor Cyan
        $response.firebase | ForEach-Object {
            Write-Host "  $($_.collection): $($_.count) records" -ForegroundColor White
        }
        Write-Host "`nPostgreSQL Tables:" -ForegroundColor Cyan
        $response.postgresql | ForEach-Object {
            Write-Host "  $($_.table): $($_.count) records" -ForegroundColor White
        }
    } catch {
        Write-Error "✗ Failed to get statistics: $_"
    }
}

if ($Validate) {
    Write-Step "Validating migration readiness..."
    try {
        $response = Invoke-RestMethod -Uri "$API_URL/migrate/validate" -Method POST
        Write-Success "`n✓ Validation Results:"
        
        if ($response.valid) {
            Write-Success "  Status: READY FOR MIGRATION"
        } else {
            Write-Error "  Status: NOT READY"
        }
        
        Write-Host "`nValidation Details:" -ForegroundColor Cyan
        $response | ConvertTo-Json -Depth 5 | Write-Host
        
    } catch {
        Write-Error "✗ Validation failed: $_"
    }
}

if ($Export) {
    Write-Step "Exporting Firebase data..."
    $exportDir = Join-Path $PSScriptRoot "firebase-export"
    
    try {
        $body = @{
            exportPath = $exportDir
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$API_URL/migrate/export" -Method POST -Body $body -ContentType "application/json"
        Write-Success "`n✓ Export completed:"
        Write-Host "  Location: $($response.exportPath)"
        Write-Host "  Files exported: $($response.collections.Count)"
        
        Write-Host "`nExported Collections:" -ForegroundColor Cyan
        $response.collections | ForEach-Object {
            Write-Host "  $($_.collection): $($_.recordCount) records ($($_.fileSizeKB) KB)"
        }
        
    } catch {
        Write-Error "✗ Export failed: $_"
    }
}

if ($DryRun) {
    Write-Step "Running migration dry-run (no changes will be made)..."
    Write-Info "Collection: $Collection"
    
    try {
        $body = @{
            collections = @($Collection)
            dryRun = $true
            batchSize = 50
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$API_URL/migrate/migrate" -Method POST -Body $body -ContentType "application/json"
        
        Write-Success "`n✓ Dry-run completed successfully!"
        Write-Host "`nResults:" -ForegroundColor Cyan
        Write-Host "  Total processed: $($response.totalProcessed)"
        Write-Host "  Would migrate: $($response.successful)"
        Write-Host "  Would skip: $($response.skipped)"
        Write-Host "  Errors: $($response.failed)"
        Write-Host "  Duration: $($response.durationMs)ms"
        
        if ($response.errors -and $response.errors.Count -gt 0) {
            Write-Host "`nErrors found:" -ForegroundColor Red
            $response.errors | ForEach-Object {
                Write-Host "  - $($_.collection): $($_.error)"
            }
        } else {
            Write-Success "`n✓ No errors found. Safe to execute migration."
        }
        
    } catch {
        Write-Error "✗ Dry-run failed: $_"
        Write-Host $_.Exception.Message
    }
}

if ($Execute) {
    Write-Step "EXECUTING MIGRATION..."
    Write-Host "⚠️  WARNING: This will migrate data from Firebase to PostgreSQL" -ForegroundColor Red
    Write-Host "⚠️  Collection: $Collection" -ForegroundColor Red
    Write-Host ""
    
    $confirm = Read-Host "Are you sure you want to proceed? (yes/no)"
    
    if ($confirm -ne "yes") {
        Write-Info "Migration cancelled"
        exit 0
    }
    
    # Create backup first
    Write-Info "Creating backup first..."
    try {
        $exportDir = Join-Path $PSScriptRoot "firebase-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        $body = @{
            exportPath = $exportDir
        } | ConvertTo-Json
        
        $exportResponse = Invoke-RestMethod -Uri "$API_URL/migrate/export" -Method POST -Body $body -ContentType "application/json"
        Write-Success "✓ Backup created: $exportDir"
    } catch {
        Write-Error "✗ Backup failed: $_"
        Write-Host "Continue without backup? (yes/no): " -NoNewline
        $continueWithoutBackup = Read-Host
        if ($continueWithoutBackup -ne "yes") {
            exit 1
        }
    }
    
    # Execute migration
    Write-Info "Starting migration..."
    try {
        $body = @{
            collections = @($Collection)
            dryRun = $false
            batchSize = 100
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "$API_URL/migrate/migrate" -Method POST -Body $body -ContentType "application/json"
        
        Write-Success "`n✓ Migration completed!"
        Write-Host "`nResults:" -ForegroundColor Cyan
        Write-Host "  Total processed: $($response.totalProcessed)"
        Write-Host "  Successfully migrated: $($response.successful)"
        Write-Host "  Skipped (duplicates): $($response.skipped)"
        Write-Host "  Failed: $($response.failed)"
        Write-Host "  Duration: $($response.durationMs)ms"
        
        if ($response.errors -and $response.errors.Count -gt 0) {
            Write-Host "`nErrors:" -ForegroundColor Red
            $response.errors | ForEach-Object {
                Write-Host "  - $($_.collection): $($_.error)"
            }
        }
        
        # Show statistics after migration
        Write-Step "Updated Statistics:"
        $stats = Invoke-RestMethod -Uri "$API_URL/migrate/stats" -Method GET
        Write-Host "`nPostgreSQL Tables:" -ForegroundColor Cyan
        $stats.postgresql | ForEach-Object {
            Write-Host "  $($_.table): $($_.count) records" -ForegroundColor White
        }
        
    } catch {
        Write-Error "✗ Migration failed: $_"
        Write-Host $_.Exception.Message
        Write-Host "`nBackup location: $exportDir" -ForegroundColor Yellow
    }
}

Write-Host "`n======================================`n" -ForegroundColor Cyan
Write-Info "For more options, see MIGRATION_QUICK_START.md"
