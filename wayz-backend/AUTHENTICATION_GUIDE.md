# 🔐 Authentication Flow Documentation

## Overview

This document provides comprehensive documentation for the authentication system implementation in the Wayz Vehicle Rental backend API.

## 📋 Authentication System Features

### ✅ Implemented
- JWT-based authentication with access and refresh tokens
- Role-based access control (CUSTOMER, OWNER, ADMIN)
- Password hashing with bcrypt (12 rounds)
- Token blacklisting for secure logout
- Rate limiting for authentication endpoints
- Email service for password reset
- Protected upload endpoints
- User profile management
- Input validation and sanitization

### 🚧 In Progress
- Email verification flow
- OAuth integration (Google, Facebook)
- Two-factor authentication (2FA)

## 🏗️ Architecture

### Core Components

1. **AuthService** (`src/auth/auth.service.ts`)
   - Handles user registration, login, password management
   - JWT token generation and validation
   - Password reset functionality with email integration

2. **JWT Strategy** (`src/auth/strategies/jwt.strategy.ts`)
   - Validates JWT tokens from requests
   - Extracts user information for protected routes

3. **Guards**
   - `JwtAuthGuard`: Validates JWT tokens
   - `RolesGuard`: Enforces role-based access control

4. **Decorators**
   - `@Roles()`: Specifies required roles for endpoints
   - `@CurrentUser()`: Extracts authenticated user from request

5. **Email Service** (`src/email/email.service.ts`)
   - Handles password reset emails
   - Welcome emails for new users
   - Booking confirmation emails

## 🔄 Authentication Flow

### Registration Flow
```
1. Client sends registration data
2. Server validates input (email, password strength, etc.)
3. Server checks if email already exists
4. Server hashes password with bcrypt
5. Server creates user record in database
6. Server generates JWT access and refresh tokens
7. Server sends welcome email (optional)
8. Server returns tokens and user data
```

### Login Flow
```
1. Client sends email/password
2. Server validates credentials
3. Server generates JWT tokens
4. Server returns tokens and user data
```

### Token Refresh Flow
```
1. Client sends refresh token
2. Server validates refresh token
3. Server checks if token is blacklisted
4. Server generates new access token
5. Server returns new tokens
```

### Password Reset Flow
```
1. Client requests password reset with email
2. Server generates reset token
3. Server sends reset email with token
4. Client submits new password with token
5. Server validates token and updates password
```

## 🔒 Security Measures

### Password Security
- Minimum 8 characters
- Hashed with bcrypt (12 rounds)
- No password in response objects

### Token Security
- JWT tokens with configurable expiry
- Refresh token rotation
- Token blacklisting on logout
- Secure HTTP-only cookies (recommended for production)

### Rate Limiting
- Login attempts: 5 per 15 minutes per IP
- Registration: 3 per hour per IP
- Password reset: 3 per hour per email

### Input Validation
- Email format validation
- Password strength requirements
- Phone number format validation
- XSS prevention with sanitization

## 🛡️ Role-Based Access Control

### User Roles
- `CUSTOMER`: Can book vehicles, view bookings
- `OWNER`: Can manage vehicles, view bookings for their vehicles
- `ADMIN`: Full system access

### Protected Endpoints

#### Upload Endpoints
```typescript
// Only OWNER and ADMIN can upload files
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.OWNER, UserRole.ADMIN)
@Post('single')
async uploadSingle(@UploadedFile() file, @CurrentUser() user) {
  // Implementation
}
```

#### Vehicle Management
```typescript
// Only OWNER and ADMIN can create vehicles
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.OWNER, UserRole.ADMIN)
@Post()
async createVehicle(@Body() createVehicleDto, @CurrentUser() user) {
  // Implementation
}
```

## 📡 API Endpoints

### Authentication Endpoints

#### POST /auth/register
Register a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+1234567890",
  "role": "CUSTOMER"
}
```

**Response:**
```json
{
  "accessToken": "jwt_token_here",
  "refreshToken": "refresh_token_here",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "CUSTOMER",
    "isEmailVerified": false,
    "createdAt": "2024-01-01T00:00:00.000Z"
  }
}
```

#### POST /auth/login
Authenticate user and get tokens.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Response:** Same as registration response.

#### POST /auth/refresh
Refresh access token using refresh token.

**Request:**
```json
{
  "refreshToken": "refresh_token_here"
}
```

**Response:** New access and refresh tokens.

#### POST /auth/forgot-password
Request password reset email.

**Request:**
```json
{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "message": "If the email exists, a reset link has been sent"
}
```

#### POST /auth/reset-password
Reset password using token from email.

**Request:**
```json
{
  "token": "reset_token_from_email",
  "newPassword": "NewSecurePassword123!"
}
```

**Response:**
```json
{
  "message": "Password reset successfully"
}
```

#### GET /auth/profile
Get current user profile (requires authentication).

**Headers:**
```
Authorization: Bearer jwt_token_here
```

**Response:**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "role": "CUSTOMER",
  "isEmailVerified": false,
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

#### POST /auth/logout
Logout and blacklist current token.

**Headers:**
```
Authorization: Bearer jwt_token_here
```

#### POST /auth/change-password
Change user password (requires authentication).

**Headers:**
```
Authorization: Bearer jwt_token_here
```

**Request:**
```json
{
  "currentPassword": "CurrentPassword123!",
  "newPassword": "NewPassword123!"
}
```

## 🔧 Environment Configuration

### Required Environment Variables

```bash
# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRES_IN=1h
JWT_REFRESH_SECRET=your_refresh_token_secret
JWT_REFRESH_EXPIRES_IN=7d

# Email Configuration
EMAIL_PROVIDER=smtp  # or 'sendgrid'
EMAIL_FROM=noreply@wayzvehiclerental.com

# SMTP Configuration (if using EMAIL_PROVIDER=smtp)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your_smtp_username
SMTP_PASS=your_smtp_password

# SendGrid Configuration (if using EMAIL_PROVIDER=sendgrid)
SENDGRID_API_KEY=your_sendgrid_api_key

# Frontend URL (for password reset links)
FRONTEND_URL=http://localhost:3000

# Database Configuration
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=wayz_rental
DATABASE_USER=postgres
DATABASE_PASSWORD=your_password

# Redis Configuration (for caching and rate limiting)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password
```

## 🧪 Testing

### Running Tests
```bash
# Unit tests
npm run test

# End-to-end tests
npm run test:e2e

# Test coverage
npm run test:cov
```

### Test Coverage
- Authentication flow tests
- Role-based access control tests
- Upload endpoint protection tests
- Error handling tests
- Token validation tests

## 🚀 Frontend Integration

### Setting Up Authentication in Flutter

#### 1. Store Tokens Securely
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
```

#### 2. HTTP Client with Authentication
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiClient {
  static const String baseUrl = 'http://your-backend-url.com';

  static Future<http.Response> authenticatedRequest(
    String method,
    String endpoint,
    {Map<String, dynamic>? body}
  ) async {
    final token = await AuthService.getAccessToken();
    
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse('$baseUrl$endpoint');

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      // Add other methods as needed
      default:
        throw UnsupportedError('HTTP method $method not supported');
    }
  }
}
```

#### 3. Login Implementation
```dart
class LoginService {
  static Future<bool> login(String email, String password) async {
    try {
      final response = await ApiClient.authenticatedRequest(
        'POST',
        '/auth/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await AuthService.saveTokens(
          data['accessToken'],
          data['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
}
```

### Replacing Firebase Auth

#### Before (Firebase):
```dart
// OLD Firebase implementation
final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: email,
  password: password,
);
```

#### After (Backend API):
```dart
// NEW Backend API implementation
final success = await LoginService.login(email, password);
if (success) {
  // Navigate to main screen
} else {
  // Show error message
}
```

## 🔍 Troubleshooting

### Common Issues

#### 1. "Invalid or expired token"
- Check token expiry time
- Verify JWT_SECRET matches between environments
- Ensure token is sent in Authorization header correctly

#### 2. "Access denied" (403)
- Verify user has correct role for the endpoint
- Check if RolesGuard is properly configured
- Ensure user is authenticated first

#### 3. Email not sending
- Verify SMTP credentials
- Check EMAIL_PROVIDER configuration
- Ensure firewall allows SMTP connections

#### 4. Redis connection errors
- Verify Redis server is running
- Check REDIS_HOST and REDIS_PORT configuration
- Ensure Redis authentication is configured correctly

### Debug Commands

```bash
# Check if backend is running
curl http://localhost:3000/health

# Test authentication
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Test protected endpoint
curl -X GET http://localhost:3000/auth/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 📈 Performance Considerations

### Optimization Strategies
1. **Token Caching**: Cache valid tokens in Redis
2. **Database Indexing**: Index frequently queried fields (email, reset tokens)
3. **Connection Pooling**: Use connection pooling for database
4. **Rate Limiting**: Implement proper rate limiting
5. **Token Cleanup**: Regularly clean expired tokens from blacklist

### Monitoring
- Track failed login attempts
- Monitor token refresh rates
- Alert on unusual authentication patterns
- Log security events

---

## 📞 Support

For questions or issues related to authentication:
1. Check this documentation first
2. Review the test files for examples
3. Check server logs for detailed error messages
4. Contact the development team

---

*Last updated: January 2024*
