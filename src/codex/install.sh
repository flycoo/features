#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-latest}"
CODEX_BASE="${CODEX_BASE:-/data/qiu/.codex}"
DEFAULT_PROXY="${ENV_PROXYIP:-${PROXYIP:-http://ld_squid_dind:3128}}"

export HTTP_PROXY="${HTTP_PROXY:-$DEFAULT_PROXY}"
export HTTPS_PROXY="${HTTPS_PROXY:-$DEFAULT_PROXY}"
export http_proxy="${http_proxy:-$DEFAULT_PROXY}"
export https_proxy="${https_proxy:-$DEFAULT_PROXY}"

install_deps() {
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            ca-certificates
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache ca-certificates
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y ca-certificates
        dnf clean all
    elif command -v yum >/dev/null 2>&1; then
        yum install -y ca-certificates
        yum clean all
    else
        echo "ERROR: No supported package manager found (apt/apk/dnf/yum)" >&2
        exit 1
    fi
}

install_deps

if ! command -v node >/dev/null 2>&1; then
    echo "ERROR: Node.js is required but not found." >&2
    echo "       Add ghcr.io/devcontainers/features/node to your devcontainer features." >&2
    exit 1
fi

echo "Node.js $(node --version) detected"

if [ "$VERSION" = "latest" ]; then
    npm_pkg="@openai/codex"
else
    npm_pkg="@openai/codex@${VERSION}"
fi

echo "Installing Codex (${VERSION})..."
npm install -g "${npm_pkg}"

echo "Codex installed successfully:"
codex --version 2>/dev/null || echo "ok"

mkdir -p "${CODEX_BASE}"

mkdir -p /usr/local/share/codex-feature
printf "CODEX_BASE=%s\n" "${CODEX_BASE}" > /usr/local/share/codex-feature/env

cp "$(dirname "$0")/postCreate.sh" /usr/local/share/codex-feature/postCreate.sh
chmod 755 /usr/local/share/codex-feature/postCreate.sh
