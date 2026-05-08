#!/usr/bin/env bash
# Runs after container creation as the actual container user ($HOME is correct here).
set -euo pipefail

# Load OPENCODE_BASE written during image build
ENV_FILE="/usr/local/share/opencode-feature/env"
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE not found – was the opencode feature installed?" >&2
    exit 1
fi
# shellcheck source=/dev/null
. "$ENV_FILE"

# ---------------------------------------------------------------------------
# XDG symlinks → persistent OPENCODE_BASE dirs
# opencode uses $XDG_*_HOME/opencode; redirect to OPENCODE_BASE
# ---------------------------------------------------------------------------
mkdir -p "$HOME/.config" "$HOME/.local/share" "$HOME/.cache" "$HOME/.local/state"
rm -rf "$HOME/.config/opencode"
ln -sfn "${OPENCODE_BASE}/config" "$HOME/.config/opencode"
rm -rf "$HOME/.local/share/opencode"
ln -sfn "${OPENCODE_BASE}/share"  "$HOME/.local/share/opencode"
rm -rf "$HOME/.cache/opencode"
ln -sfn "${OPENCODE_BASE}/cache"  "$HOME/.cache/opencode"
rm -rf "$HOME/.local/state/opencode"
ln -sfn "${OPENCODE_BASE}/state"  "$HOME/.local/state/opencode"

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
