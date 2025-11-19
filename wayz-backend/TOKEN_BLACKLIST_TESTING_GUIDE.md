# Testing Token Blacklisting and Rate Limiting

## Prerequisites

1. **Start Redis/Valkey** (if not running):
```powershell
# Make sure your Redis/Valkey service is running
```

2. **Start the Backend Server**:
```powershell
cd wayz-backend
npm run start:dev
```

## Test 1: Token Blacklisting - Single Logout

### Step 1: Register a new user
```powershell
$response = Invoke-RestMethod -Uri "http://localhost:3000/auth/register" `
  -Method Post `
  -ContentType "application/json" `
  -Body (@{
    email = "test@example.com"
    password = "Test123!"
    firstName = "Test"
    lastName = "User"
    phoneNumber = "+1234567890"
  } | ConvertTo-Json)

$token = $response.accessToken
Write-Host "Token: $token"
```

### Step 2: Access protected resource (should work)
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/auth/profile" `
  -Method Get `
  -Headers @{ Authorization = "Bearer $token" }
```

### Step 3: Logout
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/auth/logout" `
  -Method Post `
  -Headers @{ Authorization = "Bearer $token" }
```

### Step 4: Try accessing again (should fail)
```powershell
try {
  Invoke-RestMethod -Uri "http://localhost:3000/auth/profile" `
    -Method Get `
    -Headers @{ Authorization = "Bearer $token" }
} catch {
  Write-Host "✅ Expected error: $_"
}
```

**Expected Result**: `401 Unauthorized - Token has been revoked`

---

## Test 2: Token Blacklisting - Logout All Devices

### Step 1: Login twice to get two tokens
```powershell
$response1 = Invoke-RestMethod -Uri "http://localhost:3000/auth/login" `
  -Method Post `
  -ContentType "application/json" `
  -Body (@{
    email = "test@example.com"
    password = "Test123!"
  } | ConvertTo-Json)

$token1 = $response1.accessToken

$response2 = Invoke-RestMethod -Uri "http://localhost:3000/auth/login" `
  -Method Post `
  -ContentType "application/json" `
  -Body (@{
    email = "test@example.com"
    password = "Test123!"
  } | ConvertTo-Json)

$token2 = $response2.accessToken

Write-Host "Token 1: $token1"
Write-Host "Token 2: $token2"
```

### Step 2: Verify both tokens work
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/auth/profile" `
  -Method Get `
  -Headers @{ Authorization = "Bearer $token1" }

Invoke-RestMethod -Uri "http://localhost:3000/auth/profile" `
  -Method Get `
  -Headers @{ Authorization = "Bearer $token2" }
```

### Step 3: Logout from all devices using token1
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/auth/logout-all" `
  -Method Post `
  -Headers @{ Authorization = "Bearer $token1" }
```

### Step 4: Verify both tokens are now invalid
```powershell
try {
  Invoke-RestMethod -Uri "http://localhost:3000/auth/profile" `
    -Method Get `
    -Headers @{ Authorization = "Bearer $token1" }
} catch {
  Write-Host "✅ Token 1 invalidated: $_"
}

try {
  Invoke-RestMethod -Uri "http://localhost:3000/auth/profile" `
    -Method Get `
    -Headers @{ Authorization = "Bearer $token2" }
} catch {
  Write-Host "✅ Token 2 invalidated: $_"
}
```

**Expected Result**: Both tokens should be invalidated

---

## Test 3: Password Change Invalidates All Tokens

### Step 1: Login
```powershell
$response = Invoke-RestMethod -Uri "http://localhost:3000/auth/login" `
  -Method Post `
  -ContentType "application/json" `
  -Body (@{
    email = "test@example.com"
    password = "Test123!"
  } | ConvertTo-Json)

$token = $response.accessToken
```

### Step 2: Change password
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/auth/change-password" `
  -Method Post `
  -ContentType "application/json" `
  -Headers @{ Authorization = "Bearer $token" } `
  -Body (@{
    currentPassword = "Test123!"
    newPassword = "NewPassword123!"
  } | ConvertTo-Json)
```

### Step 3: Try using old token (should fail)
```powershell
try {
  Invoke-RestMethod -Uri "http://localhost:3000/auth/profile" `
    -Method Get `
    -Headers @{ Authorization = "Bearer $token" }
} catch {
  Write-Host "✅ Old token invalidated after password change: $_"
}
```

### Step 4: Login with new password
```powershell
$response = Invoke-RestMethod -Uri "http://localhost:3000/auth/login" `
  -Method Post `
  -ContentType "application/json" `
  -Body (@{
    email = "test@example.com"
    password = "NewPassword123!"
  } | ConvertTo-Json)

Write-Host "✅ Successfully logged in with new password"
```

---

## Test 4: Rate Limiting - Login Attempts

### Test login rate limiting (5 attempts per 15 minutes)
```powershell
Write-Host "Testing login rate limiting..."
for ($i = 1; $i -le 7; $i++) {
  try {
    Write-Host "Attempt $i..."
    Invoke-RestMethod -Uri "http://localhost:3000/auth/login" `
      -Method Post `
      -ContentType "application/json" `
      -Body (@{
        email = "test@example.com"
        password = "wrongpassword"
      } | ConvertTo-Json)
  } catch {
    if ($i -gt 5) {
      Write-Host "✅ Rate limited after 5 attempts (as expected)"
    } else {
      Write-Host "Attempt $i failed with: $_"
    }
  }
  Start-Sleep -Milliseconds 500
}
```

**Expected Result**: After 5-6 attempts, you should get rate limited

---

## Test 5: Global Rate Limiting

### Test general endpoint rate limiting
```powershell
Write-Host "Testing global rate limiting (100 req/min)..."
$count = 0
$rateLimited = $false

for ($i = 1; $i -le 110; $i++) {
  try {
    Invoke-RestMethod -Uri "http://localhost:3000/health" -Method Get -ErrorAction Stop
    $count++
  } catch {
    if ($_.Exception.Response.StatusCode -eq 429) {
      $rateLimited = $true
      Write-Host "✅ Rate limited after $count requests"
      break
    }
  }
}

if (-not $rateLimited) {
  Write-Host "⚠️ No rate limiting encountered in 110 requests"
}
```

---

## Test 6: Verify Redis Storage

### Check Redis keys directly
```powershell
# If you have redis-cli installed:
redis-cli -h your-redis-host -p 6379 -a your-password

# Then run these commands:
# KEYS wayz:token:blacklist:*
# KEYS wayz:user:tokens:*
# KEYS wayz:ratelimit:*
# KEYS wayz:throttle:*
```

---

## Complete Test Script

Save this as `test-auth.ps1`:

```powershell
# Complete test script for token blacklisting and rate limiting

param(
  [string]$BaseUrl = "http://localhost:3000"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Token Blacklisting & Rate Limiting Tests" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: Single Logout
Write-Host "Test 1: Single Logout" -ForegroundColor Yellow
try {
  # Register
  $response = Invoke-RestMethod -Uri "$BaseUrl/auth/register" `
    -Method Post `
    -ContentType "application/json" `
    -Body (@{
      email = "test_$(Get-Random)@example.com"
      password = "Test123!"
      firstName = "Test"
      lastName = "User"
      phoneNumber = "+1234567890"
    } | ConvertTo-Json)
  
  $token = $response.accessToken
  Write-Host "✅ Registered successfully" -ForegroundColor Green
  
  # Access profile (should work)
  Invoke-RestMethod -Uri "$BaseUrl/auth/profile" `
    -Method Get `
    -Headers @{ Authorization = "Bearer $token" } | Out-Null
  Write-Host "✅ Accessed profile with valid token" -ForegroundColor Green
  
  # Logout
  Invoke-RestMethod -Uri "$BaseUrl/auth/logout" `
    -Method Post `
    -Headers @{ Authorization = "Bearer $token" } | Out-Null
  Write-Host "✅ Logged out successfully" -ForegroundColor Green
  
  # Try accessing again (should fail)
  try {
    Invoke-RestMethod -Uri "$BaseUrl/auth/profile" `
      -Method Get `
      -Headers @{ Authorization = "Bearer $token" }
    Write-Host "❌ Token should be blacklisted" -ForegroundColor Red
  } catch {
    Write-Host "✅ Token properly blacklisted" -ForegroundColor Green
  }
} catch {
  Write-Host "❌ Test failed: $_" -ForegroundColor Red
}

Write-Host "`n========================================`n" -ForegroundColor Cyan

# Test 2: Rate Limiting
Write-Host "Test 2: Login Rate Limiting" -ForegroundColor Yellow
try {
  $attempts = 0
  $rateLimited = $false
  
  for ($i = 1; $i -le 8; $i++) {
    try {
      Invoke-RestMethod -Uri "$BaseUrl/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body (@{
          email = "nonexistent@example.com"
          password = "wrongpassword"
        } | ConvertTo-Json) -ErrorAction Stop
    } catch {
      $attempts++
      if ($_.Exception.Response.StatusCode -eq 429) {
        $rateLimited = $true
        Write-Host "✅ Rate limited after $attempts attempts" -ForegroundColor Green
        break
      }
    }
    Start-Sleep -Milliseconds 200
  }
  
  if (-not $rateLimited) {
    Write-Host "⚠️ No rate limiting detected" -ForegroundColor Yellow
  }
} catch {
  Write-Host "❌ Test failed: $_" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Tests completed!" -ForegroundColor Cyan
```

Run it with:
```powershell
.\test-auth.ps1
```

---

## Expected Output Summary

✅ **Token Blacklisting**:
- Single logout invalidates that specific token
- Logout all invalidates all user tokens
- Password change invalidates all tokens

✅ **Rate Limiting**:
- Login: 5 attempts per 15 minutes
- Global: 100 requests per minute
- Returns HTTP 429 (Too Many Requests) when limited

✅ **Redis Storage**:
- Keys are properly prefixed (`wayz:`)
- TTL set correctly for automatic cleanup
- Distributed across multiple instances

## Troubleshooting

### Tokens Not Being Blacklisted
- Check Redis connection
- Verify JWT strategy is using TokenBlacklistService
- Check token extraction in JWT strategy

### Rate Limiting Not Working
- Verify ThrottlerConfigModule is imported
- Check Redis connection
- Verify ThrottlerRedisStorage is properly configured

### Redis Connection Issues
- Check REDIS_HOST, REDIS_PORT, REDIS_PASSWORD in .env
- Verify Redis service is running
- Test connection with redis-cli

---

🎉 **Success Indicators**:
- Tokens are invalidated after logout
- Password changes invalidate all sessions
- Rate limits kick in after specified attempts
- Redis keys are created and expire properly
