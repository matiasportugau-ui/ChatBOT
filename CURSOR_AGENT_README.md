# Cursor Agent - PostgreSQL Cursor Operations

## Overview

The **Cursor Agent** (`cursor_agent.py`) is a standalone Python module that provides transactional PostgreSQL cursor operations with automatic rollback, intelligent logging, and integration with SQLTools (VS Code extension) and orchestrated systems (PromptMaker, VMC, etc.).

## Features

- ✅ **Transactional Support**: Automatic BEGIN/COMMIT/ROLLBACK
- ✅ **Auto-Rollback**: Automatic transaction rollback on errors
- ✅ **Configurable Logging**: Log levels, targets (stdout/file), and sample rates
- ✅ **Cursor Lifecycle Management**: DECLARE, OPEN, FETCH, CLOSE operations
- ✅ **Custom Actions**: Support for PL/pgSQL functions or inline SQL blocks
- ✅ **Dual Interface**: Both CLI and programmatic API
- ✅ **SQLTools Integration**: Works with VS Code SQLTools extension
- ✅ **Environment Detection**: Automatic Docker vs local environment detection

## Installation

The Cursor Agent uses `psycopg2-binary` which is already in `requirements.txt`. No additional dependencies are required.

```bash
# Ensure dependencies are installed
pip install -r requirements.txt
```

## Quick Start

### 1. Using Configuration File

Create a configuration file (see `cursor_agent_config.example.json`):

```json
{
  "connection": {
    "server": "localhost",
    "port": 5432,
    "database": "atcdb",
    "username": "atc",
    "password": "atc_pass"
  },
  "cursor": {
    "query": "SELECT id, conversation_id FROM interactions WHERE created_at > NOW() - INTERVAL '1 day'",
    "action": "process_interaction"
  },
  "logging": {
    "level": "info",
    "target": "stdout"
  }
}
```

Run with CLI:

```bash
python cursor_agent.py --config cursor_agent_config.json
```

### 2. Using CLI Arguments

```bash
python cursor_agent.py \
  --query "SELECT id, resumen FROM interactions LIMIT 10" \
  --action "log_interaction" \
  --log-level INFO
```

### 3. Using Programmatic API

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
        'query': 'SELECT id, resumen FROM interactions',
        'action': 'process_interaction'
    }
}

agent = CursorAgent(config)
result = agent.execute()

print(f"Processed {result['rows_processed']} rows")
```

## Configuration Reference

### Connection Configuration

The agent supports multiple ways to configure database connections:

#### Option 1: Connection Object

```json
{
  "connection": {
    "server": "localhost",
    "port": 5432,
    "database": "atcdb",
    "username": "atc",
    "password": "atc_pass",
    "ssl": false
  }
}
```

#### Option 2: Connection String

```json
{
  "connection_string": "dbname=atcdb user=atc password=atc_pass host=localhost port=5432"
}
```

#### Option 3: Environment Variables

The agent automatically detects these environment variables:

- `DB_HOST` or `DOCKER_ENV=true` (uses "postgres" service name)
- `DB_PORT` (default: 5432)
- `DB_NAME` (default: "atcdb")
- `DB_USER` (default: "atc")
- `DB_PASS` (default: "atc_pass")
- `PG_DSN` (full connection string)

### Cursor Configuration

```json
{
  "cursor": {
    "name": "my_cursor",  // Optional: auto-generated if not provided
    "query": "SELECT id, name FROM table WHERE condition",
    "action": "process_row"  // Function name or SQL block
  }
}
```

### Logging Configuration

```json
{
  "logging": {
    "level": "info",  // DEBUG, INFO, WARNING, ERROR
    "target": "stdout",  // stdout, file, or both
    "file": "cursor_agent.log",  // Required if target is "file" or "both"
    "sample_rate": 0.1  // Log every Nth iteration (0.1 = every 10th)
  }
}
```

### Execution Configuration

```json
{
  "execution_mode": "transactional",  // transactional or auto-commit
  "auto_commit": false  // Override auto-commit behavior
}
```

## API Reference

### CursorAgent Class

#### Constructor

```python
CursorAgent(config: Optional[Dict[str, Any]] = None)
```

Creates a new CursorAgent instance.

**Parameters:**
- `config`: Configuration dictionary (optional, uses environment variables if not provided)

**Example:**
```python
agent = CursorAgent({
    'connection': {'server': 'localhost', 'database': 'mydb'},
    'cursor': {'query': 'SELECT * FROM table', 'action': 'process'}
})
```

#### execute()

```python
execute(query: Optional[str] = None, action: Optional[str] = None) -> Dict[str, Any]
```

Executes cursor operations with automatic transaction management.

**Parameters:**
- `query`: SQL query for cursor (optional, uses config if not provided)
- `action`: Action function/block to execute (optional, uses config if not provided)

**Returns:**
```python
{
    'success': bool,
    'cursor_name': str,
    'rows_processed': int,
    'errors': List[Dict]
}
```

**Example:**
```python
result = agent.execute()
if result['success']:
    print(f"Processed {result['rows_processed']} rows")
else:
    for error in result['errors']:
        print(f"Error: {error}")
```

#### execute_with_callback()

```python
execute_with_callback(query: str, callback: Callable[[Any], None]) -> Dict[str, Any]
```

Executes cursor operations with custom row processing callback.

**Parameters:**
- `query`: SQL query for cursor
- `callback`: Function to call for each row (receives row data as tuple)

**Returns:**
Same structure as `execute()`

**Example:**
```python
def process_row(row):
    row_id, name = row
    print(f"Processing row {row_id}: {name}")
    # Custom processing logic here

result = agent.execute_with_callback(
    "SELECT id, name FROM users",
    process_row
)
```

#### execute_plpgsql_block()

```python
execute_plpgsql_block(query: str, action_block: str) -> Dict[str, Any]
```

Executes cursor operations using a PL/pgSQL DO block. This method allows the action to access cursor variables using `FETCH ... INTO`, matching the original specification pattern.

**Parameters:**
- `query`: SQL query for cursor
- `action_block`: PL/pgSQL block that processes each row. Should use `FETCH ... INTO` to get row data.

**Returns:**
Same structure as `execute()`

**Example:**
```python
# Action block that uses FETCH ... INTO
action_block = """
DECLARE
    v_id BIGINT;
    v_name TEXT;
BEGIN
    FETCH NEXT FROM cursor_name INTO v_id, v_name;
    PERFORM process_row(v_id, v_name);
END;
"""

result = agent.execute_plpgsql_block(
    "SELECT id, name FROM users",
    action_block
)
```

**Note:** This method executes the entire cursor loop within PostgreSQL, which can be more efficient for complex operations but has limitations in returning row counts.

## CLI Reference

### Basic Usage

```bash
python cursor_agent.py [OPTIONS]
```

### Options

| Option | Description | Example |
|--------|-------------|---------|
| `--config` | Path to JSON configuration file | `--config config.json` |
| `--connection` | Connection string override | `--connection "dbname=test user=postgres"` |
| `--query` | Cursor query SQL | `--query "SELECT * FROM table"` |
| `--action` | Action function name | `--action "process_row"` |
| `--cursor-name` | Custom cursor name | `--cursor-name "my_cursor"` |
| `--log-level` | Logging level | `--log-level DEBUG` |
| `--dry-run` | Validate without executing | `--dry-run` |
| `--output-json` | Output results as JSON | `--output-json` |

### Examples

#### Validate Configuration

```bash
python cursor_agent.py --config config.json --dry-run
```

#### Execute with Custom Query

```bash
python cursor_agent.py \
  --query "SELECT id, name FROM users WHERE active = true" \
  --action "update_user_stats" \
  --log-level INFO
```

#### Output JSON Results

```bash
python cursor_agent.py --config config.json --output-json
```

## SQLTools Integration

### Setup

1. Install the SQLTools extension in VS Code
2. The `.vscode/settings.json` file is already configured with PostgreSQL connections
3. Open any SQL file and select the connection from SQLTools

### Using SQLTools

1. Open a SQL file (e.g., `query.sql`)
2. Click on the SQLTools icon in the sidebar
3. Select "PostgreSQL - ChatBOT (Docker)" or "PostgreSQL - ChatBOT (Local)"
4. Execute SQL queries directly

### Example SQL for Cursor Operations

You can test cursor operations directly in SQLTools:

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

## Integration with Orchestrated Systems

### PromptMaker Integration

```python
from cursor_agent import CursorAgent
import json

# Load config from PromptMaker
config = json.loads(promptmaker_config)

agent = CursorAgent(config)
result = agent.execute()

# Return result to PromptMaker
return json.dumps(result)
```

### VMC Integration

```python
from cursor_agent import CursorAgent

def vmc_handler(event, context):
    config = {
        'connection': {
            'server': event.get('db_host', 'localhost'),
            'database': event.get('db_name', 'atcdb'),
            'username': event.get('db_user', 'atc'),
            'password': event.get('db_pass', 'atc_pass')
        },
        'cursor': {
            'query': event['query'],
            'action': event['action']
        }
    }
    
    agent = CursorAgent(config)
    result = agent.execute()
    
    return {
        'statusCode': 200 if result['success'] else 500,
        'body': json.dumps(result)
    }
```

### Shell Script Integration

```bash
#!/bin/bash

# Execute cursor agent and capture result
RESULT=$(python cursor_agent.py --config config.json --output-json)

# Parse JSON result (requires jq)
SUCCESS=$(echo $RESULT | jq -r '.success')
ROWS=$(echo $RESULT | jq -r '.rows_processed')

if [ "$SUCCESS" = "true" ]; then
    echo "Successfully processed $ROWS rows"
else
    echo "Error occurred"
    exit 1
fi
```

## Action Functions

### Creating Action Functions

Action functions can be:

1. **PL/pgSQL Functions**: Pre-defined functions in the database
2. **SQL Blocks**: Inline SQL code

#### Example: PL/pgSQL Function

```sql
CREATE OR REPLACE FUNCTION process_interaction(
    p_id BIGINT,
    p_conversation_id TEXT,
    p_resumen TEXT
) RETURNS VOID AS $$
BEGIN
    -- Process the interaction
    INSERT INTO processed_interactions (id, conversation_id, resumen, processed_at)
    VALUES (p_id, p_conversation_id, p_resumen, NOW());
END;
$$ LANGUAGE plpgsql;
```

Configuration:
```json
{
  "cursor": {
    "query": "SELECT id, conversation_id, resumen FROM interactions",
    "action": "process_interaction(id, conversation_id, resumen)"
  }
}
```

#### Example: Inline SQL Block

```json
{
  "cursor": {
    "query": "SELECT id, resumen FROM interactions",
    "action": "INSERT INTO log_table (id, message) VALUES (id, resumen)"
  }
}
```

## Error Handling

The agent automatically handles errors with rollback:

```python
try:
    result = agent.execute()
    if not result['success']:
        # Check errors
        for error in result['errors']:
            print(f"Row {error.get('row', 'N/A')}: {error['error']}")
except Exception as e:
    print(f"Fatal error: {e}")
```

### Error Structure

```python
{
    'success': False,
    'errors': [
        {
            'row': 5,  # Row number (if applicable)
            'error': 'Error message'
        },
        {
            'type': 'postgresql_error',
            'error': 'Connection failed'
        }
    ]
}
```

## Logging

### Log Levels

- `DEBUG`: Detailed information for debugging
- `INFO`: General informational messages
- `WARNING`: Warning messages
- `ERROR`: Error messages only

### Log Targets

- `stdout`: Console output (default)
- `file`: File output (requires `file` path in config)
- `both`: Both console and file

### Sample Rate

For high-volume operations, use sample rate to reduce log noise:

```json
{
  "logging": {
    "sample_rate": 0.1  // Log every 10th iteration
  }
}
```

## Best Practices

1. **Always Use Transactions**: Keep `execution_mode: "transactional"` and `auto_commit: false`
2. **Handle Errors**: Check `result['success']` and process `result['errors']`
3. **Use Sample Rate**: For large datasets, set `sample_rate` to avoid log spam
4. **Test with Dry Run**: Use `--dry-run` to validate configuration
5. **Use Callbacks for Complex Logic**: Use `execute_with_callback()` for custom row processing
6. **Close Cursors Properly**: The agent handles this automatically, but ensure your SQL functions don't leave cursors open

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to database

**Solutions**:
- Check connection parameters in config
- Verify PostgreSQL is running: `docker ps | grep postgres`
- Test connection: `psql -h localhost -U atc -d atcdb`
- Check environment variables: `echo $DOCKER_ENV`

### Cursor Not Found

**Problem**: Error "cursor does not exist"

**Solutions**:
- Ensure cursor is declared before use
- Check cursor name matches in DECLARE and FETCH
- Verify transaction is still active

### Action Function Errors

**Problem**: Action function fails

**Solutions**:
- Verify function exists: `\df function_name` in psql
- Check function signature matches cursor query columns
- Review function permissions
- Check function logs for detailed errors

### Transaction Rollback

**Problem**: Changes not committed

**Solutions**:
- Check `auto_commit` setting (should be `false` for transactions)
- Verify `execution_mode` is `"transactional"`
- Review error logs for rollback reasons
- Ensure no exceptions occurred during execution

## Examples

### Example 1: Process Recent Interactions

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
        'query': """
            SELECT id, conversation_id, resumen, productos
            FROM interactions
            WHERE created_at > NOW() - INTERVAL '1 day'
            ORDER BY created_at
        """,
        'action': 'archive_interaction'
    },
    'logging': {
        'level': 'info',
        'target': 'stdout',
        'sample_rate': 0.1
    }
}

agent = CursorAgent(config)
result = agent.execute()

print(f"Archived {result['rows_processed']} interactions")
```

### Example 2: Custom Row Processing

```python
from cursor_agent import CursorAgent

def process_row(row):
    interaction_id, conversation_id, resumen = row
    # Custom processing
    print(f"Processing interaction {interaction_id}")
    # Could call external APIs, update other tables, etc.

config = {
    'connection': {
        'server': 'localhost',
        'database': 'atcdb',
        'username': 'atc',
        'password': 'atc_pass'
    },
    'logging': {
        'level': 'info',
        'target': 'stdout'
    }
}

agent = CursorAgent(config)
result = agent.execute_with_callback(
    "SELECT id, conversation_id, resumen FROM interactions LIMIT 100",
    process_row
)
```

### Example 3: CLI Usage with Environment Variables

```bash
export DB_HOST=localhost
export DB_NAME=atcdb
export DB_USER=atc
export DB_PASS=atc_pass

python cursor_agent.py \
  --query "SELECT id, resumen FROM interactions" \
  --action "log_interaction" \
  --log-level DEBUG \
  --output-json
```

## Testing

### Dry Run Test

```bash
python cursor_agent.py --config config.json --dry-run
```

### Unit Test Example

```python
import unittest
from cursor_agent import CursorAgent

class TestCursorAgent(unittest.TestCase):
    def test_config_loading(self):
        config = {
            'connection': {'server': 'localhost', 'database': 'test'},
            'cursor': {'query': 'SELECT 1', 'action': 'test'}
        }
        agent = CursorAgent(config)
        self.assertIsNotNone(agent.logger)
```

## License

Part of the ChatBOT-full project ecosystem.

## Support

For issues or questions:
1. Check this documentation
2. Review error logs
3. Verify database connectivity
4. Test with `--dry-run` flag

