#!/usr/bin/env bash

[[ $DEBUG == true ]] && set -x
set -euo pipefail

echo "daemon off;" >> /etc/nginx/nginx.conf

mkdir -p /run/php
ln -sf /var/run/php/php{7.0,}-fpm.sock
cat > /etc/supervisor/conf.d/php-fpm.conf <<EOF
[program:php-fpm]
directory=/
command=php-fpm7.0 -R -F
user=root
autostart=true
autorestart=true
EOF

# nginx configure
cat > /etc/supervisor/conf.d/nginx.conf <<EOF
[program:nginx]
directory=/
command=/usr/sbin/nginx
user=root
autostart=true
autorestart=true
EOF
