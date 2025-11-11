# SQLTools Integration Guide

## Overview

SQLTools is integrated into the ChatBOT-full project to provide a seamless database development experience in VS Code/Cursor. This guide covers setup, usage, and integration with the Cursor Agent.

## Prerequisites

1. **VS Code or Cursor** installed
2. **SQLTools Extension** installed:
   - Main extension: `mtxr.sqltools`
   - PostgreSQL driver: `mtxr.sqltools-driver-pg`

### Installing Extensions

#### Option 1: Via VS Code/Cursor UI
1. Open Extensions view (`Cmd+Shift+X` / `Ctrl+Shift+X`)
2. Search for "SQLTools"
3. Install:
   - **SQLTools** by Matheus Teixeira
   - **SQLTools PostgreSQL/Redshift** by Matheus Teixeira

#### Option 2: Via Command Line
```bash
code --install-extension mtxr.sqltools
code --install-extension mtxr.sqltools-driver-pg
```

#### Option 3: Via Workspace Recommendations
The workspace file (`ChatBOTevo.code-workspace`) includes extension recommendations. VS Code/Cursor will prompt you to install them when opening the workspace.

## Configuration

### Automatic Configuration

The project includes pre-configured SQLTools settings in:
- `.vscode/settings.json` (workspace settings)
- `ChatBOTevo.code-workspace` (workspace file)

### Connection Profiles

Two connection profiles are configured:

#### 1. PostgreSQL - ChatBOT (Docker)
- **Server**: `localhost`
- **Port**: `5432`
- **Database**: `atcdb`
- **Username**: `atc`
- **Password**: `atc_pass`
- **Use when**: PostgreSQL is running in Docker

#### 2. PostgreSQL - ChatBOT (Local)
- **Server**: `localhost`
- **Port**: `5432`
- **Database**: `atcdb`
- **Username**: `atc`
- **Password**: `atc_pass`
- **Use when**: PostgreSQL is running locally

### Manual Connection Setup

If you need to add or modify connections:

1. Open SQLTools sidebar (SQLTools icon in Activity Bar)
2. Click the `+` button to add a new connection
3. Select "PostgreSQL"
4. Fill in connection details:
   - **Connection Name**: Choose a descriptive name
   - **Server**: `localhost` (or Docker service name if in Docker network)
   - **Port**: `5432`
   - **Database**: `atcdb`
   - **Username**: `atc`
   - **Password**: `atc_pass`
   - **SSL**: Disabled (for local development)

## Usage

### Connecting to Database

1. **Open SQLTools Sidebar**:
   - Click the SQLTools icon in the Activity Bar (left sidebar)
   - Or use Command Palette: `SQLTools: Focus on SQLTools Activity Bar`

2. **Select Connection**:
   - Click on a connection name (e.g., "PostgreSQL - ChatBOT (Docker)")
   - Click "Connect" button
   - Or right-click and select "Connect"

3. **Verify Connection**:
   - Green indicator means connected
   - Red indicator means connection failed

### Running SQL Queries

#### Method 1: SQL Files

1. Create or open a `.sql` file
2. Write your SQL query
3. Select the connection from the status bar (bottom of VS Code)
4. Execute query:
   - **Run Query**: `Cmd+E` / `Ctrl+E`
   - **Run Current Query**: `Cmd+Shift+E` / `Ctrl+Shift+E`
   - Right-click → "Run Query"

#### Method 2: Query Results Panel

1. Open SQLTools sidebar
2. Expand your connection
3. Right-click on a table → "Show Table Records"
4. Or use the query input at the top of SQLTools panel

#### Method 3: Command Palette

1. Open Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`)
2. Type "SQLTools: Run Query"
3. Select connection and execute

### Example Queries

#### View All Tables
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;
```

#### View Interactions
```sql
SELECT 
    id,
    conversation_id,
    resumen,
    productos,
    created_at
FROM interactions
ORDER BY created_at DESC
LIMIT 10;
```

#### View Knowledge Base
```sql
SELECT 
    id,
    topic,
    correction,
    context,
    created_at
FROM knowledge_base
ORDER BY created_at DESC;
```

#### Count Records
```sql
SELECT 
    'interactions' as table_name,
    COUNT(*) as record_count
FROM interactions
UNION ALL
SELECT 
    'knowledge_base' as table_name,
    COUNT(*) as record_count
FROM knowledge_base;
```

## Integration with Cursor Agent

### Using SQLTools to Test Cursor Queries

1. **Test Cursor Query**:
   ```sql
   BEGIN;
   
   DECLARE test_cursor CURSOR FOR
       SELECT id, conversation_id, resumen 
       FROM interactions 
       WHERE created_at > NOW() - INTERVAL '1 day';
   
   FETCH NEXT FROM test_cursor;
   -- Continue fetching...
   
   CLOSE test_cursor;
   COMMIT;
   ```

2. **Verify Query Results** before using in Cursor Agent

3. **Use in Cursor Agent**:
   ```python
   from cursor_agent import CursorAgent
   
   config = {
       'connection': {
           'server': 'localhost',
           'database': 'atcdb',
           'username': 'atc',
           'password': 'atc_pass'
       },
       'cursor': {
           'query': 'SELECT id, conversation_id, resumen FROM interactions WHERE created_at > NOW() - INTERVAL \'1 day\'',
           'action': 'process_interaction'
       }
   }
   
   agent = CursorAgent(config)
   result = agent.execute()
   ```

### Creating Action Functions

Use SQLTools to create and test PL/pgSQL functions:

```sql
-- Create a test function
CREATE OR REPLACE FUNCTION process_interaction(
    p_id BIGINT,
    p_conversation_id TEXT,
    p_resumen TEXT
) RETURNS VOID AS $$
BEGIN
    -- Your processing logic here
    INSERT INTO processed_interactions (id, conversation_id, resumen, processed_at)
    VALUES (p_id, p_conversation_id, p_resumen, NOW())
    ON CONFLICT (id) DO UPDATE
    SET processed_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- Test the function
SELECT process_interaction(1, 'test_conv', 'Test resumen');
```

## Database Schema Management

### View Schema

1. **In SQLTools Sidebar**:
   - Expand connection → Databases → `atcdb` → Schemas → `public` → Tables
   - Right-click table → "Show Table Records" or "Describe Table"

2. **Using SQL**:
   ```sql
   -- Describe table structure
   SELECT 
       column_name,
       data_type,
       is_nullable,
       column_default
   FROM information_schema.columns
   WHERE table_name = 'interactions'
   ORDER BY ordinal_position;
   ```

### Create/Modify Tables

Use SQLTools to execute schema changes:

```sql
-- Example: Add a new column
ALTER TABLE interactions 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';

-- Verify the change
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'interactions';
```

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to database

**Solutions**:
1. **Check PostgreSQL is running**:
   ```bash
   # Docker
   docker ps | grep postgres
   
   # Local
   psql -h localhost -U atc -d atcdb -c "SELECT 1;"
   ```

2. **Verify connection settings**:
   - Server: `localhost` (not `postgres` service name)
   - Port: `5432`
   - Database: `atcdb`
   - Username: `atc`
   - Password: `atc_pass`

3. **Check port forwarding** (Docker):
   ```bash
   docker-compose ps
   # Should show postgres:5432->5432/tcp
   ```

4. **Test connection manually**:
   ```bash
   psql -h localhost -p 5432 -U atc -d atcdb
   ```

### Extension Not Working

**Problem**: SQLTools extension not appearing

**Solutions**:
1. Reload VS Code/Cursor window
2. Check extensions are installed:
   - `mtxr.sqltools`
   - `mtxr.sqltools-driver-pg`
3. Check Output panel for errors:
   - View → Output → Select "SQLTools" from dropdown

### Query Execution Errors

**Problem**: Queries fail to execute

**Solutions**:
1. **Check connection is active** (green indicator)
2. **Verify SQL syntax** (use SQLTools syntax highlighting)
3. **Check database permissions**:
   ```sql
   SELECT current_user, current_database();
   ```
4. **Review error messages** in SQLTools Results panel

## Best Practices

1. **Use Connection Profiles**: Create separate profiles for different environments (dev, staging, prod)

2. **Save Queries**: Save frequently used queries in `.sql` files in a `queries/` directory

3. **Use Transactions**: Wrap DML operations in transactions:
   ```sql
   BEGIN;
   -- Your changes
   -- Review results
   COMMIT; -- or ROLLBACK;
   ```

4. **Version Control**: Commit `.sql` files but never commit connection passwords in workspace settings

5. **Test Before Production**: Always test queries in SQLTools before using in Cursor Agent

6. **Use Query History**: SQLTools saves query history - use it to review and reuse queries

## Advanced Features

### Query Snippets

Create reusable SQL snippets:

1. Open Command Palette
2. Type "SQLTools: Manage Snippets"
3. Add custom snippets for common queries

### Export Results

1. Execute query in SQLTools
2. Right-click results → "Export Results"
3. Choose format: CSV, JSON, Excel

### Compare Connections

Use SQLTools to compare data between connections:
1. Open multiple connections
2. Run same query on each
3. Compare results side-by-side

## Integration with Project Workflow

### Development Workflow

1. **Start PostgreSQL**:
   ```bash
   docker-compose up -d postgres
   # or
   ./start_knowledge_base.sh
   ```

2. **Connect SQLTools** to database

3. **Test queries** in SQLTools

4. **Use in Cursor Agent** once queries are validated

5. **Monitor results** using SQLTools query history

### CI/CD Integration

SQLTools can be used for:
- Database migration testing
- Data validation queries
- Performance testing
- Schema verification

## Resources

- **SQLTools Documentation**: https://vscode-sqltools.mteixeira.dev/
- **PostgreSQL Driver**: https://github.com/mtxr/vscode-sqltools/tree/master/packages/driver.pg
- **Project Cursor Agent Docs**: See `CURSOR_AGENT_README.md`

## Quick Reference

### Keyboard Shortcuts

| Action | Mac | Windows/Linux |
|--------|-----|---------------|
| Run Query | `Cmd+E` | `Ctrl+E` |
| Run Current Query | `Cmd+Shift+E` | `Ctrl+Shift+E` |
| Focus SQLTools | `Cmd+Shift+P` → "SQLTools: Focus" | `Ctrl+Shift+P` → "SQLTools: Focus" |
| New Query | `Cmd+N` → Save as `.sql` | `Ctrl+N` → Save as `.sql` |

### Common Commands

- `SQLTools: Add New Connection`
- `SQLTools: Focus on SQLTools Activity Bar`
- `SQLTools: Run Query`
- `SQLTools: Show Output Channel`
- `SQLTools: Manage Snippets`

---

**Last Updated**: 2025-01-XX  
**Project**: ChatBOT-full  
**Database**: PostgreSQL 15

