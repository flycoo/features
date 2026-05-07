#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="/usr/local/share/mcp-db-feature/env"
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE not found – was the mcp-db feature installed?" >&2
    exit 1
fi
# shellcheck source=/dev/null
. "$ENV_FILE"

DST="${MODULE_DST}/db_config.json"

# ---------------------------------------------------------------------------
# Handle db_config.json
# ---------------------------------------------------------------------------
if [ -n "${DB_CONFIG:-}" ]; then
    if [ -f "$DB_CONFIG" ]; then
        cp "$DB_CONFIG" "$DST"
        chmod 600 "$DST"
        echo "mcp-db: db_config.json copied from $DB_CONFIG"
    else
        echo "WARNING: db-config path '$DB_CONFIG' does not exist. Creating template db_config.json." >&2
        cat > "$DST" << 'EOL'
{
  "default": {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "password",
    "database": "test_db",
    "charset": "utf8mb4",
    "autocommit": true,
    "use_unicode": true
  }
}
EOL
        chmod 600 "$DST"
    fi
else
    echo "WARNING: 'db-config' option is not set. Creating template db_config.json." >&2
    echo "Set it in devcontainer.json, e.g.:" >&2
    echo '  "features": { "ghcr.io/flycoo/features/mcp-db": { "db-config": "/workspaces/myproject/db_config.json" } }' >&2
    cat > "$DST" << 'EOL'
{
  "default": {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "password",
    "database": "test_db",
    "charset": "utf8mb4",
    "autocommit": true,
    "use_unicode": true
  }
}
EOL
    chmod 600 "$DST"
fi
