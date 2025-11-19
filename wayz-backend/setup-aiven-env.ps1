# PowerShell Script to Update .env with Aiven.io Connection Strings
# Day 3: Cloud Database Setup Helper for Aiven.io

param(
    [string]$PostgresUrl = "",
    [string]$RedisUrl = ""
)

Write-Host "🚀 Tourism Vehicle Rental - Day 3 Aiven.io Database Setup" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""

if (-not $PostgresUrl -or -not $RedisUrl) {
    Write-Host "Usage Examples:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After setting up Aiven.io, run this script with your connection strings:" -ForegroundColor White
    Write-Host ""
    Write-Host ".\setup-aiven-env.ps1 \"
    Write-Host "  -PostgresUrl 'postgresql://avnadmin:PASSWORD@pg-xyz.aivencloud.com:12345/defaultdb' \"
    Write-Host "  -RedisUrl 'redis://default:PASSWORD@redis-xyz.aivencloud.com:12345'"
    Write-Host ""
    Write-Host "Or run without parameters and enter them interactively:" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not $PostgresUrl) {
        $PostgresUrl = Read-Host "Enter your Aiven PostgreSQL Service URI"
    }
    
    if (-not $RedisUrl) {
        $RedisUrl = Read-Host "Enter your Aiven Redis Service URI"
    }
}

Write-Host "Parsing Aiven connection strings..." -ForegroundColor Yellow

# Parse PostgreSQL URL: postgresql://avnadmin:password@host:port/database
if ($PostgresUrl -match "postgresql://([^:]+):([^@]+)@([^:]+):(\d+)/([^?]+)") {
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

# Parse Redis URL: redis://default:password@host:port or redis://:password@host:port
if ($RedisUrl -match "redis://(?:default:)?([^@]+)@([^:]+):(\d+)") {
    $RedisPassword = $matches[1]
    $RedisHost = $matches[2]
    $RedisPort = $matches[3]
    
    Write-Host "✅ Aiven Redis connection parsed:" -ForegroundColor Green
    Write-Host "   Host: $RedisHost" -ForegroundColor White
    Write-Host "   Port: $RedisPort" -ForegroundColor White
    Write-Host "   Password: [HIDDEN]" -ForegroundColor White
} else {
    Write-Host "❌ Invalid Redis URL format" -ForegroundColor Red
    Write-Host "Expected format: redis://default:PASSWORD@redis-xyz.aivencloud.com:PORT" -ForegroundColor Yellow
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

# Update Redis configuration
$envContent = $envContent -replace "REDIS_HOST=.*", "REDIS_HOST=$RedisHost"
$envContent = $envContent -replace "REDIS_PORT=.*", "REDIS_PORT=$RedisPort"

# Update Redis password - handle duplicate entries
$updatedContent = @()
$redisPasswordSet = $false

foreach ($line in $envContent) {
    if ($line -match "^REDIS_PASSWORD=" -and -not $redisPasswordSet) {
        $updatedContent += "REDIS_PASSWORD=$RedisPassword"
        $redisPasswordSet = $true
    } elseif ($line -match "^REDIS_PASSWORD=" -and $redisPasswordSet) {
        # Skip duplicate REDIS_PASSWORD lines
        continue
    } else {
        $updatedContent += $line
    }
}

# If no REDIS_PASSWORD was found, add it
if (-not $redisPasswordSet) {
    for ($i = 0; $i -lt $updatedContent.Count; $i++) {
        if ($updatedContent[$i] -match "^REDIS_PORT=") {
            $updatedContent = $updatedContent[0..$i] + "REDIS_PASSWORD=$RedisPassword" + $updatedContent[($i+1)..($updatedContent.Count-1)]
            break
        }
    }
}

# Write updated .env file
$updatedContent | Set-Content $envPath

Write-Host "✅ .env file updated successfully with Aiven.io credentials!" -ForegroundColor Green
Write-Host ""
Write-Host "Aiven.io Configuration Summary:" -ForegroundColor Cyan
Write-Host "- PostgreSQL Host: $PgHost" -ForegroundColor White
Write-Host "- PostgreSQL Port: $PgPort" -ForegroundColor White
Write-Host "- Redis Host: $RedisHost" -ForegroundColor White
Write-Host "- Redis Port: $RedisPort" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run 'npm run start:dev' to test the connection" -ForegroundColor White
Write-Host "2. Create the database schema using Aiven console or CLI" -ForegroundColor White
Write-Host "3. Test the health endpoints" -ForegroundColor White
Write-Host ""
Write-Host "Your Aiven.io cloud databases are ready! 🎉" -ForegroundColor Green
