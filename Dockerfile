FROM composer:2.0.12 AS composer

FROM php:8.0.3-apache AS shared
RUN apt-get update && apt-get install -y \
  busybox-static \
  libpq-dev \
  libzip-dev \
  locales \
  supervisor \
  unzip \
  && docker-php-ext-install \
  bcmath \
  pdo_mysql \
  pdo_pgsql \
  zip \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
RUN localedef -i ja_JP -c -f UTF-8 -A /usr/share/locale/locale.alias ja_JP.UTF-8
COPY ./docker-compose/php/my.ini /usr/local/etc/php/conf.d/
RUN a2enmod rewrite
ARG APACHE_DOCUMENT_ROOT=/var/www/html/laravel/public
ENV APACHE_DOCUMENT_ROOT ${APACHE_DOCUMENT_ROOT}
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
COPY ./docker-compose/php/001-my.conf /etc/apache2/sites-available/001-my.conf
RUN a2dissite 000-default \
  && a2ensite 001-my
ENV APP_ENV laravel
RUN mkdir -p /var/log/supervisor
COPY ./docker-compose/php/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./docker-compose/php/crontabs/root /var/spool/cron/crontabs/root
RUN ln -sf /dev/stdout /var/log/cron
CMD ["/usr/bin/supervisord"]

FROM shared AS develop
COPY --from=composer /usr/bin/composer /usr/bin/composer
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
  && apt-get update && apt-get install -y \
  git \
	nodejs \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

#FROM composer AS build_composer
#ENV APP_ENV laravel
#COPY --chown=www-data:www-data ./composer.json ./composer.lock ./
#RUN composer install --prefer-dist --no-dev --no-autoloader --no-scripts --no-progress --no-suggest --no-interaction
#COPY --chown=www-data:www-data . .
#RUN composer dump-autoload \
#  && composer run-script post-root-package-install \
#  && composer run-script post-create-project-cmd
#
#FROM node:14.15.0 AS build_npm
#WORKDIR /app
#COPY ./package.json ./package-lock.json ./
#RUN npm install
#COPY . .
#RUN npm run production
#
#FROM shared AS server
#COPY --from=build_composer --chown=www-data:www-data ./app/ .
#RUN touch ./database/database.sqlite
#COPY --from=build_npm --chown=www-data:www-data ./app/public/css ./public/css
#COPY --from=build_npm --chown=www-data:www-data ./app/public/js ./public/js
#COPY --from=build_npm --chown=www-data:www-data ./app/public/mix-manifest.json ./public/mix-manifest.json
