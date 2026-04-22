#!/usr/bin/env bash
set -euo pipefail

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  dnsutils \
  git \
  iproute2 \
  iputils-ping \
  net-tools \
  php-cli \
  php-curl \
  php-mbstring \
  php-xml \
  php-zip \
  traceroute \
  unzip \
  wget \
  zip

if ! command -v composer >/dev/null 2>&1; then
  curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php
  php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
  rm -f /tmp/composer-setup.php
fi

INSTALL_WEBMAN="${INSTALLWEBMAN:-true}"
WEBMAN_PATH="${WEBMANPATH:-/opt/webman}"

if [ "${INSTALL_WEBMAN}" = "true" ]; then
  mkdir -p "${WEBMAN_PATH}"
  if [ ! -f "${WEBMAN_PATH}/composer.json" ]; then
    composer create-project workerman/webman "${WEBMAN_PATH}" --no-interaction --no-progress
  fi
fi

cat >/usr/local/bin/webman-tools-check <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf 'php: '
php -v | head -n 1
printf 'composer: '
composer --version
printf 'curl: '
curl --version | head -n 1
printf 'wget: '
wget --version | head -n 1
printf 'ping: '
ping -V 2>/dev/null | head -n 1 || true
printf 'traceroute: '
traceroute --version 2>/dev/null | head -n 1 || true
printf 'dig: '
dig -v 2>/dev/null | head -n 1 || true
EOF
chmod +x /usr/local/bin/webman-tools-check
