# Fix: getaddrinfo ENOTFOUND Error

## Problem
SQLTools shows error: `getaddrinfo ENOTFOUND PostgreSQL - ChatBOT (Local)`

This happens when SQLTools tries to resolve the connection name as a hostname instead of using the `server` field.

## Solution

### Step 1: Reload VS Code/Cursor
1. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
2. Type: `Developer: Reload Window`
3. Press Enter

### Step 2: Clear SQLTools Cache
1. Open SQLTools sidebar
2. Right-click on any old/broken connection
3. Select "Delete Connection"
4. Delete all connections that show errors

### Step 3: Use New Connection Names
I've updated the configuration with simpler connection names:
- ✅ **ChatBOT-Docker** (instead of "PostgreSQL - ChatBOT (Docker)")
- ✅ **ChatBOT-Local** (instead of "PostgreSQL - ChatBOT (Local)")

### Step 4: Connect Again
1. Open SQLTools sidebar
2. You should see the new connections: **ChatBOT-Docker** and **ChatBOT-Local**
3. Click on **ChatBOT-Docker**
4. Click "Connect" button
5. If prompted for password, enter: `atc_pass`

## If Still Not Working

### Manual Connection Setup
1. In SQLTools sidebar, click the `+` button
2. Select "PostgreSQL"
3. Fill in:
   - **Connection Name**: `ChatBOT-Docker`
   - **Server**: `localhost` (NOT the connection name!)
   - **Port**: `5432`
   - **Database**: `atcdb`
   - **Username**: `atc`
   - **Password**: `atc_pass`
   - **SSL**: Disabled
4. Click "Test Connection"
5. If successful, click "Save Connection"

### Verify PostgreSQL is Running
```bash
# Check if PostgreSQL container is running
docker ps | grep postgres

# If not running, start it:
docker-compose up -d postgres

# Test connection manually
PGPASSWORD=atc_pass psql -h localhost -p 5432 -U atc -d atcdb -c "SELECT 1;"
```

## Key Points

⚠️ **Important**: The `server` field must be `localhost`, NOT the connection name!

- ✅ Correct: `"server": "localhost"`
- ❌ Wrong: `"server": "PostgreSQL - ChatBOT (Local)"`

The connection name is just a label - SQLTools uses the `server` field to actually connect.

## Updated Configuration

The configuration files have been updated with:
- Simpler connection names (no spaces, no parentheses)
- Correct server settings (`localhost`)
- All required fields properly set

After reloading VS Code/Cursor, the new connections should work correctly.

