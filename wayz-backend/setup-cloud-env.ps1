# PowerShell Script to Update .env with Railway Connection Strings
# Day 3: Cloud Database Setup Helper

param(
    [string]$PostgresUrl = "postgresql://postgres:pKbJbHhDyeReboOACVtrtzAGsKAlDIIV@interchange.proxy.rlwy.net:17846/railway",
    [string]$RedisUrl = "redis://default:CMkTDDRICYurCbCGuOzawnfYDLqJPzEJ@redis.railway.internal:6379"
)

Write-Host "🚀 Tourism Vehicle Rental - Day 3 Database Setup Helper" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""

if (-not $PostgresUrl -or -not $RedisUrl) {
    Write-Host "Usage Examples:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After setting up Railway, run this script with your connection strings:" -ForegroundColor White
    Write-Host ""
    Write-Host ".\setup-cloud-env.ps1 \"
    Write-Host "  -PostgresUrl 'postgresql://postgres:PASSWORD@containers-us-west-xyz.railway.app:5432/railway' \"
    Write-Host "  -RedisUrl 'redis://default:PASSWORD@containers-us-west-xyz.railway.app:6379'"
    Write-Host ""
    Write-Host "Or run without parameters and enter them interactively:" -ForegroundColor Cyan
    Write-Host ""
    
    if (-not $PostgresUrl) {
        $PostgresUrl = Read-Host "Enter your Railway PostgreSQL URL"
    }
    
    if (-not $RedisUrl) {
        $RedisUrl = Read-Host "Enter your Railway Redis URL"
    }
}

Write-Host "Parsing connection strings..." -ForegroundColor Yellow

# Parse PostgreSQL URL: postgresql://postgres:password@host:port/database
if ($PostgresUrl -match "postgresql://([^:]+):([^@]+)@([^:]+):(\d+)/([^?]+)") {
    $PgUser = $matches[1]
    $PgPassword = $matches[2] 
    $PgHost = $matches[3]
    $PgPort = $matches[4]
    $PgDatabase = $matches[5]
    
    Write-Host "✅ PostgreSQL connection parsed:" -ForegroundColor Green
    Write-Host "   Host: $PgHost" -ForegroundColor White
    Write-Host "   Port: $PgPort" -ForegroundColor White
    Write-Host "   Database: $PgDatabase" -ForegroundColor White
    Write-Host "   Username: $PgUser" -ForegroundColor White
    Write-Host "   Password: [HIDDEN]" -ForegroundColor White
} else {
    Write-Host "❌ Invalid PostgreSQL URL format" -ForegroundColor Red
    exit 1
}

# Parse Redis URL: redis://default:password@host:port or redis://:password@host:port
if ($RedisUrl -match "redis://(?:default:)?([^@]+)@([^:]+):(\d+)") {
    $RedisPassword = $matches[1]
    $RedisHost = $matches[2]
    $RedisPort = $matches[3]
    
    Write-Host "✅ Redis connection parsed:" -ForegroundColor Green
    Write-Host "   Host: $RedisHost" -ForegroundColor White
    Write-Host "   Port: $RedisPort" -ForegroundColor White
    Write-Host "   Password: [HIDDEN]" -ForegroundColor White
} else {
    Write-Host "❌ Invalid Redis URL format" -ForegroundColor Red
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
        $envContent = $envContent[0..($lineIndex-1)] + "REDIS_PASSWORD=$RedisPassword" + $envContent[$lineIndex..($envContent.Count-1)]
    }
} else {
    $envContent = $envContent -replace "REDIS_PASSWORD=.*", "REDIS_PASSWORD=$RedisPassword"
}

# Write updated .env file
$envContent | Set-Content $envPath

Write-Host "✅ .env file updated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Run 'npm run start:dev' to test the connection" -ForegroundColor White
Write-Host "2. Create the database schema (see database/schema.sql)" -ForegroundColor White
Write-Host "3. Test the health endpoints" -ForegroundColor White
Write-Host ""
Write-Host "Your cloud database is ready! 🎉" -ForegroundColor Green
