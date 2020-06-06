FROM debian:buster-slim

LABEL maintainer="Hubok <docker-maint@hubok.net>"

RUN set -x \
    && echo "deb http://deb.debian.org/debian/ unstable main contrib" >> /etc/apt/sources.list.d/nginx.list \
    && echo "Package: *\nPin: release a=stable\nPin-Priority: 500\n\nPackage: *\nPin: release a=unstable\nPin-Priority: 1\n" >> /etc/apt/preferences.d/99-sid \
    && apt-get update \
    && apt-get -y upgrade \
    && addgroup --system --gid 101 nginx \
    && adduser --system --disabled-login --ingroup nginx --no-create-home --home /nonexistent --gecos "nginx user" --shell /bin/false --uid 101 nginx \
    && apt-get -t unstable -y install nginx-full php7.4-fpm \
    && apt-get -y install openssl git curl vim htop \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && ln -sf /dev/stderr /var/log/php_errors.log

RUN set -x \
    && rm -rf /var/www/html /etc/nginx/sites-available/* /etc/nginx/sites-enabled/* /etc/php/7.4/fpm/php.ini \
    && curl https://raw.githubusercontent.com/amix/vimrc/master/vimrcs/basic.vim >> /root/.vimrc \
    && curl https://raw.githubusercontent.com/Hubok/processwire-docker/master/src/nginx.conf >> /etc/nginx/nginx.conf.conf \
    && curl https://raw.githubusercontent.com/Hubok/processwire-docker/master/src/nginx-siteconfig.conf >> /etc/nginx/sites-enabled/processwire.conf \
    && curl https://raw.githubusercontent.com/Hubok/processwire-docker/master/src/php.ini >> /etc/php/7.4/fpm/php.ini \
    && git clone https://github.com/processwire/processwire.git /var/www/html \
    && chown -R nginx:nginx /var/www/html

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
