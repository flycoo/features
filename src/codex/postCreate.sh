#!/usr/bin/env bash
# Runs after container creation as the actual container user ($HOME is correct here).
set -euo pipefail

ENV_FILE="/usr/local/share/codex-feature/env"
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: $ENV_FILE not found - was the codex feature installed?" >&2
    exit 1
fi
# shellcheck source=/dev/null
. "$ENV_FILE"

CODEX_SRC="$HOME/.codex"
CODEX_DST="${CODEX_BASE:-/data/qiu/.codex}"

mkdir -p "$CODEX_DST"

if [ -d "$CODEX_SRC" ] && [ ! -L "$CODEX_SRC" ]; then
    cp -rn "$CODEX_SRC"/* "$CODEX_DST"/ 2>/dev/null || true
    rm -rf "$CODEX_SRC"
fi

if [ -e "$CODEX_SRC" ] && [ ! -d "$CODEX_SRC" ] && [ ! -L "$CODEX_SRC" ]; then
    rm -f "$CODEX_SRC"
fi

ln -sfn "$CODEX_DST" "$CODEX_SRC"
