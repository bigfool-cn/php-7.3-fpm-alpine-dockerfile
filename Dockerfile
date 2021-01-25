FROM php:7.3-fpm-alpine

MAINTAINER bigfool <1063944784@qq.com>

# 替换apk源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装composer
RUN set -xe \
  && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
  && php composer-setup.php \
  && php -r "unlink('composer-setup.php');" \
  && mv composer.phar /usr/local/bin/composer \
  && composer self-update \
  && composer config -g repo.packagist composer https://packagist.phpcomposer.com

# 安装phpize依赖
RUN apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS

# 安装扩展
RUN docker-php-ext-install pdo_mysql \
    opcache \
    sockets \
    pcntl 

# 安装event扩展
RUN set -xe \
    && apk add --no-cache --update libevent-dev openssl-dev \
    && pecl install event \
    && docker-php-ext-enable --ini-name zz-event.ini event

# 安装gd扩展
ENV GD_DEPS libpng-dev freetype-dev libjpeg-turbo-dev
RUN set -xe \
  && apk add --no-cache --update --virtual .gd_deps $GD_DEPS \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/  \
  && docker-php-ext-install -j$(nproc) gd

# 安装memcached扩展
ENV MEMCACHED_DEPS zlib-dev libmemcached-dev cyrus-sasl-dev
RUN apk add --no-cache --update libmemcached-libs zlib
RUN set -xe \
  && apk add --no-cache --update --virtual .memcached-deps $MEMCACHED_DEPS \
  && pecl install memcached \
  && echo "extension=memcached.so" > /usr/local/etc/php/conf.d/20_memcached.ini \
  && rm -rf /usr/share/php7 \
  && rm -rf /tmp/* \
  && apk del .memcached-deps

# 安装redis扩展
RUN pecl install redis-5.0.0 \
    && docker-php-ext-enable redis

# 删除phpize依赖 减少镜像体积
RUN apk del .phpize-deps

RUN rm -rf /tmp/* \
    && rm -rf /var/cache/apk/*
