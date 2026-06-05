#!/usr/bin/env bash
set -euo pipefail

APP=claude
VERSION="${VERSION:-latest}"

# ---------------------------------------------------------------------------
# Package installation – supports apt / apk / dnf / yum
# ---------------------------------------------------------------------------
install_deps() {
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            ca-certificates curl
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache ca-certificates curl
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y ca-certificates curl
        dnf clean all
    elif command -v yum >/dev/null 2>&1; then
        yum install -y ca-certificates curl
        yum clean all
    else
        echo "ERROR: No supported package manager found (apt/apk/dnf/yum)" >&2
        exit 1
    fi
}

install_deps

# ---------------------------------------------------------------------------
# Ensure Node.js is available
# ---------------------------------------------------------------------------
if ! command -v node >/dev/null 2>&1; then
    echo "ERROR: Node.js is required but not found." >&2
    echo "       Add 'ghcr.io/devcontainers/features/node' to your devcontainer features." >&2
    exit 1
fi

echo "Node.js $(node --version) detected"

# ---------------------------------------------------------------------------
# Install Claude Code via npm
# ---------------------------------------------------------------------------
if [ "$VERSION" = "latest" ]; then
    npm_pkg="@anthropic-ai/claude-code"
else
    npm_pkg="@anthropic-ai/claude-code@${VERSION}"
fi

# Ensure nvm group exists and qiu is in it, so g+w permission works for user updates
groupadd -f nvm 2>/dev/null || true
usermod -aG nvm qiu 2>/dev/null || true
chgrp -R nvm "$(npm config get prefix)/lib/node_modules" 2>/dev/null || true
chmod g+s "$(npm config get prefix)/lib/node_modules" 2>/dev/null || true

echo "Installing Claude Code (${VERSION})..."
umask 0002
npm install -g "${npm_pkg}"
chmod -Rf g+w "$(npm config get prefix)/lib/node_modules" 2>/dev/null || true

echo "Claude Code installed successfully:"
claude --version 2>/dev/null || claude --help 2>&1 | head -1 || echo "ok"

# ---------------------------------------------------------------------------
# Ensure persistent data directories exist
# ---------------------------------------------------------------------------
CLAUDE_BASE="${CLAUDE_BASE:-}"
if [ -z "$CLAUDE_BASE" ]; then
    echo "ERROR: 'claude-base' option is required for data persistence." >&2
    echo "       Set it in devcontainer.json, e.g.:" >&2
    echo '       "features": { "ghcr.io/flycoo/features/claude-code": { "claude-base": "/usr/local/share/claude-code-data" } }' >&2
    exit 1
fi
mkdir -p "${CLAUDE_BASE}"

# Save CLAUDE_BASE for the postCreate phase (runs as real container user)
mkdir -p /usr/local/share/claude-code-feature
echo "CLAUDE_BASE=${CLAUDE_BASE}" > /usr/local/share/claude-code-feature/env

# Copy postCreate script to a fixed system path
cp "$(dirname "$0")/postCreate.sh" /usr/local/share/claude-code-feature/postCreate.sh
chmod 755 /usr/local/share/claude-code-feature/postCreate.sh
