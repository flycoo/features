"""
MCP DB Module - MySQL 8.0+ Database Operations for Model Context Protocol

Features:
- Real MySQL database operations (not simulations)
- Multiple database configuration support
- Comprehensive SQL operations (SELECT, INSERT, UPDATE, DELETE, CREATE, DROP)
- Schema inspection and table management
- Secure local configuration file
- Time zone utility functions
"""

__version__ = "0.2.0"
__author__ = "MCP Services"
__description__ = "MySQL 8.0+ Database Operations for Model Context Protocol"

# Import main functions for easier access
from .db import (
    load_db_config,
    get_db_connection,
    query_db,
    list_tables,
    describe_table,
    create_table,
    insert_data,
    debug_config,
    main
)

__all__ = [
    'load_db_config',
    'get_db_connection', 
    'query_db',
    'list_tables',
    'describe_table',
    'create_table',
    'insert_data',
    'debug_config',
    'main',
    '__version__',
    '__author__',
    '__description__'
]
