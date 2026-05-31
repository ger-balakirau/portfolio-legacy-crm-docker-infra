FROM php:7.0-apache

# LEGACY DEV ONLY:
# - PHP 7.0 and Debian Stretch are EOL.
# - Keep this image only for compatibility with legacy CRM code.

ENV DEBIAN_FRONTEND=noninteractive \
  COMPOSER_ALLOW_SUPERUSER=1 \
  COMPOSER_MEMORY_LIMIT=-1 \
  MAKEFLAGS="-j$(nproc)"

ARG PUID=1000
ARG PGID=1000

# Репозитории Stretch (EOL) + пакеты
RUN set -eux; \
  printf '%s\n' \
  'deb http://archive.debian.org/debian stretch main contrib non-free' \
  'deb http://archive.debian.org/debian-security stretch/updates main contrib non-free' \
  > /etc/apt/sources.list; \
  rm -f /etc/apt/sources.list.d/*.list; \
  printf 'Acquire::Check-Valid-Until "false";\nAcquire::AllowInsecureRepositories "true";\nAPT::Get::AllowUnauthenticated "true";\n' \
  > /etc/apt/apt.conf.d/99archive; \
  apt-get update; \
  apt-get install -y --allow-unauthenticated --no-install-recommends \
  libc-client2007e-dev libkrb5-dev libssl-dev \
  libcurl4-openssl-dev libmcrypt-dev libedit-dev libgettextpo-dev \
  libjpeg62-turbo-dev libpng-dev libfreetype6-dev libxslt1-dev \
  libxml2-dev zlib1g-dev libzip-dev libicu-dev \
  libmagickwand-dev unzip curl mariadb-client ca-certificates; \
  rm -rf /var/lib/apt/lists/*

RUN set -eux; \
  docker-php-ext-configure imap --with-kerberos --with-imap-ssl; \
  docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/; \
  docker-php-ext-install \
  calendar curl ftp gettext imap intl mbstring mcrypt \
  mysqli opcache pcntl pdo pdo_mysql posix readline \
  shmop sockets sysvmsg sysvsem sysvshm \
  wddx xsl zip gd xml exif fileinfo soap

RUN set -eux; pecl install imagick-3.4.4; docker-php-ext-enable imagick

# Приводим www-data к uid/gid хостового пользователя по умолчанию (1000:1000)
RUN set -eux; \
  groupmod -o -g "${PGID}" www-data; \
  usermod -o -u "${PUID}" -g "${PGID}" www-data

# Apache + .htaccess + ServerName (убирает AH00558)
RUN a2enmod rewrite \
  && printf 'ServerName localhost\n' > /etc/apache2/conf-available/servername.conf \
  && a2enconf servername \
  && sed -ri 's!AllowOverride +None!AllowOverride All!g' /etc/apache2/apache2.conf

# Отключаем/удаляем любые прежние конфиги OPcache (на случай кэша слоёв)
RUN rm -f /usr/local/etc/php/conf.d/*opcache*.ini 2>/dev/null || true

# Composer v1
COPY --from=composer:1 /usr/bin/composer /usr/bin/composer

# Рабочая директория
WORKDIR /var/www/html/example-crm.local
CMD ["apache2-foreground"]
