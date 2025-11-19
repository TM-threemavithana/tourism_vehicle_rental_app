# Simple Authentication Test Script
# Tests token blacklisting and rate limiting

$BaseUrl = "http://localhost:3000"
$TestEmail = "test_$(Get-Random)@example.com"
$TestPassword = "Test123!"

Write-Host "`n=== Token Blacklisting & Rate Limiting Test ===" -ForegroundColor Cyan
Write-Host "Using: $TestEmail`n" -ForegroundColor Gray

# Test 1: Register and Login
Write-Host "[Test 1] Register new user..." -ForegroundColor Yellow
try {
    $registerBody = @{
        email = $TestEmail
        password = $TestPassword
        firstName = "Test"
        lastName = "User"
        phoneNumber = "+1234567890"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$BaseUrl/auth/register" `
        -Method Post `
        -ContentType "application/json" `
        -Body $registerBody

    $token = $response.accessToken
    Write-Host "✅ Registration successful" -ForegroundColor Green
    Write-Host "   Token: $($token.Substring(0, 20))..." -ForegroundColor Gray
} catch {
    Write-Host "❌ Registration failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Access protected resource
Write-Host "`n[Test 2] Access protected resource with valid token..." -ForegroundColor Yellow
try {
    $profile = Invoke-RestMethod -Uri "$BaseUrl/auth/profile" `
        -Method Get `
        -Headers @{ Authorization = "Bearer $token" }
    
    Write-Host "✅ Successfully accessed profile" -ForegroundColor Green
    Write-Host "   User: $($profile.firstName) $($profile.lastName)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Failed to access profile: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Logout (blacklist token)
Write-Host "`n[Test 3] Logout (blacklist current token)..." -ForegroundColor Yellow
try {
    $logoutResponse = Invoke-RestMethod -Uri "$BaseUrl/auth/logout" `
        -Method Post `
        -Headers @{ Authorization = "Bearer $token" }
    
    Write-Host "✅ Logout successful" -ForegroundColor Green
    Write-Host "   Message: $($logoutResponse.message)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Logout failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Try using blacklisted token
Write-Host "`n[Test 4] Try accessing with blacklisted token..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "$BaseUrl/auth/profile" `
        -Method Get `
        -Headers @{ Authorization = "Bearer $token" } `
        -ErrorAction Stop
    
    Write-Host "❌ FAIL: Blacklisted token still works!" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✅ Token properly blacklisted (401 Unauthorized)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Unexpected error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Test 5: Login Rate Limiting
Write-Host "`n[Test 5] Test login rate limiting (5 attempts per 15 min)..." -ForegroundColor Yellow
$failedAttempts = 0
$rateLimited = $false

for ($i = 1; $i -le 7; $i++) {
    try {
        $loginBody = @{
            email = $TestEmail
            password = "WrongPassword123!"
        } | ConvertTo-Json

        Invoke-RestMethod -Uri "$BaseUrl/auth/login" `
            -Method Post `
            -ContentType "application/json" `
            -Body $loginBody `
            -ErrorAction Stop
        
    } catch {
        $failedAttempts++
        $statusCode = $_.Exception.Response.StatusCode.value__
        
        if ($statusCode -eq 429) {
            $rateLimited = $true
            Write-Host "✅ Rate limited after $failedAttempts failed attempts" -ForegroundColor Green
            break
        } elseif ($statusCode -eq 401) {
            Write-Host "   Attempt $i/7: Failed (as expected)" -ForegroundColor Gray
        }
    }
    Start-Sleep -Milliseconds 300
}

if (-not $rateLimited -and $failedAttempts -ge 5) {
    Write-Host "⚠️  Rate limiting may not be active" -ForegroundColor Yellow
}

# Test 6: Multiple logins and logout all
Write-Host "`n[Test 6] Multiple logins and logout from all devices..." -ForegroundColor Yellow
try {
    # Login twice
    $loginBody = @{
        email = $TestEmail
        password = $TestPassword
    } | ConvertTo-Json

    $response1 = Invoke-RestMethod -Uri "$BaseUrl/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody

    $token1 = $response1.accessToken

    $response2 = Invoke-RestMethod -Uri "$BaseUrl/auth/login" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loginBody

    $token2 = $response2.accessToken

    Write-Host "✅ Logged in twice successfully" -ForegroundColor Green

    # Verify both work
    Invoke-RestMethod -Uri "$BaseUrl/auth/profile" `
        -Method Get `
        -Headers @{ Authorization = "Bearer $token1" } | Out-Null
    
    Invoke-RestMethod -Uri "$BaseUrl/auth/profile" `
        -Method Get `
        -Headers @{ Authorization = "Bearer $token2" } | Out-Null
    
    Write-Host "✅ Both tokens work" -ForegroundColor Green

    # Logout from all devices
    Invoke-RestMethod -Uri "$BaseUrl/auth/logout-all" `
        -Method Post `
        -Headers @{ Authorization = "Bearer $token1" } | Out-Null
    
    Write-Host "✅ Logged out from all devices" -ForegroundColor Green

    # Verify both are invalidated
    $bothInvalid = $true
    try {
        Invoke-RestMethod -Uri "$BaseUrl/auth/profile" `
            -Method Get `
            -Headers @{ Authorization = "Bearer $token1" } `
            -ErrorAction Stop
        $bothInvalid = $false
    } catch {}

    try {
        Invoke-RestMethod -Uri "$BaseUrl/auth/profile" `
            -Method Get `
            -Headers @{ Authorization = "Bearer $token2" } `
            -ErrorAction Stop
        $bothInvalid = $false
    } catch {}

    if ($bothInvalid) {
        Write-Host "✅ Both tokens properly invalidated" -ForegroundColor Green
    } else {
        Write-Host "❌ Some tokens still valid after logout-all" -ForegroundColor Red
    }

} catch {
    Write-Host "❌ Multiple login test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Token blacklisting and rate limiting tests completed!" -ForegroundColor Green
Write-Host "`nKey Features Tested:" -ForegroundColor Yellow
Write-Host "  ✓ Token blacklisting on logout" -ForegroundColor Gray
Write-Host "  ✓ Blacklisted tokens rejected" -ForegroundColor Gray
Write-Host "  ✓ Login rate limiting" -ForegroundColor Gray
Write-Host "  ✓ Logout from all devices" -ForegroundColor Gray
Write-Host ""
