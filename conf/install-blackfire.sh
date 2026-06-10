#!/bin/sh
set -e

version="$(php -r 'echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;')"
machine="$(uname -m)"
architecture="$(case "$machine" in
    i386 | i686 | x86) echo "i386" ;;
    x86_64 | amd64) echo "amd64" ;;
    aarch64 | arm64 | armv8) echo "arm64" ;;
    *) echo "Unsupported architecture: $machine" >&2; exit 1 ;;
esac)"
probe_dir="$(mktemp -d)"

cleanup() {
    rm -rf "$probe_dir" /tmp/blackfire-probe.tar.gz
}
trap cleanup EXIT

curl -A "Docker" -fsSL -o /tmp/blackfire-probe.tar.gz "https://blackfire.io/api/v1/releases/probe/php/alpine/${architecture}/${version}"
tar zxf /tmp/blackfire-probe.tar.gz -C "$probe_dir"
mv "$probe_dir"/blackfire-*.so "$(php -r 'echo ini_get("extension_dir");')/blackfire.so"
docker-php-ext-enable --ini-name 95-blackfire.ini blackfire
