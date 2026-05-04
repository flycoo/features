#!/usr/bin/env bash
set -euo pipefail

APP=opencode
VERSION="${VERSION:-latest}"

# ---------------------------------------------------------------------------
# Package installation – supports apt / apk / dnf / yum
# ---------------------------------------------------------------------------
install_deps() {
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            ca-certificates curl tar
        apt-get clean
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache ca-certificates curl tar
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y ca-certificates curl tar
        dnf clean all
    elif command -v yum >/dev/null 2>&1; then
        yum install -y ca-certificates curl tar
        yum clean all
    else
        echo "ERROR: No supported package manager found (apt/apk/dnf/yum)" >&2
        exit 1
    fi
}

install_deps

# ---------------------------------------------------------------------------
# Architecture + target detection
# ---------------------------------------------------------------------------
arch=$(uname -m)
case "$arch" in
    aarch64) arch="arm64" ;;
    x86_64)  arch="x64"   ;;
    *) echo "ERROR: Unsupported architecture: $arch" >&2; exit 1 ;;
esac

is_musl=false
if [ -f /etc/alpine-release ]; then
    is_musl=true
elif command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl; then
    is_musl=true
fi

needs_baseline=false
if [ "$arch" = "x64" ] && ! grep -qwi avx2 /proc/cpuinfo 2>/dev/null; then
    needs_baseline=true
fi

target="linux-$arch"
[ "$needs_baseline" = "true" ] && target="${target}-baseline"
[ "$is_musl"        = "true" ] && target="${target}-musl"

# ---------------------------------------------------------------------------
# Resolve download URL
# ---------------------------------------------------------------------------
if [ "$VERSION" = "latest" ]; then
    download_url="https://github.com/anomalyco/opencode/releases/latest/download/${APP}-${target}.tar.gz"
else
    VERSION="${VERSION#v}"
    download_url="https://github.com/anomalyco/opencode/releases/download/v${VERSION}/${APP}-${target}.tar.gz"

    http_status=$(curl -sIL -o /dev/null -w "%{http_code}" "$download_url")
    if [ "$http_status" != "200" ]; then
        echo "ERROR: OpenCode asset not found for v${VERSION} / ${target} (HTTP ${http_status})" >&2
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# Download & install
# ---------------------------------------------------------------------------
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

echo "Downloading OpenCode (${VERSION}) for ${target}..."
curl -fsSL -o "$tmp_dir/opencode.tar.gz" "$download_url"

tar -xzf "$tmp_dir/opencode.tar.gz" -C "$tmp_dir"
mv "$tmp_dir/opencode" /usr/local/bin/opencode
chmod 755 /usr/local/bin/opencode

echo "OpenCode installed successfully:"
opencode --version

# ---------------------------------------------------------------------------
# Ensure XDG / persistent data directories exist
# Uses containerEnv vars if already injected, otherwise falls back to defaults
# that match the named volume mount target in devcontainer-feature.json
# ---------------------------------------------------------------------------
OP_BASE="/usr/local/share/opencode-data"
mkdir -p \
    "${XDG_DATA_HOME:-$OP_BASE/data}" \
    "${XDG_CONFIG_HOME:-$OP_BASE/config}" \
    "${XDG_CACHE_HOME:-$OP_BASE/cache}" \
    "${XDG_STATE_HOME:-$OP_BASE/state}"


