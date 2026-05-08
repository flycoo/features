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

# ---------------------------------------------------------------------------
# Register mcp-db in .vscode/mcp.json (workspace root)
# ---------------------------------------------------------------------------
WORKSPACE_DIR="$(pwd)"
VSCODE_DIR="$WORKSPACE_DIR/.vscode"
MCP_JSON="$VSCODE_DIR/mcp.json"

mkdir -p "$VSCODE_DIR"

python3 - "$MCP_JSON" << 'PYEOF'
import sys, json, os

path = sys.argv[1]
entry = {"command": "mcp-db"}

if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)
else:
    data = {"servers": {}}

data.setdefault("servers", {})["mcp-db"] = entry

with open(path, "w") as f:
    json.dump(data, f, indent=4)
    f.write("\n")

print(f"mcp-db: registered in {path}")
PYEOF

# ---------------------------------------------------------------------------
# Ensure ~/.local/bin/mcp-db symlink (tools may hardcode this path)
# ---------------------------------------------------------------------------
SRC="/usr/local/bin/mcp-db"
LOCAL_BIN="$HOME/.local/bin"
DST="$LOCAL_BIN/mcp-db"

if [ ! -f "$SRC" ]; then
    echo "WARNING: $SRC not found – skipping ~/.local/bin symlink" >&2
else
    mkdir -p "$LOCAL_BIN"

    # If target already exists and is the correct symlink, nothing to do
    if [ -e "$DST" ] || [ -L "$DST" ]; then
        if [ -L "$DST" ] && [ "$(readlink "$DST")" = "$SRC" ]; then
            echo "mcp-db: ~/.local/bin symlink already correct"
        else
            echo "ERROR: $DST already exists but is not a symlink to $SRC." >&2
            echo "       Remove it manually and re-run postCreate." >&2
            exit 1
        fi
    else
        ln -sf "$SRC" "$DST"
        echo "mcp-db: symlink created $DST -> $SRC"
    fi
fi
