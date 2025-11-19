# PostgreSQL Client Installation Guide for Windows

## Method 1: Download PostgreSQL (Recommended)

1. **Download PostgreSQL**:
   - Go to: https://www.postgresql.org/download/windows/
   - Click "Download the installer"
   - Choose the latest version for Windows x86-64

2. **Install PostgreSQL**:
   - Run the downloaded installer
   - During installation, you can uncheck "PostgreSQL Server" if you only want the client tools
   - Make sure "Command Line Tools" is checked
   - Complete the installation

3. **Add to PATH** (usually automatic):
   - PostgreSQL should add itself to PATH
   - Restart your terminal/PowerShell

## Method 2: Use Aiven Console (Easier Alternative)

Since you already have Aiven.io setup, you can create the schema directly in the Aiven console:

1. **Go to Aiven Console**:
   - Visit: https://console.aiven.io
   - Click on your PostgreSQL service

2. **Open Query Editor**:
   - Click "Query" tab in your PostgreSQL service
   - This opens a web-based SQL editor

3. **Run Schema Creation**:
   - Copy the content from `database/schema.sql`
   - Paste it into the query editor
   - Click "Execute" or "Run"

## Method 3: Use Database Client Tool

Download a PostgreSQL client like:
- **DBeaver** (free): https://dbeaver.io/
- **pgAdmin** (free): https://www.pgadmin.org/
- **DataGrip** (paid): https://www.jetbrains.com/datagrip/

## Method 4: Use Online PostgreSQL Client

Some online tools can connect to your Aiven PostgreSQL:
- **Adminer**: Lightweight web-based database tool
- **phpPgAdmin**: Web-based PostgreSQL administration

---

**Recommendation**: Use **Aiven Console Query Editor** - it's the fastest and doesn't require installation!
