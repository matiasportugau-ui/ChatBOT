# SQL Queries Directory

This directory contains SQL queries for the ChatBOT-full project.

## Files

- **`example_queries.sql`**: Comprehensive collection of example queries for:
  - Database information
  - Interactions table queries
  - Knowledge base queries
  - Cursor examples for Cursor Agent
  - Analytics queries
  - Maintenance queries

## Usage

### In SQLTools

1. Open SQLTools sidebar in VS Code/Cursor
2. Connect to "PostgreSQL - ChatBOT (Docker)" or "PostgreSQL - ChatBOT (Local)"
3. Open any `.sql` file from this directory
4. Select the connection from the status bar
5. Execute queries using:
   - `Cmd+E` / `Ctrl+E` to run query
   - `Cmd+Shift+E` / `Ctrl+Shift+E` to run current query
   - Right-click → "Run Query"

### In Cursor Agent

Copy queries from `example_queries.sql` and use them in Cursor Agent configuration:

```json
{
  "cursor": {
    "query": "SELECT id, conversation_id, resumen FROM interactions WHERE created_at > NOW() - INTERVAL '1 day'",
    "action": "process_interaction"
  }
}
```

## Adding New Queries

When adding new queries:

1. Add them to `example_queries.sql` with appropriate comments
2. Organize by category (use section headers)
3. Include usage notes if needed
4. Test queries in SQLTools before using in production

## Best Practices

- Always test queries in SQLTools first
- Use transactions for data modification queries
- Review results before committing changes
- Keep queries organized and commented
- Document any special requirements or dependencies

