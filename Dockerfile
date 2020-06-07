FROM debian:buster-slim

LABEL Maintainer="Hubok <docker-maint@hubok.net>" \
      Description="ProcessWire container with Nginx and PHP-FPM 7.4 based on Debian Buster."

ENV VERSION_PROCESSWIRE     3.0.148
ENV VERSION_NGINX           1.19.0
ENV VERSION_PHP             7.4.0

# Install required packages
COPY config/gpg_nginx.key /root/gpg_nginx.key
COPY config/gpg_sury.key /root/gpg_sury.key
RUN set -x \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y gnupg1 ca-certificates \
    && apt-key add /root/gpg_nginx.key \
    && apt-key add /root/gpg_sury.key \
    && rm -f /root/gpg_nginx.key /root/gpg_sury.key
COPY config/apt-sources-custom.conf /etc/apt/sources.list.d/custom.list
COPY config/apt-preferences-custom.conf /etc/apt/preferences.d/99-custom
RUN set -x \
    && apt-get update \
    && apt-get -y upgrade \
    && addgroup --system --gid 101 nginx \
    && adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 101 nginx \
    && apt-get install --no-install-recommends --no-install-suggests -y nginx=1.19.0* php7.4-fpm supervisor openssl git

# Setup error logging
RUN set -x \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && ln -sf /dev/stderr /var/log/php_errors.log

# Clean out existing files
RUN set -x \
    && rm -rf /var/www/html /etc/nginx/conf.d/* /etc/nginx/sites-available/* /etc/nginx/sites-enabled/* \
    && rm -f /etc/nginx/nginx.conf /etc/php/7.4/fpm/php.ini /etc/php/7.4/fpm/pool.d/www.conf

# Configure Nginx
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx-siteconfig.conf /etc/nginx/conf.d/processwire.conf

# Configure PHP-FPM
COPY config/php.ini /etc/php/7.4/fpm/php.ini
COPY config/php-www.conf /etc/php/7.4/fpm/pool.d/www.conf
RUN set -x \
    && mkdir /run/php

# Download ProcessWire
RUN set -x \
    && git clone -b '3.0.148' --single-branch https://github.com/processwire/processwire.git /var/www/html \
    && chown -R nginx:nginx /var/www/html

# Setup supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

STOPSIGNAL SIGTERM

EXPOSE 80

WORKDIR /var/www/html

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
