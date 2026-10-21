#!/bin/sh

# Rebuild PHP from the official sources when the php:8.4-fpm-alpine image is not yet published for PHP_VERSION.
# Mirrors the build of https://github.com/docker-library/php (8.4/alpine/fpm) so that the result, including the
# /usr/src/php.tar.xz sources used by docker-php-ext-install, matches the upstream image of the same version.

set -eux

if [ "$(php -r 'echo PHP_VERSION;')" = "${PHP_VERSION}" ]; then
    echo "PHP ${PHP_VERSION} is already installed, nothing to upgrade"
    exit 0
fi

apk add --no-cache --virtual .fetch-deps gnupg

cd /usr/src
rm -f php.tar.xz php.tar.xz.asc
curl -fsSL -o php.tar.xz "${PHP_URL}"
echo "${PHP_SHA256} *php.tar.xz" | sha256sum -c -
curl -fsSL -o php.tar.xz.asc "${PHP_ASC_URL}"
export GNUPGHOME="$(mktemp -d)"
for key in ${GPG_KEYS}; do
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${key}"
done
gpg --batch --verify php.tar.xz.asc php.tar.xz
gpgconf --kill all
rm -rf "${GNUPGHOME}"
apk del --no-network .fetch-deps

apk add --no-cache --virtual .php-build-deps \
    ${PHPIZE_DEPS} \
    argon2-dev \
    coreutils \
    curl-dev \
    gnu-libiconv-dev \
    libsodium-dev \
    libxml2-dev \
    linux-headers \
    oniguruma-dev \
    openssl-dev \
    readline-dev \
    sqlite-dev

# Make sure musl's iconv is not used (https://www.php.net/manual/en/intro.iconv.php)
rm -vf /usr/include/iconv.h

export \
    CFLAGS="${PHP_CFLAGS}" \
    CPPFLAGS="${PHP_CPPFLAGS}" \
    LDFLAGS="${PHP_LDFLAGS}" \
    PHP_BUILD_PROVIDER='https://github.com/docker-library/php' \
    PHP_UNAME='Linux - Docker'

docker-php-source extract
cd /usr/src/php
gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"
./configure \
    --build="${gnuArch}" \
    --sysconfdir="${PHP_INI_DIR%/php}" \
    --with-config-file-path="${PHP_INI_DIR}" \
    --with-config-file-scan-dir="${PHP_INI_DIR}/conf.d" \
    --enable-option-checking=fatal \
    --with-mhash \
    --with-pic \
    --enable-mbstring \
    --enable-mysqlnd \
    --with-password-argon2 \
    --with-sodium=shared \
    --with-pdo-sqlite=/usr \
    --with-sqlite3=/usr \
    --with-curl \
    --with-iconv=/usr \
    --with-openssl \
    --with-readline \
    --with-zlib \
    --disable-phpdbg \
    --with-pear \
    --disable-cgi \
    --enable-fpm \
    --with-fpm-user=www-data \
    --with-fpm-group=www-data
make -j "$(nproc)"
find -type f -name '*.a' -delete
make install
find /usr/local -type f -perm '/0111' -exec sh -euxc 'strip --strip-all "$@" || :' -- '{}' +
make clean
cp -v php.ini-* "${PHP_INI_DIR}/"

cd /
docker-php-source delete

runDeps="$( \
    scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
        | tr ',' '\n' \
        | sort -u \
        | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
)"
apk add --no-cache ${runDeps}
apk del --no-network .php-build-deps

pecl update-channels
rm -rf /tmp/pear ~/.pearrc

php --version
test "$(php -r 'echo PHP_VERSION;')" = "${PHP_VERSION}"
test "$(php-fpm -v | head -n 1 | cut -d ' ' -f 2)" = "${PHP_VERSION}"
