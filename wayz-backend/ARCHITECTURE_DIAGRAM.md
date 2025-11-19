# 🏗️ Token Blacklisting & Rate Limiting Architecture

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLIENT APPLICATION                           │
│                    (Flutter Mobile App / Web)                        │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ HTTP Requests + JWT Token
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         API GATEWAY / NGINX                          │
│                    (X-Forwarded-For, X-Real-IP)                     │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        NESTJS APPLICATION                            │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │          THROTTLER MODULE (Global Rate Limiting)            │    │
│  │  • ThrottlerGuard (APP_GUARD)                               │    │
│  │  • ThrottlerRedisStorage                                    │    │
│  │  • 100 req/min (default), 20 req/min (strict)              │    │
│  └─────────────────────┬──────────────────────────────────────┘    │
│                        │ If not rate limited, continue             │
│                        ▼                                             │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │             AUTH CONTROLLER                                 │    │
│  │  /auth/login, /auth/logout, /auth/logout-all              │    │
│  │  /auth/register, /auth/change-password                     │    │
│  └─────────────────────┬──────────────────────────────────────┘    │
│                        │                                             │
│                        ▼                                             │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │          AUTH SERVICE                                       │    │
│  │  • login() - Generate JWT + Track token                    │    │
│  │  • logout() - Blacklist single token                       │    │
│  │  • logoutAll() - Blacklist all user tokens                 │    │
│  │  • changePassword() - Blacklist all + update password      │    │
│  └─────┬──────────────────┬─────────────────────────────────────┘  │
│        │                  │                                         │
│        │                  │                                         │
│        ▼                  ▼                                         │
│  ┌─────────────┐    ┌──────────────────┐                          │
│  │  Rate Limit │    │ Token Blacklist  │                          │
│  │   Service   │    │     Service      │                          │
│  │             │    │                  │                          │
│  │ • Check     │    │ • blacklistToken │                          │
│  │ • Record    │    │ • isBlacklisted  │                          │
│  │ • Reset     │    │ • addUserToken   │                          │
│  └──────┬──────┘    └────────┬─────────┘                          │
│         │                    │                                     │
│         └────────┬───────────┘                                     │
│                  │                                                  │
└──────────────────┼──────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     REDIS / VALKEY CACHE                             │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ wayz:token:blacklist:{token}                                │    │
│  │   → { userId, blacklistedAt }                               │    │
│  │   → TTL: Remaining token lifetime                           │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ wayz:user:tokens:{userId}                                   │    │
│  │   → SET [token1, token2, token3, ...]                       │    │
│  │   → TTL: Updated on token add                               │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ wayz:ratelimit:login:{ip}                                   │    │
│  │   → attempt_count                                            │    │
│  │   → TTL: 900 seconds (15 minutes)                           │    │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ wayz:throttle:default:{ip:endpoint}                         │    │
│  │   → request_count                                            │    │
│  │   → TTL: 60 seconds                                          │    │
│  └────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

## Request Flow Diagrams

### 1. Login Flow

```
┌────────┐                                                     ┌────────┐
│ Client │                                                     │ Redis  │
└───┬────┘                                                     └───┬────┘
    │                                                              │
    │ POST /auth/login                                            │
    │ { email, password }                                         │
    ├────────────────────────────────────►                       │
    │                                                              │
    │           [ThrottlerGuard]                                  │
    │           Check: wayz:throttle:default:{ip}                 │
    │ ◄────────────────────────────────────────────────────────► │
    │                                                              │
    │           [RateLimitService]                                │
    │           Check: wayz:ratelimit:login:{ip}                  │
    │ ◄────────────────────────────────────────────────────────► │
    │                                                              │
    │           [AuthService]                                     │
    │           • Validate credentials                            │
    │           • Generate JWT token                              │
    │           • Store: wayz:user:tokens:{userId}                │
    │ ◄────────────────────────────────────────────────────────► │
    │                                                              │
    │ ◄────────────────────────────────────                       │
    │ { accessToken, user }                                       │
    │                                                              │
```

### 2. Protected Resource Access

```
┌────────┐                                                     ┌────────┐
│ Client │                                                     │ Redis  │
└───┬────┘                                                     └───┬────┘
    │                                                              │
    │ GET /auth/profile                                           │
    │ Authorization: Bearer {token}                               │
    ├────────────────────────────────────►                       │
    │                                                              │
    │           [JwtStrategy.validate()]                          │
    │           1. Decode & verify JWT                            │
    │           2. Check: wayz:token:blacklist:{token}            │
    │ ◄────────────────────────────────────────────────────────► │
    │              └─► If blacklisted: 401 Unauthorized           │
    │                                                              │
    │           3. Check: wayz:user:tokens:{userId}               │
    │              Contains token?                                │
    │ ◄────────────────────────────────────────────────────────► │
    │              └─► If not in set: 401 Unauthorized            │
    │                                                              │
    │           4. Verify user is active                          │
    │           5. Return user object                             │
    │                                                              │
    │ ◄────────────────────────────────────                       │
    │ { user data }                                               │
    │                                                              │
```

### 3. Logout Flow (Single Device)

```
┌────────┐                                                     ┌────────┐
│ Client │                                                     │ Redis  │
└───┬────┘                                                     └───┬────┘
    │                                                              │
    │ POST /auth/logout                                           │
    │ Authorization: Bearer {token}                               │
    ├────────────────────────────────────►                       │
    │                                                              │
    │           [JwtAuthGuard] - Validate token first             │
    │           (checks blacklist + active tokens)                │
    │ ◄────────────────────────────────────────────────────────► │
    │                                                              │
    │           [TokenBlacklistService]                           │
    │           1. Add to blacklist:                              │
    │              SET wayz:token:blacklist:{token}               │
    │              EXPIRE ttl={remaining_time}                    │
    │ ◄────────────────────────────────────────────────────────► │
    │                                                              │
    │           2. Remove from active tokens:                     │
    │              SREM wayz:user:tokens:{userId} {token}         │
    │ ◄────────────────────────────────────────────────────────► │
    │                                                              │
    │ ◄────────────────────────────────────                       │
    │ { message: "Logged out successfully" }                      │
    │                                                              │
```

### 4. Logout All Devices

```
┌────────┐                                                     ┌────────┐
│ Client │                                                     │ Redis  │
└───┬────┘                                                     └───┬────┘
    │                                                              │
    │ POST /auth/logout-all                                       │
    │ Authorization: Bearer {token}                               │
    ├────────────────────────────────────►                       │
    │                                                              │
    │           [TokenBlacklistService]                           │
    │           • Delete entire user token set:                   │
    │           DEL wayz:user:tokens:{userId}                     │
    │ ◄────────────────────────────────────────────────────────► │
    │           • All tokens now fail validation                  │
    │           • No need to blacklist individually               │
    │                                                              │
    │ ◄────────────────────────────────────                       │
    │ { message: "Logged out from all devices" }                  │
    │                                                              │
```

### 5. Rate Limiting Flow

```
┌────────┐                                                     ┌────────┐
│ Client │                                                     │ Redis  │
└───┬────┘                                                     └───┬────┘
    │                                                              │
    │ POST /auth/login (Attempt #1)                              │
    ├────────────────────────────────────►                       │
    │           INCR wayz:ratelimit:login:{ip}                    │
    │           EXPIRE 900 (if new key)                           │
    │ ◄────────────────────────────────────────────────────────► │
    │           Returns: 1                                        │
    │ ◄────────────────────────────────────                       │
    │ 401 Unauthorized (wrong password)                           │
    │                                                              │
    │ POST /auth/login (Attempt #2-5)                            │
    ├────────────────────────────────────►                       │
    │           INCR wayz:ratelimit:login:{ip}                    │
    │ ◄────────────────────────────────────────────────────────► │
    │           Returns: 2, 3, 4, 5                               │
    │ ◄────────────────────────────────────                       │
    │ 401 Unauthorized (wrong password)                           │
    │                                                              │
    │ POST /auth/login (Attempt #6)                              │
    ├────────────────────────────────────►                       │
    │           INCR wayz:ratelimit:login:{ip}                    │
    │ ◄────────────────────────────────────────────────────────► │
    │           Returns: 6 (exceeds limit of 5)                   │
    │ ◄────────────────────────────────────                       │
    │ 429 Too Many Requests                                       │
    │ "Too many login attempts. Try again in 15 minutes"          │
    │                                                              │
```

## Component Interaction Matrix

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Component Interaction Matrix                      │
├──────────────┬──────────────┬──────────────┬────────────────────────┤
│ Component    │ Uses         │ Used By      │ Purpose                │
├──────────────┼──────────────┼──────────────┼────────────────────────┤
│ Throttler    │ Redis        │ All Routes   │ Global rate limiting   │
│ Guard        │              │ (APP_GUARD)  │ (100 req/min default)  │
├──────────────┼──────────────┼──────────────┼────────────────────────┤
│ JWT Strategy │ Token        │ JwtAuthGuard │ Validates JWT tokens   │
│              │ Blacklist    │              │ + checks blacklist     │
├──────────────┼──────────────┼──────────────┼────────────────────────┤
│ Token        │ CacheService │ JWT Strategy │ Manages token          │
│ Blacklist    │ (Redis)      │ AuthService  │ lifecycle & blacklist  │
│ Service      │              │              │                        │
├──────────────┼──────────────┼──────────────┼────────────────────────┤
│ Rate Limit   │ CacheService │ AuthService  │ Operation-specific     │
│ Service      │ (Redis)      │              │ rate limiting          │
├──────────────┼──────────────┼──────────────┼────────────────────────┤
│ Auth Service │ Rate Limit   │ Auth         │ Business logic for     │
│              │ Token        │ Controller   │ authentication         │
│              │ Blacklist    │              │                        │
├──────────────┼──────────────┼──────────────┼────────────────────────┤
│ Cache        │ Redis/Valkey │ All Services │ Key-value storage      │
│ Service      │              │              │ with TTL support       │
└──────────────┴──────────────┴──────────────┴────────────────────────┘
```

## Security Layers

```
┌─────────────────────────────────────────────────────────────────────┐
│                           SECURITY LAYERS                            │
└─────────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────────┐
    │  Layer 1: Global Rate Limiting (Throttler)               │
    │  • 100 requests/minute for all endpoints                 │
    │  • DDoS protection                                        │
    │  • IP-based tracking                                      │
    └───────────────────────┬──────────────────────────────────┘
                            │ Pass
                            ▼
    ┌──────────────────────────────────────────────────────────┐
    │  Layer 2: Operation Rate Limiting (RateLimitService)     │
    │  • Login: 5 attempts/15 min                              │
    │  • Register: 3 attempts/hour                             │
    │  • Brute force protection                                │
    └───────────────────────┬──────────────────────────────────┘
                            │ Pass
                            ▼
    ┌──────────────────────────────────────────────────────────┐
    │  Layer 3: JWT Validation (Passport JWT)                  │
    │  • Signature verification                                │
    │  • Expiration check                                      │
    │  • Payload validation                                    │
    └───────────────────────┬──────────────────────────────────┘
                            │ Valid
                            ▼
    ┌──────────────────────────────────────────────────────────┐
    │  Layer 4: Token Blacklist Check                          │
    │  • Is token blacklisted?                                 │
    │  • Is token in active tokens?                            │
    │  • Redis-backed validation                               │
    └───────────────────────┬──────────────────────────────────┘
                            │ Not Blacklisted
                            ▼
    ┌──────────────────────────────────────────────────────────┐
    │  Layer 5: User Account Status                            │
    │  • Is user account active?                               │
    │  • User exists in database?                              │
    │  • Database validation                                   │
    └───────────────────────┬──────────────────────────────────┘
                            │ Active
                            ▼
                   ┌─────────────────┐
                   │  ACCESS GRANTED  │
                   └─────────────────┘
```

## Data Flow Summary

```
User Action          Redis Keys Modified              Effect
─────────────────   ────────────────────────────   ──────────────────────
Login               • user:tokens:{userId} +token   Token tracked
                    • ratelimit:login:{ip} ++       Attempt counted

Access Resource     • throttle:default:{ip} ++      Request counted
                    [Read only checks]              No modification

Logout              • token:blacklist:{token}       Token invalidated
                    • user:tokens:{userId} -token   Token removed

Logout All          • user:tokens:{userId} DELETE   All tokens invalid

Change Password     • user:tokens:{userId} DELETE   All tokens invalid
                    • [Database] Update hash        Password changed

Token Expiry        [Automatic via Redis TTL]       Cleanup automatic
```

---

## Performance Characteristics

- **Token Validation**: O(1) - Redis hash lookup
- **Rate Limit Check**: O(1) - Redis counter increment
- **Blacklist Check**: O(1) - Redis key exists
- **Active Token Check**: O(1) - Redis set membership
- **Logout All**: O(n) - Where n = number of user tokens (typically small)

## Scalability

✅ **Horizontal Scaling**: Redis-backed, works across multiple app instances  
✅ **High Availability**: Redis can be clustered  
✅ **Low Latency**: In-memory operations  
✅ **Auto Cleanup**: TTL-based expiration  

---

*Architecture designed for enterprise-scale applications*
