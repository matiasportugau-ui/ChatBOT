#!/usr/bin/env python3
"""
Cursor Agent - PostgreSQL Cursor Operations with Transactional Support

Provides transactional cursor operations for PostgreSQL with auto-rollback,
logging, and integration with SQLTools and orchestrated systems.
"""

import os
import sys
import json
import logging
import argparse
import psycopg2
from psycopg2 import sql, Error as PGError
from typing import Dict, Any, Optional, Callable, List
from contextlib import contextmanager


class CursorAgent:
    """
    Agent for executing PostgreSQL cursor operations with transactional support.
    
    Supports:
    - Declare, open, fetch, close cursor operations
    - Automatic transaction management (BEGIN/COMMIT/ROLLBACK)
    - Auto-rollback on errors
    - Configurable logging
    - Custom action functions
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize CursorAgent with configuration.
        
        Args:
            config: Configuration dictionary. If None, uses environment variables.
        """
        self.config = config or {}
        self.connection = None
        self.cursor = None
        self.logger = None
        self._setup_logging()
        self._setup_connection()
    
    def _setup_logging(self):
        """Configure logging based on config."""
        log_config = self.config.get('logging', {})
        level_str = log_config.get('level', 'INFO').upper()
        level = getattr(logging, level_str, logging.INFO)
        
        # Create logger
        self.logger = logging.getLogger('cursor_agent')
        self.logger.setLevel(level)
        
        # Remove existing handlers
        self.logger.handlers.clear()
        
        # Add handler based on target
        target = log_config.get('target', 'stdout')
        if target == 'stdout' or target == 'both':
            handler = logging.StreamHandler(sys.stdout)
            handler.setLevel(level)
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            self.logger.addHandler(handler)
        
        if target == 'file' or target == 'both':
            log_file = log_config.get('file', 'cursor_agent.log')
            handler = logging.FileHandler(log_file)
            handler.setLevel(level)
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            self.logger.addHandler(handler)
        
        self.sample_rate = log_config.get('sample_rate', 1.0)
        self._iteration_count = 0
    
    def _setup_connection(self):
        """Setup database connection from config or environment."""
        # Check if connection string is provided
        conn_str = self.config.get('connection_string')
        if conn_str:
            self.connection_string = conn_str
        else:
            # Build from connection config or environment
            conn_config = self.config.get('connection', {})
            
            # Support Docker vs local (from actions.py pattern)
            is_docker = os.getenv("DOCKER_ENV", "false").lower() == "true"
            default_host = "postgres" if is_docker else "localhost"
            
            host = conn_config.get('server') or os.getenv('DB_HOST', default_host)
            port = conn_config.get('port') or int(os.getenv('DB_PORT', 5432))
            database = conn_config.get('database') or os.getenv('DB_NAME', 'atcdb')
            username = conn_config.get('username') or os.getenv('DB_USER', 'atc')
            password = conn_config.get('password') or os.getenv('DB_PASS', 'atc_pass')
            ssl = conn_config.get('ssl', False)
            
            # Build connection string
            ssl_mode = "require" if ssl else "disable"
            self.connection_string = (
                f"dbname={database} user={username} password={password} "
                f"host={host} port={port} sslmode={ssl_mode}"
            )
        
        self.logger.debug(f"Connection string configured (host hidden)")
    
    @contextmanager
    def _get_connection(self):
        """Context manager for database connection."""
        try:
            conn = psycopg2.connect(self.connection_string)
            conn.autocommit = self.config.get('auto_commit', False)
            self.logger.debug("Database connection established")
            yield conn
        except PGError as e:
            self.logger.error(f"Database connection error: {e}")
            raise
        finally:
            if conn:
                conn.close()
                self.logger.debug("Database connection closed")
    
    def _should_log_iteration(self) -> bool:
        """Check if current iteration should be logged based on sample rate."""
        self._iteration_count += 1
        if self.sample_rate >= 1.0:
            return True
        return (self._iteration_count % int(1.0 / self.sample_rate)) == 0
    
    def _generate_cursor_name(self) -> str:
        """Generate a unique cursor name."""
        cursor_config = self.config.get('cursor', {})
        if 'name' in cursor_config:
            return cursor_config['name']
        # Generate default name
        import uuid
        return f"cursor_{uuid.uuid4().hex[:8]}"
    
    def execute(self, query: Optional[str] = None, action: Optional[str] = None) -> Dict[str, Any]:
        """
        Execute cursor operations with automatic transaction management.
        
        Args:
            query: SQL query for cursor. If None, uses config.
            action: Action function/block to execute. If None, uses config.
        
        Returns:
            Dictionary with execution results and statistics.
        """
        cursor_config = self.config.get('cursor', {})
        cursor_query = query or cursor_config.get('query')
        cursor_action = action or cursor_config.get('action')
        cursor_name = self._generate_cursor_name()
        
        if not cursor_query:
            raise ValueError("Cursor query is required (provide via config or query parameter)")
        
        if not cursor_action:
            raise ValueError("Cursor action is required (provide via config or action parameter)")
        
        execution_mode = self.config.get('execution_mode', 'transactional')
        auto_commit = self.config.get('auto_commit', False)
        
        result = {
            'success': False,
            'cursor_name': cursor_name,
            'rows_processed': 0,
            'errors': []
        }
        
        conn = None
        try:
            conn = psycopg2.connect(self.connection_string)
            conn.autocommit = auto_commit
            
            with conn.cursor() as cur:
                # Begin transaction if not auto-commit
                if execution_mode == 'transactional' and not auto_commit:
                    cur.execute("BEGIN")
                    self.logger.info("Transaction started")
                
                try:
                    # Declare cursor
                    declare_sql = sql.SQL("DECLARE {cursor} CURSOR FOR {query}").format(
                        cursor=sql.Identifier(cursor_name),
                        query=sql.SQL(cursor_query)
                    )
                    cur.execute(declare_sql)
                    self.logger.info(f"Cursor '{cursor_name}' declared")
                    
                    # Iterate through cursor
                    rows_processed = 0
                    while True:
                        # Fetch next row
                        fetch_sql = sql.SQL("FETCH NEXT FROM {cursor}").format(
                            cursor=sql.Identifier(cursor_name)
                        )
                        cur.execute(fetch_sql)
                        row = cur.fetchone()
                        
                        if row is None:
                            # No more rows
                            break
                        
                        rows_processed += 1
                        
                        # Log iteration if sample rate allows
                        if self._should_log_iteration():
                            self.logger.info(f"Processing row {rows_processed}")
                        
                        # Execute action
                        try:
                            # Build action SQL - support both function calls and inline blocks
                            if cursor_action.strip().upper().startswith('DO '):
                                # Full DO block - execute as-is
                                action_sql = sql.SQL(cursor_action)
                            elif '(' in cursor_action and ')' in cursor_action:
                                # Function call with parameters - use as-is
                                action_sql = sql.SQL("PERFORM {action}").format(
                                    action=sql.SQL(cursor_action)
                                )
                            elif cursor_action.strip().upper().startswith(('INSERT ', 'UPDATE ', 'DELETE ', 'SELECT ')):
                                # SQL statement - execute directly
                                action_sql = sql.SQL(cursor_action)
                            else:
                                # Simple function name - call it
                                action_sql = sql.SQL("PERFORM {action}()").format(
                                    action=sql.Identifier(cursor_action)
                                )
                            
                            cur.execute(action_sql)
                            
                        except Exception as e:
                            error_msg = f"Error executing action on row {rows_processed}: {e}"
                            self.logger.error(error_msg)
                            result['errors'].append({
                                'row': rows_processed,
                                'error': str(e)
                            })
                            # Continue processing other rows
                            continue
                    
                    # Close cursor
                    close_sql = sql.SQL("CLOSE {cursor}").format(
                        cursor=sql.Identifier(cursor_name)
                    )
                    cur.execute(close_sql)
                    self.logger.info(f"Cursor '{cursor_name}' closed")
                    
                    # Commit transaction
                    if execution_mode == 'transactional' and not auto_commit:
                        cur.execute("COMMIT")
                        self.logger.info("Transaction committed")
                    
                    result['success'] = True
                    result['rows_processed'] = rows_processed
                    self.logger.info(f"Execution completed: {rows_processed} rows processed")
                    
                except Exception as inner_e:
                    # Rollback on inner errors
                    if execution_mode == 'transactional' and not auto_commit:
                        try:
                            cur.execute("ROLLBACK")
                            self.logger.info("Transaction rolled back due to error")
                        except:
                            pass
                    raise
                    
        except PGError as e:
            self.logger.error(f"PostgreSQL error: {e}")
            result['errors'].append({
                'type': 'postgresql_error',
                'error': str(e)
            })
            # Rollback if transaction is active
            if conn and execution_mode == 'transactional' and not auto_commit:
                try:
                    with conn.cursor() as cur:
                        cur.execute("ROLLBACK")
                        self.logger.info("Transaction rolled back")
                except:
                    pass
        
        except Exception as e:
            self.logger.error(f"Unexpected error: {e}")
            result['errors'].append({
                'type': 'unexpected_error',
                'error': str(e)
            })
            # Attempt rollback
            if conn and execution_mode == 'transactional' and not auto_commit:
                try:
                    with conn.cursor() as cur:
                        cur.execute("ROLLBACK")
                        self.logger.info("Transaction rolled back")
                except:
                    pass
        
        finally:
            if conn:
                conn.close()
                self.logger.debug("Database connection closed")
        
        return result
    
    def execute_with_callback(self, query: str, callback: Callable[[Any], None]) -> Dict[str, Any]:
        """
        Execute cursor operations with custom row processing callback.
        
        Args:
            query: SQL query for cursor
            callback: Function to call for each row (receives row data)
        
        Returns:
            Dictionary with execution results and statistics.
        """
        cursor_name = self._generate_cursor_name()
        execution_mode = self.config.get('execution_mode', 'transactional')
        auto_commit = self.config.get('auto_commit', False)
        
        result = {
            'success': False,
            'cursor_name': cursor_name,
            'rows_processed': 0,
            'errors': []
        }
        
        conn = None
        try:
            conn = psycopg2.connect(self.connection_string)
            conn.autocommit = auto_commit
            
            with conn.cursor() as cur:
                # Begin transaction if not auto-commit
                if execution_mode == 'transactional' and not auto_commit:
                    cur.execute("BEGIN")
                    self.logger.info("Transaction started")
                
                try:
                    # Declare cursor
                    declare_sql = sql.SQL("DECLARE {cursor} CURSOR FOR {query}").format(
                        cursor=sql.Identifier(cursor_name),
                        query=sql.SQL(query)
                    )
                    cur.execute(declare_sql)
                    self.logger.info(f"Cursor '{cursor_name}' declared")
                    
                    # Iterate through cursor
                    rows_processed = 0
                    while True:
                        # Fetch next row
                        fetch_sql = sql.SQL("FETCH NEXT FROM {cursor}").format(
                            cursor=sql.Identifier(cursor_name)
                        )
                        cur.execute(fetch_sql)
                        row = cur.fetchone()
                        
                        if row is None:
                            break
                        
                        rows_processed += 1
                        
                        # Log iteration if sample rate allows
                        if self._should_log_iteration():
                            self.logger.info(f"Processing row {rows_processed}")
                        
                        # Call callback with row data
                        try:
                            callback(row)
                        except Exception as e:
                            error_msg = f"Error in callback for row {rows_processed}: {e}"
                            self.logger.error(error_msg)
                            result['errors'].append({
                                'row': rows_processed,
                                'error': str(e)
                            })
                            continue
                    
                    # Close cursor
                    close_sql = sql.SQL("CLOSE {cursor}").format(
                        cursor=sql.Identifier(cursor_name)
                    )
                    cur.execute(close_sql)
                    self.logger.info(f"Cursor '{cursor_name}' closed")
                    
                    # Commit transaction
                    if execution_mode == 'transactional' and not auto_commit:
                        cur.execute("COMMIT")
                        self.logger.info("Transaction committed")
                    
                    result['success'] = True
                    result['rows_processed'] = rows_processed
                    self.logger.info(f"Execution completed: {rows_processed} rows processed")
                    
                except Exception as inner_e:
                    # Rollback on inner errors
                    if execution_mode == 'transactional' and not auto_commit:
                        try:
                            cur.execute("ROLLBACK")
                            self.logger.info("Transaction rolled back due to error")
                        except:
                            pass
                    raise
                    
        except PGError as e:
            self.logger.error(f"PostgreSQL error: {e}")
            result['errors'].append({
                'type': 'postgresql_error',
                'error': str(e)
            })
            # Rollback if transaction is active
            if conn and execution_mode == 'transactional' and not auto_commit:
                try:
                    with conn.cursor() as cur:
                        cur.execute("ROLLBACK")
                        self.logger.info("Transaction rolled back")
                except:
                    pass
        
        except Exception as e:
            self.logger.error(f"Unexpected error: {e}")
            result['errors'].append({
                'type': 'unexpected_error',
                'error': str(e)
            })
            # Attempt rollback
            if conn and execution_mode == 'transactional' and not auto_commit:
                try:
                    with conn.cursor() as cur:
                        cur.execute("ROLLBACK")
                        self.logger.info("Transaction rolled back")
                except:
                    pass
        
        finally:
            if conn:
                conn.close()
                self.logger.debug("Database connection closed")
        
        return result
    
    def execute_plpgsql_block(self, query: str, action_block: str) -> Dict[str, Any]:
        """
        Execute cursor operations using a PL/pgSQL DO block.
        
        This method executes the entire cursor loop within a PL/pgSQL block,
        allowing the action to access cursor variables using FETCH ... INTO.
        
        Args:
            query: SQL query for cursor
            action_block: PL/pgSQL block that processes each row.
                         The block should use FETCH ... INTO to get row data.
                         Example: "PERFORM process_row(var1, var2);"
        
        Returns:
            Dictionary with execution results and statistics.
        """
        cursor_name = self._generate_cursor_name()
        execution_mode = self.config.get('execution_mode', 'transactional')
        auto_commit = self.config.get('auto_commit', False)
        
        result = {
            'success': False,
            'cursor_name': cursor_name,
            'rows_processed': 0,
            'errors': []
        }
        
        conn = None
        try:
            conn = psycopg2.connect(self.connection_string)
            conn.autocommit = auto_commit
            
            with conn.cursor() as cur:
                # Begin transaction if not auto-commit
                if execution_mode == 'transactional' and not auto_commit:
                    cur.execute("BEGIN")
                    self.logger.info("Transaction started")
                
                try:
                    # Build PL/pgSQL DO block using proper SQL escaping
                    # Note: This method requires the action_block to be valid PL/pgSQL
                    # For full control, users should create their own DO blocks
                    do_block = sql.SQL("""
DO $$
DECLARE
    {cursor} CURSOR FOR {query};
    row_count INTEGER := 0;
BEGIN
    OPEN {cursor};
    
    LOOP
        FETCH NEXT FROM {cursor};
        EXIT WHEN NOT FOUND;
        
        row_count := row_count + 1;
        
        {action}
    END LOOP;
    
    CLOSE {cursor};
END $$;
""").format(
                        cursor=sql.Identifier(cursor_name),
                        query=sql.SQL(query),
                        action=sql.SQL(action_block)
                    )
                    
                    cur.execute(do_block)
                    self.logger.info(f"PL/pgSQL block executed with cursor '{cursor_name}'")
                    
                    # Commit transaction
                    if execution_mode == 'transactional' and not auto_commit:
                        cur.execute("COMMIT")
                        self.logger.info("Transaction committed")
                    
                    result['success'] = True
                    # Note: row_count is not easily retrievable from DO block
                    # This is a limitation of this approach
                    result['rows_processed'] = 0  # Would need to use a function to get this
                    self.logger.info("PL/pgSQL block execution completed")
                    
                except Exception as inner_e:
                    # Rollback on inner errors
                    if execution_mode == 'transactional' and not auto_commit:
                        try:
                            cur.execute("ROLLBACK")
                            self.logger.info("Transaction rolled back due to error")
                        except:
                            pass
                    raise
                    
        except PGError as e:
            self.logger.error(f"PostgreSQL error: {e}")
            result['errors'].append({
                'type': 'postgresql_error',
                'error': str(e)
            })
            # Rollback if transaction is active
            if conn and execution_mode == 'transactional' and not auto_commit:
                try:
                    with conn.cursor() as cur:
                        cur.execute("ROLLBACK")
                        self.logger.info("Transaction rolled back")
                except:
                    pass
        
        except Exception as e:
            self.logger.error(f"Unexpected error: {e}")
            result['errors'].append({
                'type': 'unexpected_error',
                'error': str(e)
            })
            # Attempt rollback
            if conn and execution_mode == 'transactional' and not auto_commit:
                try:
                    with conn.cursor() as cur:
                        cur.execute("ROLLBACK")
                        self.logger.info("Transaction rolled back")
                except:
                    pass
        
        finally:
            if conn:
                conn.close()
                self.logger.debug("Database connection closed")
        
        return result


def load_config(config_path: str) -> Dict[str, Any]:
    """Load configuration from JSON file."""
    with open(config_path, 'r') as f:
        return json.load(f)


def main():
    """CLI entry point."""
    parser = argparse.ArgumentParser(
        description='PostgreSQL Cursor Agent - Execute transactional cursor operations'
    )
    parser.add_argument(
        '--config',
        type=str,
        help='Path to JSON configuration file'
    )
    parser.add_argument(
        '--connection',
        type=str,
        help='Connection string override (e.g., "dbname=test user=postgres")'
    )
    parser.add_argument(
        '--query',
        type=str,
        help='Cursor query SQL'
    )
    parser.add_argument(
        '--action',
        type=str,
        help='Action function name or SQL block to execute'
    )
    parser.add_argument(
        '--cursor-name',
        type=str,
        help='Custom cursor name'
    )
    parser.add_argument(
        '--log-level',
        type=str,
        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'],
        default='INFO',
        help='Logging level'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Validate configuration without executing'
    )
    parser.add_argument(
        '--output-json',
        action='store_true',
        help='Output results as JSON'
    )
    
    args = parser.parse_args()
    
    # Load config
    config = {}
    if args.config:
        config = load_config(args.config)
    
    # Override with CLI arguments
    if args.connection:
        config['connection_string'] = args.connection
    
    if args.query:
        if 'cursor' not in config:
            config['cursor'] = {}
        config['cursor']['query'] = args.query
    
    if args.action:
        if 'cursor' not in config:
            config['cursor'] = {}
        config['cursor']['action'] = args.action
    
    if args.cursor_name:
        if 'cursor' not in config:
            config['cursor'] = {}
        config['cursor']['name'] = args.cursor_name
    
    if args.log_level:
        if 'logging' not in config:
            config['logging'] = {}
        config['logging']['level'] = args.log_level.lower()
    
    # Set defaults
    if 'logging' not in config:
        config['logging'] = {'level': 'info', 'target': 'stdout'}
    if 'execution_mode' not in config:
        config['execution_mode'] = 'transactional'
    if 'auto_commit' not in config:
        config['auto_commit'] = False
    
    # Dry run - just validate
    if args.dry_run:
        try:
            agent = CursorAgent(config)
            print("✓ Configuration valid")
            if args.output_json:
                print(json.dumps({'valid': True}, indent=2))
            sys.exit(0)
        except Exception as e:
            print(f"✗ Configuration error: {e}")
            if args.output_json:
                print(json.dumps({'valid': False, 'error': str(e)}, indent=2))
            sys.exit(1)
    
    # Execute
    try:
        agent = CursorAgent(config)
        result = agent.execute()
        
        if args.output_json:
            print(json.dumps(result, indent=2))
        else:
            if result['success']:
                print(f"✓ Success: {result['rows_processed']} rows processed")
                if result['errors']:
                    print(f"⚠ {len(result['errors'])} errors occurred")
            else:
                print(f"✗ Execution failed")
                for error in result['errors']:
                    print(f"  Error: {error}")
        
        sys.exit(0 if result['success'] else 1)
        
    except Exception as e:
        error_result = {'success': False, 'error': str(e)}
        if args.output_json:
            print(json.dumps(error_result, indent=2))
        else:
            print(f"✗ Error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()

