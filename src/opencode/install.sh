#!/usr/bin/env bash
set -euo pipefail

APP=opencode
VERSION="${VERSION:-latest}"

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar

arch=$(uname -m)
case "$arch" in
    aarch64) arch="arm64" ;;
    x86_64)  arch="x64" ;;
esac

is_musl=false
if [ -f /etc/alpine-release ]; then
    is_musl=true
fi
if command -v ldd >/dev/null 2>&1; then
    if ldd --version 2>&1 | grep -qi musl; then
        is_musl=true
    fi
fi

needs_baseline=false
if [ "$arch" = "x64" ]; then
    if ! grep -qwi avx2 /proc/cpuinfo 2>/dev/null; then
        needs_baseline=true
    fi
fi

target="linux-$arch"
if [ "$needs_baseline" = "true" ]; then
    target="${target}-baseline"
fi
if [ "$is_musl" = "true" ]; then
    target="${target}-musl"
fi

if [ "$VERSION" = "latest" ]; then
    download_url="https://github.com/anomalyco/opencode/releases/latest/download/${APP}-${target}.tar.gz"
else
    VERSION="${VERSION#v}"
    download_url="https://github.com/anomalyco/opencode/releases/download/v${VERSION}/${APP}-${target}.tar.gz"

    http_status=$(curl -sI -o /dev/null -w "%{http_code}" "https://github.com/anomalyco/opencode/releases/tag/v${VERSION}")
    if [ "$http_status" = "404" ]; then
        echo "Error: OpenCode release v${VERSION} not found"
        exit 1
    fi
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

echo "Downloading OpenCode (${VERSION}) for ${target}..."
curl -fsSL -o "$tmp_dir/opencode.tar.gz" "$download_url"

tar -xzf "$tmp_dir/opencode.tar.gz" -C "$tmp_dir"
mv "$tmp_dir/opencode" /usr/local/bin/opencode
chmod 755 /usr/local/bin/opencode

echo "OpenCode installed successfully:"
opencode --version

# Set up persistent data directories on the named volume
OP_BASE="/usr/local/share/opencode-data"
mkdir -p "$OP_BASE/data" "$OP_BASE/config" "$OP_BASE/cache" "$OP_BASE/state"

# Ensure PATH includes /usr/local/bin in common shell configs
INSTALL_BIN="/usr/local/bin"
for rc in /etc/bash.bashrc /etc/zsh/zshrc /etc/skel/.bashrc /etc/profile.d/opencode.sh; do
    dir=$(dirname "$rc")
    [ -d "$dir" ] || continue
    if [ -f "$rc" ] && grep -q "$INSTALL_BIN" "$rc" 2>/dev/null; then
        continue
    fi
    echo 'export PATH="/usr/local/bin:$PATH"' >> "$rc" 2>/dev/null || true
done
