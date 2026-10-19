#!/bin/sh
set -e

export BLACKFIRE_CLIENT_ID="${BLACKFIRE_CLIENT_ID:-}"
export BLACKFIRE_CLIENT_TOKEN="${BLACKFIRE_CLIENT_TOKEN:-}"
export BLACKFIRE_LOG_FILE="${BLACKFIRE_LOG_FILE:-}"

if { [ -n "${BLACKFIRE_SERVER_ID:-}" ] && [ -n "${BLACKFIRE_SERVER_TOKEN:-}" ]; } || \
    { [ -n "${BLACKFIRE_CLIENT_ID:-}" ] && [ -n "${BLACKFIRE_CLIENT_TOKEN:-}" ]; }; then
    if [ "${BLACKFIRE_DISABLE_PCOV:-1}" = "1" ] && [ -f /usr/local/etc/php/conf.d/90-pcov.ini ]; then
        echo "Disabling pcov while Blackfire is configured."
        rm -f /usr/local/etc/php/conf.d/90-pcov.ini
    fi
fi

# PHP-FPM logs as JSON events on stdout
rm -f /tmp/php-fpm.log
mkfifo -m 600 /tmp/php-fpm.log
awk -v source=php-fpm -f /usr/local/etc/log-to-json.awk < /tmp/php-fpm.log &

exec /usr/local/sbin/php-fpm --nodaemonize 2> /tmp/php-fpm.log
