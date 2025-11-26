# 🔥 Firebase Service Account Setup Guide

This guide will help you set up the Firebase service account for the migration system.

## 📋 Prerequisites

- Access to Firebase Console
- Your Firebase project (the one with existing Firestore data)

## 🔑 Step 1: Generate Firebase Service Account Key

### Option A: Using Firebase Console (Recommended)

1. **Go to Firebase Console**
   - Visit: https://console.firebase.google.com/
   - Select your project

2. **Navigate to Project Settings**
   - Click the gear icon ⚙️ next to "Project Overview"
   - Select "Project settings"

3. **Go to Service Accounts Tab**
   - Click the "Service accounts" tab
   - You'll see "Firebase Admin SDK" section

4. **Generate New Private Key**
   - Click "Generate new private key"
   - Confirm the action
   - A JSON file will be downloaded

5. **Save the File**
   - Rename it to `firebase-service-account.json`
   - Move it to your backend directory: `wayz-backend/firebase-service-account.json`

### Option B: Using Google Cloud Console

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Select your Firebase project

2. **Navigate to Service Accounts**
   - Go to "IAM & Admin" > "Service Accounts"
   - Find the Firebase Admin SDK service account

3. **Create Key**
   - Click the three dots menu
   - Select "Manage keys"
   - Click "Add Key" > "Create new key"
   - Choose "JSON" format
   - Download the file

## 📄 Step 2: Update .env File

The service account JSON file contains these fields:
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "key-id-here",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

### Update your `.env` file with these values:

```env
# Firebase Admin SDK Configuration
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
```

**Important Notes:**
- Keep the quotes around `FIREBASE_PRIVATE_KEY`
- Keep the `\n` characters (they represent newlines)
- Don't remove the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` parts

## 🔐 Step 3: Secure the Service Account File

### Add to .gitignore

Make sure your `.gitignore` includes:
```gitignore
# Firebase service account
firebase-service-account.json
*.json

# Environment variables
.env
.env.local
.env.*.local
```

### Set Proper Permissions (Linux/Mac)

```bash
chmod 600 firebase-service-account.json
```

## 🧪 Step 4: Test Firebase Connection

### Option 1: Quick Test Script

Create a test file `test-firebase.ts`:

```typescript
import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert('./firebase-service-account.json'),
});

async function testConnection() {
  try {
    const db = admin.firestore();
    const testDoc = await db.collection('users').limit(1).get();
    
    console.log('✅ Firebase connection successful!');
    console.log(`Found ${testDoc.size} document(s) in users collection`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Firebase connection failed:', error);
    process.exit(1);
  }
}

testConnection();
```

Run the test:
```bash
npx ts-node test-firebase.ts
```

### Option 2: Use Migration System

The migration system includes built-in connection testing:

```bash
# Test connection
npm run migrate:backup

# This will attempt to connect and create a backup
# If it fails, check your Firebase credentials
```

## 🎯 Migration System Setup

### Environment Variables Checklist

Make sure all these are set in your `.env`:

```env
# ✅ Database (PostgreSQL)
DATABASE_HOST=pg-4a2bf3f-wayz.k.aivencloud.com
DATABASE_PORT=17019
DATABASE_USERNAME=avnadmin
DATABASE_PASSWORD=AVNS_Yg1A9GQmC6P0ErX8msM
DATABASE_NAME=defaultdb

# ✅ Firebase
FIREBASE_PROJECT_ID=your-actual-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com

# ✅ JWT
JWT_SECRET=your-jwt-secret
JWT_REFRESH_SECRET=your-refresh-secret
```

## 📚 Firebase Collections Structure

Your Firebase project should have these collections:

```
📁 users/
  └─ {userId}/
      ├─ email
      ├─ name
      └─ ...

📁 vehicles/
  └─ {vehicleId}/
      ├─ make
      ├─ model
      ├─ ownerId
      └─ ...

📁 bookings/
  └─ {bookingId}/
      ├─ userId
      ├─ vehicleId
      └─ ...

📁 favorites/
  └─ {favoriteId}/
      ├─ userId
      ├─ vehicleId
      └─ ...

📁 reviews/
  └─ {reviewId}/
      ├─ userId
      ├─ vehicleId
      └─ ...
```

## 🚀 Next Steps

After setting up Firebase credentials:

1. **Backup Your Data**
   ```bash
   npm run migrate:backup
   ```

2. **Validate Backup**
   - Check `wayz-backend/backups/` directory
   - Verify JSON files contain your data

3. **Run Dry Run Migration**
   ```bash
   npm run migrate:dry-run
   ```

4. **Run Actual Migration**
   ```bash
   npm run migrate:run
   ```

5. **Validate Migration**
   ```bash
   npm run migrate:validate
   ```

## ⚠️ Common Issues

### Issue 1: "Invalid service account"
**Solution:** Check that your `private_key` is complete and includes `\n` characters

### Issue 2: "Permission denied"
**Solution:** Ensure the service account has "Firebase Admin SDK Admin Service Agent" role

### Issue 3: "Collection not found"
**Solution:** Verify your Firestore collections exist and have data

### Issue 4: "ENOENT: no such file"
**Solution:** Make sure `firebase-service-account.json` is in the correct directory

## 🔒 Security Best Practices

1. **Never commit service account files to git**
2. **Use environment variables in production**
3. **Rotate service account keys regularly**
4. **Restrict service account permissions to minimum required**
5. **Use different service accounts for dev/staging/prod**

## 📞 Need Help?

If you encounter issues:
1. Check the [MIGRATION_TROUBLESHOOTING.md](./MIGRATION_TROUBLESHOOTING.md) guide
2. Review Firebase Console logs
3. Check backend server logs: `npm run start:dev`
4. Verify network connectivity to Firebase

## 📖 Related Documentation

- [MIGRATION_QUICK_START.md](./MIGRATION_QUICK_START.md) - Quick migration guide
- [MIGRATION_GUIDE.md](./MIGRATION_GUIDE.md) - Complete migration documentation
- [Firebase Admin SDK Documentation](https://firebase.google.com/docs/admin/setup)
