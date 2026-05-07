#!/usr/bin/env bash
set -euo pipefail

DB_CONFIG="${DB_CONFIG:-}"

# ---------------------------------------------------------------------------
# Package installation – supports apt / apk / dnf / yum
# ---------------------------------------------------------------------------
install_deps() {
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            ca-certificates python3 python3-pip
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache ca-certificates python3 py3-pip
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y ca-certificates python3 python3-pip
        dnf clean all
    elif command -v yum >/dev/null 2>&1; then
        yum install -y ca-certificates python3 python3-pip
        yum clean all
    else
        echo "ERROR: No supported package manager found (apt/apk/dnf/yum)" >&2
        exit 1
    fi
}

install_deps

# ---------------------------------------------------------------------------
# Install Python dependencies
# ---------------------------------------------------------------------------
pip3 install --no-cache-dir mysql-connector-python "mcp[cli]"

# ---------------------------------------------------------------------------
# Copy mcp_db module to system location
# ---------------------------------------------------------------------------
MODULE_SRC="$(dirname "$0")/mcp_db"
MODULE_DST="/usr/local/share/mcp-db"

mkdir -p "$MODULE_DST"
cp -r "$MODULE_SRC"/* "$MODULE_DST/"

# Remove any stray config file that may have been included; config is user-provided
rm -f "$MODULE_DST/db_config.json"

echo "MCP DB Server installed to $MODULE_DST"

# ---------------------------------------------------------------------------
# Save options for postCreate phase (runs as real container user)
# ---------------------------------------------------------------------------
FEATURE_DIR="/usr/local/share/mcp-db-feature"
mkdir -p "$FEATURE_DIR"
echo "DB_CONFIG=${DB_CONFIG}" > "$FEATURE_DIR/env"
echo "MODULE_DST=${MODULE_DST}" >> "$FEATURE_DIR/env"

cp "$(dirname "$0")/postCreate.sh" "$FEATURE_DIR/postCreate.sh"
chmod 755 "$FEATURE_DIR/postCreate.sh"
