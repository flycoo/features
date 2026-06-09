#!/usr/bin/env python3
"""
MCP DB Server - A Model Context Protocol server for MySQL 8.0+ database operations

Version: 0.2.0
Author: MCP Services
Description: Provides real MySQL database operations through MCP tools
"""

import mysql.connector
import json
import os
from pathlib import Path
from typing import Dict, Any, Optional
from mcp.server.fastmcp import FastMCP

# Version information
__version__ = "0.2.0"
__author__ = "MCP Services"

# Create FastMCP server instance
server = FastMCP(
    name="DatabaseServer", 
    stateless_http=True, 
    log_level="DEBUG",
    # description=f"MySQL Database Server v{__version__}"
)

# Database configuration file path – can be overridden via MCP_DB_CONFIG env var
CONFIG_FILE = Path(os.getenv("MCP_DB_CONFIG", Path(__file__).parent / "db_config.json"))

def load_db_config() -> Dict[str, Any]:
    """Load database configuration from local file and environment variables."""
    if not CONFIG_FILE.exists():
        # Create default config file if it doesn't exist
        default_config = {
            "default": {
                "host": "localhost",
                "port": 3306,
                "user": "root",
                "password": "password",
                "database": "test_db",
                "charset": "utf8mb4",
                "autocommit": True,
                "use_unicode": True
            }
        }
        with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
            json.dump(default_config, f, indent=2, ensure_ascii=False)
        return default_config
    
    with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
        config = json.load(f)
    
    # Override with environment variables if they exist – iterate all config keys
    for env_name in list(config.keys()):
        env_prefix = f"DB_{env_name.upper()}_"

        # Check if any environment variables exist for this environment
        env_vars = {}
        for key in ['host', 'port', 'user', 'password', 'database', 'charset']:
            env_key = f"{env_prefix}{key.upper()}"
            env_value = os.getenv(env_key)
            if env_value:
                if key == 'port':
                    env_vars[key] = int(env_value)
                elif key in ['autocommit', 'use_unicode']:
                    env_vars[key] = env_value.lower() in ['true', '1', 'yes']
                else:
                    env_vars[key] = env_value

        # Override configuration with environment variables
        if env_vars:
            config[env_name].update(env_vars)
    
    return config

def get_db_connection(env_name: Optional[str] = None):
    """Get MySQL database connection."""
    config = load_db_config()
    
    # If no env_name parameter is provided, use DB_CONNECTION or fall back to "default"
    if env_name is None:
        db_connection = os.getenv("DB_CONNECTION")
        if db_connection and db_connection in config:
            env_name = db_connection
        else:
            env_name = "default"
    
    if env_name not in config:
        raise ValueError(f"Database configuration '{env_name}' not found in config file")
    
    db_config = config[env_name]
    conn = mysql.connector.connect(**db_config)
    return conn, env_name

@server.tool(description="Execute a database query")
def query_db(query: str, env_name: Optional[str] = None) -> str:
    """Execute a database query."""
    try:
        conn, actual_database = get_db_connection(env_name=env_name)
        cursor = conn.cursor()
        
        # Execute the query
        cursor.execute(query)
        
        # Check if it's a SELECT query
        if query.strip().upper().startswith('SELECT'):
            rows = cursor.fetchall()
            if rows:
                # Get column names
                columns = [desc[0] for desc in cursor.description]
                result = f"Query executed successfully on database '{actual_database}':\n\n"
                result += " | ".join(columns) + "\n"
                result += "-" * (len(" | ".join(columns))) + "\n"
                
                for row in rows:
                    result += " | ".join(str(cell) if cell is not None else "NULL" for cell in row) + "\n"
                
                result += f"\nRows returned: {len(rows)}"
            else:
                result = f"Query executed successfully on database '{actual_database}': No rows returned"
        else:
            # For INSERT, UPDATE, DELETE, etc.
            conn.commit()
            result = f"Query executed successfully on database '{actual_database}'\n"
            result += f"Rows affected: {cursor.rowcount}"
        
        cursor.close()
        conn.close()
        return result
        
    except mysql.connector.Error as e:
        return f"MySQL error: {str(e)}"
    except Exception as e:
        return f"Error: {str(e)}"

@server.tool(description="List all tables in the database")
def list_tables(env_name: Optional[str] = None, pattern: Optional[str] = None) -> str:
    """List all tables in the database with optional pattern matching."""
    try:
        conn, actual_database = get_db_connection(env_name=env_name)
        cursor = conn.cursor()
        
        if pattern:
            # Use LIKE pattern for fuzzy search (supports % and _ wildcards)
            cursor.execute("SHOW TABLES LIKE %s", (pattern,))
        else:
            cursor.execute("SHOW TABLES")
        
        tables = cursor.fetchall()
        
        result = f"Tables in database '{actual_database}'"
        if pattern:
            result += f" matching pattern '{pattern}'"
        result += ":\n"
        
        if tables:
            for i, (table_name,) in enumerate(tables, 1):
                result += f"{i}. {table_name}\n"
        else:
            if pattern:
                result += f"No tables found matching pattern '{pattern}'.\n"
            else:
                result += "No tables found.\n"
        
        cursor.close()
        conn.close()
        return result
        
    except mysql.connector.Error as e:
        return f"MySQL error: {str(e)}"
    except Exception as e:
        return f"Error: {str(e)}"

@server.tool(description="Get table schema information")
def describe_table(table_name: str, env_name: Optional[str] = None) -> str:
    """Get table schema information."""
    try:
        conn, actual_database = get_db_connection(env_name=env_name)
        cursor = conn.cursor()
        
        # Get table schema using SHOW CREATE TABLE
        cursor.execute(f"SHOW CREATE TABLE {table_name}")
        result_tuple = cursor.fetchone()
        
        if not result_tuple:
            cursor.close()
            conn.close()
            return f"Table '{table_name}' not found in database '{actual_database}'"
        
        # The result_tuple is (table_name, create_table_statement)
        create_table_statement = result_tuple[1]
        
        result = f"Schema for table '{table_name}' in database '{actual_database}':\\n\\n"
        result += create_table_statement
        
        cursor.close()
        conn.close()
        return result
        
    except mysql.connector.Error as e:
        return f"MySQL error: {str(e)}"
    except Exception as e:
        return f"Error: {str(e)}"

@server.tool(description="Create a new table")
def create_table(table_name: str, table_schema: str, env_name: Optional[str] = None) -> str:
    """Create a new table.表名必须以mcp_打头"""
    if not table_name.startswith("mcp_"):
        return "Error: 表名必须以'mcp_'打头"

    try:
        conn, actual_database = get_db_connection(env_name=env_name)
        cursor = conn.cursor()
        
        # Create the table with the provided schema
        create_sql = f"CREATE TABLE {table_name} ({table_schema})"
        cursor.execute(create_sql)
        conn.commit()
        
        result = f"Table '{table_name}' created successfully in database '{actual_database}'\n"
        result += f"Schema: {table_schema}"
        
        cursor.close()
        conn.close()
        return result
        
    except mysql.connector.Error as e:
        return f"MySQL error: {str(e)}"
    except Exception as e:
        return f"Error: {str(e)}"

@server.tool(description="Insert data into a table")
def insert_data(table_name: str, data: str, env_name: Optional[str] = None) -> str:
    """Insert data into a table."""
    try:
        conn, actual_database = get_db_connection(env_name=env_name)
        cursor = conn.cursor()
        
        # Execute the insert statement
        insert_sql = f"INSERT INTO {table_name} {data}"
        cursor.execute(insert_sql)
        conn.commit()
        
        result = f"Data inserted successfully into table '{table_name}' in database '{actual_database}'\n"
        result += f"Rows affected: {cursor.rowcount}"
        
        cursor.close()
        conn.close()
        return result
        
    except mysql.connector.Error as e:
        return f"MySQL error: {str(e)}"
    except Exception as e:
        return f"Error: {str(e)}"

@server.tool(description="Check environment variables and database configuration")
def debug_config() -> str:
    """Check environment variables and database configuration."""
    db_connection = os.getenv("DB_CONNECTION")
    config = load_db_config()
    
    result = f"Environment Variables:\n"
    result += f"DB_CONNECTION: {db_connection}\n\n"
    
    result += f"Available configurations in db_config.json:\n"
    for key, config_data in config.items():
        database_name = config_data.get('database', 'N/A')
        result += f"- env={key}, database={database_name}\n"
    
    return result

@server.tool(description="Show all available databases")
def show_databases(env_name: Optional[str] = None) -> str:
    """显示所有可用的数据库列表."""
    try:
        conn, actual_env = get_db_connection(env_name=env_name)
        cursor = conn.cursor()
        
        # 执行查询所有数据库的SQL
        cursor.execute("SHOW DATABASES")
        databases = cursor.fetchall()
        
        result = f"Available databases (using env configuration '{actual_env}'):\n"
        
        if databases:
            for i, (db_name,) in enumerate(databases, 1):
                result += f"{i}. {db_name}\n"
        else:
            result += "No databases found.\n"
        
        cursor.close()
        conn.close()
        return result
        
    except mysql.connector.Error as e:
        return f"MySQL error: {str(e)}"
    except Exception as e:
        return f"Error: {str(e)}"

def main():
    """Main entry point for the database server."""
    server.run()


if __name__ == "__main__":
    main()
