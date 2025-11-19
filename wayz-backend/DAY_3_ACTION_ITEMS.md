# 🎯 Day 3: Cloud Database Setup - Action Items

## 📋 Current Status
✅ **Backend Foundation**: NestJS backend with all dependencies ready
✅ **Environment Config**: `.env` configured for cloud databases
✅ **Database Schema**: Complete PostgreSQL schema ready for deployment
✅ **Setup Scripts**: PowerShell scripts ready for Railway connection strings

## 🚀 **NEXT: Set Up Railway (15 minutes)**

### **Step 1: Create Railway Account (2 minutes)**
1. Go to [https://railway.app](https://railway.app)
2. Click "Sign up" → Sign in with GitHub
3. Verify email if prompted

### **Step 2: Create PostgreSQL Database (3 minutes)**
1. Click "New Project"
2. Click "Provision PostgreSQL"
3. Wait for deployment (1-2 minutes)
4. ✅ PostgreSQL is ready!

### **Step 3: Add Redis Database (3 minutes)**
1. In the SAME project, click "+" button
2. Click "Add Service" → "Redis" 
3. Wait for deployment (1-2 minutes)
4. ✅ Redis is ready!

### **Step 4: Get Connection Strings (2 minutes)**

**For PostgreSQL:**
1. Click PostgreSQL service → "Connect" tab
2. Copy the **Database URL** (looks like: `postgresql://postgres:XXX@containers-us-west-YYY.railway.app:5432/railway`)

**For Redis:**
1. Click Redis service → "Connect" tab  
2. Copy the **Redis URL** (looks like: `redis://default:XXX@containers-us-west-YYY.railway.app:6379`)

### **Step 5: Update Environment (2 minutes)**
Run this PowerShell command in your backend directory:

```powershell
cd c:\Users\User\tourism_vehicle_rental_app\wayz-backend

# Replace YOUR_POSTGRES_URL and YOUR_REDIS_URL with actual URLs from Railway
.\setup-cloud-env.ps1 -PostgresUrl "YOUR_POSTGRES_URL" -RedisUrl "YOUR_REDIS_URL"
```

### **Step 6: Create Database Schema (3 minutes)**

**Option A: Using Railway Console (Recommended)**
1. In Railway, click your PostgreSQL service
2. Click "Query" tab
3. Copy & paste content from `database/schema.sql`
4. Click "Execute"

**Option B: Using psql Command Line**
```bash
# Install PostgreSQL client if needed, then:
psql "YOUR_POSTGRES_URL" -f database/schema.sql
```

## 🧪 **Test Your Setup (5 minutes)**

### **Step 7: Start Backend Server**
```powershell
npm run start:dev
```

You should see:
```
[Nest] Starting Nest application...
[Nest] TypeOrmModule dependencies initialized
[Nest] ConfigModule dependencies initialized  
[Nest] CacheModule dependencies initialized
[Nest] CommonModule dependencies initialized
[Nest] AppModule dependencies initialized
[Nest] Application is running on: http://localhost:3000/api/v1
```

### **Step 8: Test Health Endpoints**

**Test 1: Basic Health Check**
```
GET http://localhost:3000/health
```
Expected response:
```json
{
  "status": "ok",
  "timestamp": "2025-11-09T...",
  "uptime": 123.45,
  "environment": "development",
  "database": "connected",
  "firebase": "disabled",
  "dualWrite": "disabled"
}
```

**Test 2: API Status Check**
```
GET http://localhost:3000/api/v1/status  
```
Expected response:
```json
{
  "api": "Wayz Backend API",
  "version": "1.0.0", 
  "status": "operational",
  "features": {
    "dualWrite": false,
    "firebase": false,
    "migration": "phase-1-setup"
  }
}
```

## ✅ **Success Criteria**

When everything works, you should have:

- ✅ **Railway Account**: PostgreSQL + Redis databases running
- ✅ **Environment Config**: `.env` updated with cloud connection strings  
- ✅ **Database Schema**: Tourism vehicle rental tables created
- ✅ **Backend Running**: NestJS server starting without database errors
- ✅ **Health Endpoints**: Both `/health` and `/api/v1/status` responding correctly

## 🎉 **Day 3 Complete!**

After successful setup, you'll be ready for:

- **Day 4-5**: Create TypeORM entities and basic CRUD operations
- **Week 2**: Implement Firebase dual-write for migration
- **Week 3+**: Authentication, booking system, and mobile app integration

## 🆘 **Troubleshooting**

**Problem**: Database connection still failing
**Solution**: Double-check connection strings in `.env` file

**Problem**: Schema creation fails  
**Solution**: Make sure you're connected to Railway PostgreSQL, not local

**Problem**: Health endpoint shows "database: disconnected"
**Solution**: Restart the server after updating `.env`

---

**🚀 Ready to set up Railway? The setup takes about 15 minutes total!**

Once you complete Railway setup, paste your connection strings here and I'll help you configure everything!
