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
DEFAULT_PROXY="${DEFAULT_PROXY:-http://ld_squid_dind:3128}"
DEFAULT_NO_PROXY="${DEFAULT_NO_PROXY:-localhost,127.0.0.1,open.weixin.qq.com,api.mch.weixin.qq.com,api.weixin.qq.com,cn.ubuntu.com,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,scqy.ccbsc.com,open.feishu.cn}"

mkdir -p "$CODEX_DST"

if [ -d "$CODEX_SRC" ] && [ ! -L "$CODEX_SRC" ]; then
    cp -rn "$CODEX_SRC"/* "$CODEX_DST"/ 2>/dev/null || true
    rm -rf "$CODEX_SRC"
fi

if [ -e "$CODEX_SRC" ] && [ ! -d "$CODEX_SRC" ] && [ ! -L "$CODEX_SRC" ]; then
    rm -f "$CODEX_SRC"
fi

ln -sfn "$CODEX_DST" "$CODEX_SRC"

append_once() {
    local file="$1"
    local marker="$2"
    local content="$3"

    touch "$file"
    if ! grep -Fq "$marker" "$file"; then
        {
            printf '\n%s\n' "$marker"
            printf '%s\n' "$content"
        } >>"$file"
    fi
}

proxy_shell_exports="$(cat <<EOF
export HTTP_PROXY="\${HTTP_PROXY:-$DEFAULT_PROXY}"
export HTTPS_PROXY="\${HTTPS_PROXY:-$DEFAULT_PROXY}"
export http_proxy="\${http_proxy:-$DEFAULT_PROXY}"
export https_proxy="\${https_proxy:-$DEFAULT_PROXY}"
export NO_PROXY="\${NO_PROXY:-$DEFAULT_NO_PROXY}"
export no_proxy="\${no_proxy:-$DEFAULT_NO_PROXY}"
EOF
)"

append_once "$HOME/.bashrc" "# Codex proxy environment" "$proxy_shell_exports"
append_once "$HOME/.profile" "# Codex proxy environment" "$proxy_shell_exports"

CONFIG_FILE="$CODEX_DST/config.toml"
touch "$CONFIG_FILE"
if ! grep -Fq "[shell_environment_policy.set]" "$CONFIG_FILE"; then
    cat >>"$CONFIG_FILE" <<EOF

[shell_environment_policy]

[shell_environment_policy.set]
HTTP_PROXY = "$DEFAULT_PROXY"
HTTPS_PROXY = "$DEFAULT_PROXY"
http_proxy = "$DEFAULT_PROXY"
https_proxy = "$DEFAULT_PROXY"
NO_PROXY = "$DEFAULT_NO_PROXY"
no_proxy = "$DEFAULT_NO_PROXY"
EOF
fi
