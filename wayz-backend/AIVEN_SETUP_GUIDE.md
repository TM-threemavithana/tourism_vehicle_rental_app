# 🚀 Aiven.io Setup Guide - Day 3 Alternative

## 🎯 Why Aiven.io?

Since Railway trial has expired, **Aiven.io** is an excellent alternative:

- ✅ **$300 free credits** (3-4 months of free usage)
- ✅ **Enterprise-grade** managed databases
- ✅ **Multiple cloud providers** (AWS, Google Cloud, Azure)
- ✅ **Excellent performance** and reliability
- ✅ **PostgreSQL + Redis** on one platform
- ✅ **No credit card required** for signup

## 🚀 Step-by-Step Aiven.io Setup (15 minutes)

### **Step 1: Create Account (3 minutes)**

1. **Visit**: [https://aiven.io](https://aiven.io)
2. **Click**: "Sign up for free"
3. **Sign up** with email or GitHub account
4. **Verify** your email
5. **Complete** profile setup
6. **Get $300 free credits** automatically!

### **Step 2: Create PostgreSQL Service (5 minutes)**

1. **Click**: "Create service"
2. **Select**: "PostgreSQL"
3. **Configure**:
   - **Cloud provider**: AWS (recommended)
   - **Region**: Choose closest to your location (e.g., US East, EU West)
   - **Service plan**: Select "Startup-4" (4GB RAM, $19/month - covered by free credits)
   - **Service name**: `tourism-postgres`
4. **Click**: "Create service"
5. **Wait**: 2-5 minutes for deployment
6. **Status**: Should show "Running" when ready

### **Step 3: Create Redis Service (5 minutes)**

1. **Click**: "Create service" again
2. **Select**: "Redis"
3. **Configure**:
   - **Cloud provider**: Same as PostgreSQL
   - **Region**: Same as PostgreSQL  
   - **Service plan**: Select "Startup-4" ($15/month - covered by free credits)
   - **Service name**: `tourism-redis`
4. **Click**: "Create service"
5. **Wait**: 2-5 minutes for deployment
6. **Status**: Should show "Running" when ready

### **Step 4: Get Connection Strings (2 minutes)**

**PostgreSQL Connection:**
1. Click on **"tourism-postgres"** service
2. Go to **"Overview"** tab
3. Find **"Service URI"**
4. Copy the full URI (looks like: `postgresql://avnadmin:PASSWORD@pg-xyz.aivencloud.com:12345/defaultdb`)

**Redis Connection:**
1. Click on **"tourism-redis"** service
2. Go to **"Overview"** tab  
3. Find **"Service URI"**
4. Copy the full URI (looks like: `redis://default:PASSWORD@redis-xyz.aivencloud.com:12345`)

## 🔧 Update Your Environment

### **Method 1: Use PowerShell Script (Recommended)**

```powershell
# Run this in your wayz-backend directory
.\setup-aiven-env.ps1 -PostgresUrl "YOUR_POSTGRES_URI" -RedisUrl "YOUR_REDIS_URI"

# Example:
.\setup-aiven-env.ps1 `
  -PostgresUrl "postgresql://avnadmin:xyz123@pg-abc.aivencloud.com:12345/defaultdb" `
  -RedisUrl "redis://default:abc456@redis-def.aivencloud.com:12345"
```

### **Method 2: Manual Update**

Edit your `.env` file directly:

```env
# Aiven PostgreSQL
DATABASE_HOST=pg-xyz.aivencloud.com
DATABASE_PORT=12345
DATABASE_USERNAME=avnadmin  
DATABASE_PASSWORD=your_postgres_password
DATABASE_NAME=defaultdb

# Aiven Redis
REDIS_HOST=redis-xyz.aivencloud.com
REDIS_PORT=12345
REDIS_PASSWORD=your_redis_password
```

## 🗄️ Create Database Schema

### **Method 1: Aiven Console (Easiest)**

1. **Go to**: PostgreSQL service in Aiven console
2. **Click**: "Query" tab
3. **Copy & paste**: Contents from `database/schema.sql`
4. **Click**: "Execute"

### **Method 2: psql Command Line**

```bash
# If you have psql installed
psql "postgresql://avnadmin:PASSWORD@pg-xyz.aivencloud.com:12345/defaultdb" -f database/schema.sql
```

### **Method 3: Database Client**

Use any PostgreSQL client (DBeaver, pgAdmin, etc.) with the connection string.

## 🧪 Test Your Setup

### **Step 1: Start Backend**
```powershell
npm run start:dev
```

### **Step 2: Expected Output**
```
[Nest] Starting Nest application...
[Nest] TypeOrmModule dependencies initialized +15ms
[Nest] ConfigModule dependencies initialized +1ms
[Nest] CacheModule dependencies initialized +0ms
[Nest] CommonModule dependencies initialized +5ms  
[Nest] AppModule dependencies initialized +1ms
[Nest] Application is running on: http://localhost:3000/api/v1
```

### **Step 3: Test Endpoints**

**Health Check:**
```
GET http://localhost:3000/health
```

**API Status:**
```
GET http://localhost:3000/api/v1/status
```

## 💰 Cost Estimation

**Monthly Costs (covered by $300 free credits):**
- PostgreSQL Startup-4: ~$19/month
- Redis Startup-4: ~$15/month
- **Total**: ~$34/month
- **Free usage**: ~8-9 months with $300 credits!

## 🔄 Migration Path

**Future Options:**
1. **Continue with Aiven** (excellent for production)
2. **Migrate to AWS RDS/ElastiCache** (if you prefer AWS)
3. **Self-hosted** (if you want more control)

## 🆘 Troubleshooting

**Connection Issues:**
- Verify service status is "Running" in Aiven console
- Check connection string format
- Ensure correct region/firewall settings

**Schema Creation Issues:**
- Make sure PostgreSQL service is fully initialized
- Try creating schema via Aiven console first

**Performance Issues:**
- Consider upgrading service plan if needed
- Monitor usage in Aiven console

---

## ✅ Success Checklist

- [ ] Aiven account created with $300 credits
- [ ] PostgreSQL service running
- [ ] Redis service running
- [ ] Connection strings copied
- [ ] Environment variables updated  
- [ ] Database schema created
- [ ] Backend server connecting successfully
- [ ] Health endpoints responding

**🎉 Once complete, you'll have a production-ready cloud database setup!**
