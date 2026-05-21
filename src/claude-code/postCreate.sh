#!/usr/bin/env bash
# Runs after container creation as the actual container user ($HOME is correct here).
set -euo pipefail

# Load CLAUDE_BASE written during image build
ENV_FILE="/usr/local/share/claude-code-feature/env"
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE not found – was the claude-code feature installed?" >&2
    exit 1
fi
# shellcheck source=/dev/null
. "$ENV_FILE"

# ---------------------------------------------------------------------------
# Symlink ~/.claude → persistent CLAUDE_BASE
# ---------------------------------------------------------------------------
rm -rf "$HOME/.claude"
ln -sfn "${CLAUDE_BASE}/config" "$HOME/.claude"

# ---------------------------------------------------------------------------
# Persist ~/.agents/skills → /data/qiu/.agents/skills (survives rebuilds)
# ---------------------------------------------------------------------------
AGENTS_SRC="$HOME/.agents/skills"
AGENTS_DST="/data/qiu/.agents/skills"

if [ -d "/data/qiu" ]; then
    mkdir -p "$AGENTS_DST"
    mkdir -p "$HOME/.agents"

    # Migrate existing real directory into persistent location first
    if [ -d "$AGENTS_SRC" ] && [ ! -L "$AGENTS_SRC" ]; then
        cp -rn "$AGENTS_SRC"/* "$AGENTS_DST"/ 2>/dev/null || true
        rm -rf "$AGENTS_SRC"
    fi

    # Remove any stale non-directory, non-symlink entry
    if [ -e "$AGENTS_SRC" ] && [ ! -d "$AGENTS_SRC" ] && [ ! -L "$AGENTS_SRC" ]; then
        rm -f "$AGENTS_SRC"
    fi

    if [ ! -e "$AGENTS_SRC" ]; then
        ln -sfn "$AGENTS_DST" "$AGENTS_SRC"
    fi
fi
