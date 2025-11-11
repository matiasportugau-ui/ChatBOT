# SQLTools Connection Issue - Quick Fix

## Problem
SQLTools is asking for password for user 'postgres', but our project uses user 'atc'.

## Solution Options

### Option 1: Use the Correct Connection (Recommended)

1. **Cancel the current password prompt** (press Escape or click Cancel)

2. **In SQLTools sidebar**, look for these connections:
   - ✅ **"PostgreSQL - ChatBOT (Docker)"** (username: atc)
   - ✅ **"PostgreSQL - ChatBOT (Local)"** (username: atc)

3. **Connect to one of these** instead of "PostgreSQL Local"

4. **Password**: `atc_pass` (if prompted)

### Option 2: If You Need 'postgres' User

If you specifically need to connect as 'postgres' user:

1. **Check PostgreSQL password**:
   ```bash
   # For Docker
   docker exec -it <postgres_container> psql -U postgres -c "\password"
   
   # Or check docker-compose.yml for POSTGRES_PASSWORD
   ```

2. **Add a new connection** in SQLTools:
   - Name: "PostgreSQL - postgres user"
   - Username: `postgres`
   - Password: (your postgres password)
   - Other settings same as configured connections

### Option 3: Remove Old Connection

If "PostgreSQL Local" is an old connection you don't need:

1. Open SQLTools sidebar
2. Right-click on "PostgreSQL Local"
3. Select "Delete Connection"
4. Use "PostgreSQL - ChatBOT (Docker)" or "PostgreSQL - ChatBOT (Local)" instead

## Quick Reference

**Project Database Credentials:**
- Username: `atc`
- Password: `atc_pass`
- Database: `atcdb`
- Host: `localhost`
- Port: `5432`

**Pre-configured Connections:**
- ✅ PostgreSQL - ChatBOT (Docker) → Uses 'atc' user
- ✅ PostgreSQL - ChatBOT (Local) → Uses 'atc' user

## Still Having Issues?

1. Check PostgreSQL is running:
   ```bash
   docker-compose ps postgres
   ```

2. Test connection manually:
   ```bash
   PGPASSWORD=atc_pass psql -h localhost -p 5432 -U atc -d atcdb -c "SELECT 1;"
   ```

3. Reload VS Code/Cursor window to refresh SQLTools connections

