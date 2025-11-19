# Token Blacklisting & Rate Limiting Implementation Guide

## Overview

This guide covers the comprehensive token blacklisting and rate limiting implementation for proper logout functionality and API protection.

## Features Implemented

### 1. Token Blacklisting ✅

**Location**: `src/auth/services/token-blacklist.service.ts`

**Features**:
- Blacklist individual tokens on logout
- Blacklist all user tokens (logout from all devices)
- Check if token is blacklisted before allowing access
- Track active tokens per user
- Automatic expiration based on JWT expiry time

**Usage**:
```typescript
// Logout single device
await this.authService.logout(userId, token);

// Logout all devices
await this.authService.logoutAll(userId);

// Automatically checked in JWT strategy
const isBlacklisted = await this.tokenBlacklistService.isTokenBlacklisted(token);
```

**Storage**: Redis/Valkey with automatic TTL based on token expiration

### 2. Rate Limiting (Multiple Layers)

#### A. Global Rate Limiting ✅

**Location**: `src/rate-limit/throttler-config.module.ts`

**Configuration**:
- Default: 100 requests per minute for general endpoints
- Strict: 20 requests per minute for sensitive endpoints
- Redis-backed for distributed rate limiting

**Usage**:
```typescript
// Applied globally via APP_GUARD
// Automatically protects all endpoints
```

#### B. Authentication-Specific Rate Limiting ✅

**Location**: `src/auth/services/rate-limit.service.ts`

**Configuration**:
- Login: 5 attempts per 15 minutes
- Register: 3 attempts per hour
- Forgot Password: 3 attempts per hour
- Change Password: 5 attempts per 15 minutes
- Refresh Token: 10 attempts per 10 minutes

**Usage**:
```typescript
// Check if rate limited
const isLimited = await this.rateLimitService.isRateLimited('login', ipAddress);

// Record attempt
await this.rateLimitService.recordAttempt('login', ipAddress);

// Reset limit (after successful operation)
await this.rateLimitService.resetLimit('login', ipAddress);
```

#### C. Custom Throttle Guards ✅

**Location**: `src/auth/guards/auth-throttle.guard.ts`

**Features**:
- IP-based tracking with proxy support (X-Forwarded-For, X-Real-IP)
- Endpoint-specific rate limiting
- Custom error messages

**Usage**:
```typescript
@UseGuards(AuthThrottleGuard)
@Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 requests per minute
@Post('login')
async login(@Body() loginDto: LoginDto) {
  // ...
}
```

### 3. JWT Strategy Integration ✅

**Location**: `src/auth/strategies/jwt.strategy.ts`

**Checks**:
1. Token is not blacklisted
2. Token is in user's active tokens list
3. User account is still active

**Flow**:
```
Request → JWT Strategy → Check Blacklist → Check Active Tokens → Validate User → Allow/Deny
```

## API Endpoints

### Authentication Endpoints

#### 1. Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Rate Limit**: 5 attempts per 15 minutes per IP

**Response**:
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "CUSTOMER",
    "isEmailVerified": false
  }
}
```

#### 2. Logout (Single Device)
```http
POST /auth/logout
Authorization: Bearer {accessToken}
```

**Response**:
```json
{
  "message": "Logged out successfully"
}
```

**What Happens**:
- Token is added to blacklist
- Token remains blacklisted until natural expiry
- Token is removed from user's active tokens list

#### 3. Logout All Devices
```http
POST /auth/logout-all
Authorization: Bearer {accessToken}
```

**Response**:
```json
{
  "message": "Logged out from all devices successfully"
}
```

**What Happens**:
- All user's active tokens are invalidated
- User must login again on all devices

#### 4. Change Password
```http
POST /auth/change-password
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "currentPassword": "oldPassword123",
  "newPassword": "newPassword456"
}
```

**Rate Limit**: 5 attempts per 15 minutes per user

**What Happens**:
- Password is updated
- **All tokens are automatically blacklisted**
- User must login again on all devices

## Redis Storage Structure

### Token Blacklist
```
Key: wayz:token:blacklist:{token}
Value: { userId, blacklistedAt }
TTL: Remaining token lifetime
```

### User Active Tokens
```
Key: wayz:user:tokens:{userId}
Type: Set
Members: [token1, token2, token3, ...]
TTL: Updated on each token addition
```

### Rate Limiting
```
Key: wayz:ratelimit:{operation}:{identifier}
Value: attempt count
TTL: Window duration
```

### Throttler
```
Key: wayz:throttle:{throttlerName}:{key}
Value: request count
TTL: Window duration (60 seconds)
```

## Configuration

### Environment Variables

Ensure these are set in your `.env`:

```env
# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_REFRESH_SECRET=your-refresh-secret-key

# Redis/Valkey Configuration
REDIS_HOST=your-redis-host
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password
```

## Testing

### Test Token Blacklisting

1. **Login**:
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'
```

2. **Access Protected Resource**:
```bash
curl -X GET http://localhost:3000/auth/profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

3. **Logout**:
```bash
curl -X POST http://localhost:3000/auth/logout \
  -H "Authorization: Bearer YOUR_TOKEN"
```

4. **Try Accessing Again** (Should fail):
```bash
curl -X GET http://localhost:3000/auth/profile \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected Response**: `401 Unauthorized - Token has been revoked`

### Test Rate Limiting

**Test Login Rate Limit**:
```bash
# Run this script to test rate limiting
for i in {1..10}; do
  curl -X POST http://localhost:3000/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"user@example.com","password":"wrongpassword"}'
  echo ""
done
```

After 5 attempts, you should get rate limited for 15 minutes.

### Test Logout All Devices

1. Login multiple times to get multiple tokens:
```bash
# Login 1
TOKEN1=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}' \
  | jq -r '.accessToken')

# Login 2
TOKEN2=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}' \
  | jq -r '.accessToken')
```

2. Verify both work:
```bash
curl -X GET http://localhost:3000/auth/profile \
  -H "Authorization: Bearer $TOKEN1"

curl -X GET http://localhost:3000/auth/profile \
  -H "Authorization: Bearer $TOKEN2"
```

3. Logout all:
```bash
curl -X POST http://localhost:3000/auth/logout-all \
  -H "Authorization: Bearer $TOKEN1"
```

4. Verify both are invalidated:
```bash
curl -X GET http://localhost:3000/auth/profile \
  -H "Authorization: Bearer $TOKEN1"
# Should fail

curl -X GET http://localhost:3000/auth/profile \
  -H "Authorization: Bearer $TOKEN2"
# Should also fail
```

## Monitoring

### Check Rate Limit Stats

Access Redis CLI to monitor:

```bash
# Connect to Redis
redis-cli -h your-redis-host -p 6379 -a your-password

# Check all throttle keys
KEYS wayz:throttle:*

# Check token blacklist
KEYS wayz:token:blacklist:*

# Check user active tokens
SMEMBERS wayz:user:tokens:USER_ID

# Check rate limit attempts
GET wayz:ratelimit:login:IP_ADDRESS
```

## Security Considerations

### 1. Token Blacklist

- ✅ Tokens are blacklisted immediately on logout
- ✅ Blacklist entries expire automatically with token TTL
- ✅ No manual cleanup required
- ✅ Works across distributed servers (Redis-backed)

### 2. Rate Limiting

- ✅ IP-based tracking with proxy header support
- ✅ Different limits for different operations
- ✅ Automatic cleanup via Redis TTL
- ✅ Fails open if cache is unavailable (graceful degradation)

### 3. Password Changes

- ✅ Automatically invalidates all sessions
- ✅ Forces re-authentication
- ✅ Prevents unauthorized access after password change

## Best Practices

1. **Use HTTPS**: Always use HTTPS in production to prevent token interception
2. **Short Token Lifetime**: Keep access tokens short-lived (1 hour)
3. **Refresh Tokens**: Implement refresh token rotation for better security
4. **Monitor Rate Limits**: Set up alerts for excessive rate limit violations
5. **IP Whitelisting**: Consider IP whitelisting for administrative endpoints
6. **Audit Logs**: Log all authentication events for security auditing

## Performance Considerations

- **Redis Connection Pool**: Reuses connections efficiently
- **TTL-based Cleanup**: Automatic cleanup, no manual intervention
- **Distributed**: Works across multiple server instances
- **Fail-Safe**: Degrades gracefully if Redis is unavailable

## Troubleshooting

### Token Still Works After Logout

**Check**:
1. JWT Strategy is checking blacklist:
```typescript
const isBlacklisted = await this.tokenBlacklistService.isTokenBlacklisted(token);
```

2. Redis is connected and accessible
3. Token extraction is working correctly

### Rate Limiting Not Working

**Check**:
1. ThrottlerModule is imported in AppModule
2. ThrottlerConfigModule is properly configured
3. Redis is accessible
4. Environment variables are set correctly

### All Requests Blocked

**Check**:
1. Rate limit thresholds are reasonable
2. Redis keys are expiring correctly (check TTL)
3. IP detection is working (check logs)

## Additional Resources

- [NestJS Throttler Documentation](https://docs.nestjs.com/security/rate-limiting)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [Redis Documentation](https://redis.io/documentation)

## Summary

✅ **Token Blacklisting**: Properly logs out users by invalidating tokens  
✅ **Rate Limiting**: Protects against brute force and DoS attacks  
✅ **Distributed**: Works across multiple server instances via Redis  
✅ **Automatic Cleanup**: TTL-based expiration, no manual intervention  
✅ **Graceful Degradation**: Fails safely if cache is unavailable  
✅ **Fine-Grained Control**: Different limits for different operations  
✅ **Security Focused**: Multiple layers of protection

Your authentication system now has enterprise-grade token management and rate limiting! 🎉
