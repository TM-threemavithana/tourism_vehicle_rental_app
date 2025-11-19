# 🔐 Authentication & Authorization Testing Guide

## 🚀 **Test Your Authentication System**

Base URL: `http://localhost:3000`  
Swagger Docs: `http://localhost:3000/api/v1/docs`

---

## 📋 **Authentication Endpoints**

### **1. Register New User**
```bash
POST /auth/register
Content-Type: application/json

{
  "email": "test.user@example.com",
  "password": "SecureTest123!",
  "firstName": "Test",
  "lastName": "User",
  "phoneNumber": "+94771234567"
}
```

**Expected Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "test.user@example.com",
    "firstName": "Test",
    "lastName": "User", 
    "role": "customer",
    "isEmailVerified": false
  }
}
```

### **2. Login with Email/Password**
```bash
POST /auth/login
Content-Type: application/json

{
  "email": "test.user@example.com",
  "password": "SecureTest123!"
}
```

### **3. Login with Firebase Token (Migration)**
```bash
POST /auth/firebase
Content-Type: application/json

{
  "firebaseToken": "your-firebase-id-token-here"
}
```

### **4. Get User Profile (Protected)**
```bash
GET /auth/profile
Authorization: Bearer your-jwt-token-here
```

### **5. Change Password (Protected)**
```bash
POST /auth/change-password
Authorization: Bearer your-jwt-token-here
Content-Type: application/json

{
  "currentPassword": "SecureTest123!",
  "newPassword": "NewSecureTest456!"
}
```

### **6. Refresh Token**
```bash
POST /auth/refresh
Content-Type: application/json

{
  "refreshToken": "your-refresh-token-here"
}
```

---

## 🛡️ **Protected API Endpoints**

### **Admin Only Endpoints**
These require `Authorization: Bearer admin-token` AND admin role:

```bash
# Get all users (Admin only)
GET /api/v1/users
Authorization: Bearer your-jwt-token-here

# Get user statistics (Admin only) 
GET /api/v1/users/stats
Authorization: Bearer your-jwt-token-here
```

### **User Data Protection**
Users can only access their own data:

```bash
# Get own profile (or admin can access any)
GET /api/v1/users/550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer your-jwt-token-here

# Update own profile (or admin can update any)
PATCH /api/v1/users/550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer your-jwt-token-here
Content-Type: application/json

{
  "firstName": "Updated Name"
}
```

---

## 🧪 **Testing Scenarios**

### **Scenario 1: New User Registration & Login**
1. Register a new user with POST `/auth/register`
2. Save the returned JWT token
3. Use the token to access GET `/auth/profile`
4. Try accessing admin endpoint GET `/api/v1/users` (should fail with 403)

### **Scenario 2: Admin Access Control**  
1. Create an admin user (manually set role to 'admin' in database)
2. Login as admin
3. Access GET `/api/v1/users` (should succeed)
4. Access GET `/api/v1/users/stats` (should succeed)

### **Scenario 3: User Data Privacy**
1. Register User A and User B
2. User A tries to access User B's profile (should fail)
3. User A accesses their own profile (should succeed)
4. Admin accesses any user's profile (should succeed)

### **Scenario 4: Firebase Migration**
1. Get a valid Firebase ID token from your Firebase project
2. Use POST `/auth/firebase` with the token
3. User should be auto-created with Firebase UID
4. Subsequent logins should work with either method

### **Scenario 5: Token Refresh**
1. Login and get access + refresh tokens
2. Wait for access token to expire (or use an expired one)  
3. Use POST `/auth/refresh` with refresh token
4. Get new access token and use it

---

## ❌ **Expected Error Responses**

### **401 Unauthorized**
```json
{
  "statusCode": 401,
  "message": "Unauthorized",
  "error": "Unauthorized"
}
```

### **403 Forbidden (Insufficient Role)**
```json
{
  "statusCode": 403,
  "message": "Forbidden resource",
  "error": "Forbidden"
}
```

### **409 Conflict (Email Exists)**
```json
{
  "statusCode": 409,
  "message": "User with this email already exists",
  "error": "Conflict"
}
```

---

## 🔍 **How to Test**

### **Using Swagger UI (Recommended)**
1. Go to `http://localhost:3000/api/v1/docs`
2. Test registration and login endpoints
3. Copy the JWT token from response
4. Click "Authorize" button in Swagger
5. Enter `Bearer your-jwt-token-here`
6. Test protected endpoints

### **Using curl**
```bash
# 1. Register user
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecureTest123!",
    "firstName": "Test",
    "lastName": "User"
  }'

# 2. Save token from response and test protected endpoint
curl -X GET http://localhost:3000/auth/profile \
  -H "Authorization: Bearer your-jwt-token-here"
```

### **Using Postman**
1. Import the API endpoints
2. Create environment variables for tokens
3. Set up automatic token extraction from login responses
4. Test the authentication flow

---

## 📊 **User Roles & Permissions**

| Role | Permissions |
|------|-------------|
| **customer** | - Access own profile<br>- Create bookings<br>- Add reviews<br>- Manage favorites |
| **owner** | - All customer permissions<br>- Create/manage own vehicles<br>- View own vehicle bookings<br>- Respond to reviews |
| **admin** | - All permissions<br>- View all users<br>- Access user statistics<br>- Manage any data<br>- System administration |

---

## 🔒 **Security Notes**

1. **JWT Tokens**: Store securely in HTTP-only cookies or secure storage
2. **Password Requirements**: Minimum 8 characters (can be enhanced)
3. **Token Expiry**: Access tokens expire in 15 minutes, refresh in 7 days
4. **Rate Limiting**: Consider adding rate limiting for production
5. **HTTPS**: Always use HTTPS in production
6. **Secret Keys**: Use strong, unique secrets for JWT signing

---

## 🚀 **Ready for Production**

The authentication system is production-ready with:
- ✅ Secure password hashing
- ✅ JWT token management  
- ✅ Role-based access control
- ✅ Firebase migration support
- ✅ Comprehensive error handling
- ✅ API documentation

**Test everything and then integrate with your Flutter app!** 🎉
