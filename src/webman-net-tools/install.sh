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

mkdir -p /opt/webman
if [ ! -f /opt/webman/composer.json ]; then
  composer create-project workerman/webman /opt/webman --no-interaction --no-progress
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
