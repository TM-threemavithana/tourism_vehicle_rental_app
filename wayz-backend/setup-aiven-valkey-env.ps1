# PowerShell Script to Update .env with Aiven.io Valkey Connection Strings
# Day 3: Cloud Database Setup Helper for Aiven.io (Valkey version)

param(
    [string]$PostgresUrl = "postgres://avnadmin:AVNS_Yg1A9GQmC6P0ErX8msM@pg-4a2bf3f-wayz.k.aivencloud.com:17019/defaultdb?sslmode=require",
    [string]$ValkeyUrl = "rediss://default:AVNS_ywXDn30VvvQOltpc4Sr@valkey-1408eade-wayz.b.aivencloud.com:17020"
)

Write-Host "🚀 Tourism Vehicle Rental - Day 3 Aiven.io Database Setup (Valkey)" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host ""

if (-not $PostgresUrl -or -not $ValkeyUrl) {
    Write-Host "Usage Examples:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After setting up Aiven.io, run this script with your connection strings:" -ForegroundColor White
    Write-Host ""
    Write-Host ".\setup-aiven-valkey-env.ps1 \"
    Write-Host "  -PostgresUrl 'postgresql://avnadmin:PASSWORD@pg-xyz.aivencloud.com:12345/defaultdb' \"
    Write-Host "  -ValkeyUrl 'redis://default:PASSWORD@valkey-xyz.aivencloud.com:12345'"
    Write-Host ""
    Write-Host "💡 Note: Valkey uses redis:// protocol (100% Redis compatible)" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not $PostgresUrl) {
        $PostgresUrl = Read-Host "Enter your Aiven PostgreSQL Service URI"
    }
    
    if (-not $ValkeyUrl) {
        $ValkeyUrl = Read-Host "Enter your Aiven Valkey Service URI (redis://...)"
    }
}

Write-Host "Parsing Aiven connection strings..." -ForegroundColor Yellow

# Parse PostgreSQL URL: postgres://avnadmin:password@host:port/database (with optional query params)
if ($PostgresUrl -match "postgres(?:ql)?://([^:]+):([^@]+)@([^:]+):(\d+)/([^?]+)") {
    $PgUser = $matches[1]
    $PgPassword = $matches[2] 
    $PgHost = $matches[3]
    $PgPort = $matches[4]
    $PgDatabase = $matches[5]
    
    Write-Host "✅ Aiven PostgreSQL connection parsed:" -ForegroundColor Green
    Write-Host "   Host: $PgHost" -ForegroundColor White
    Write-Host "   Port: $PgPort" -ForegroundColor White
    Write-Host "   Database: $PgDatabase" -ForegroundColor White
    Write-Host "   Username: $PgUser" -ForegroundColor White
    Write-Host "   Password: [HIDDEN]" -ForegroundColor White
} else {
    Write-Host "❌ Invalid PostgreSQL URL format" -ForegroundColor Red
    Write-Host "Expected format: postgresql://avnadmin:PASSWORD@pg-xyz.aivencloud.com:PORT/defaultdb" -ForegroundColor Yellow
    exit 1
}

# Parse Valkey URL: redis(s)://default:password@host:port (Valkey uses Redis protocol, supports SSL)
if ($ValkeyUrl -match "redis(?:s)?://(?:default:)?([^@]+)@([^:]+):(\d+)") {
    $ValkeyPassword = $matches[1]
    $ValkeyHost = $matches[2]
    $ValkeyPort = $matches[3]
    
    Write-Host "✅ Aiven Valkey connection parsed:" -ForegroundColor Green
    Write-Host "   Host: $ValkeyHost" -ForegroundColor White
    Write-Host "   Port: $ValkeyPort" -ForegroundColor White
    Write-Host "   Password: [HIDDEN]" -ForegroundColor White
    Write-Host "   Protocol: Redis (Valkey is 100% compatible)" -ForegroundColor Cyan
} else {
    Write-Host "❌ Invalid Valkey URL format" -ForegroundColor Red
    Write-Host "Expected format: redis://default:PASSWORD@valkey-xyz.aivencloud.com:PORT" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Updating .env file..." -ForegroundColor Yellow

# Read current .env file
$envPath = ".env"
if (-not (Test-Path $envPath)) {
    Write-Host "❌ .env file not found" -ForegroundColor Red
    exit 1
}

$envContent = Get-Content $envPath

# Update database configuration
$envContent = $envContent -replace "DATABASE_HOST=.*", "DATABASE_HOST=$PgHost"
$envContent = $envContent -replace "DATABASE_PORT=.*", "DATABASE_PORT=$PgPort"  
$envContent = $envContent -replace "DATABASE_USERNAME=.*", "DATABASE_USERNAME=$PgUser"
$envContent = $envContent -replace "DATABASE_PASSWORD=.*", "DATABASE_PASSWORD=$PgPassword"
$envContent = $envContent -replace "DATABASE_NAME=.*", "DATABASE_NAME=$PgDatabase"

# Update Valkey/Redis configuration
$envContent = $envContent -replace "REDIS_HOST=.*", "REDIS_HOST=$ValkeyHost"
$envContent = $envContent -replace "REDIS_PORT=.*", "REDIS_PORT=$ValkeyPort"

# Add Redis password if not exists
if ($envContent -notmatch "REDIS_PASSWORD=") {
    $redisHostIndex = $envContent | ForEach-Object { $_.IndexOf("REDIS_HOST=") } | Where-Object { $_ -ge 0 } | Select-Object -First 1
    if ($redisHostIndex -ge 0) {
        $lineIndex = 0
        for ($i = 0; $i -lt $envContent.Count; $i++) {
            if ($envContent[$i].IndexOf("REDIS_HOST=") -ge 0) {
                $lineIndex = $i + 2  # Add after REDIS_PORT
                break
            }
        }
        $envContent = $envContent[0..($lineIndex-1)] + "REDIS_PASSWORD=$ValkeyPassword" + $envContent[$lineIndex..($envContent.Count-1)]
    }
} else {
    $envContent = $envContent -replace "REDIS_PASSWORD=.*", "REDIS_PASSWORD=$ValkeyPassword"
}

# Write updated .env file
$envContent | Set-Content $envPath

Write-Host "✅ .env file updated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 Valkey Benefits:" -ForegroundColor Cyan
Write-Host "   • Open-source (BSD license)" -ForegroundColor White
Write-Host "   • 100% Redis compatible" -ForegroundColor White
Write-Host "   • Linux Foundation backed" -ForegroundColor White
Write-Host "   • Same performance as Redis" -ForegroundColor White
Write-Host "   • Better long-term choice" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run 'npm run start:dev' to test the connection" -ForegroundColor White
Write-Host "2. Create the database schema (see database/schema.sql)" -ForegroundColor White
Write-Host "3. Test the health endpoints" -ForegroundColor White
Write-Host ""
Write-Host "Your Aiven cloud database with Valkey is ready! 🎉" -ForegroundColor Green
