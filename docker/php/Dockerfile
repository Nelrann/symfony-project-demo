FROM php:8.3-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    bash \
    git \
    curl \
    zip \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    oniguruma-dev \
    icu-dev \
    postgresql-dev \
    mysql-client \
    linux-headers

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        mysqli \
        zip \
        gd \
        intl \
        opcache \
        mbstring \
        bcmath \
        exif \
        pcntl

# Install Composer (le vrai binaire, appelé par le wrapper qui prend un flock)
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer-real

# Wrapper Composer : verrouille pour éviter deux installs concurrents
COPY --chmod=755 composer-wrapper.sh /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy php config
COPY php.ini /usr/local/etc/php/conf.d/custom.ini

# Create user to avoid permission issues
RUN addgroup -g 1000 www && adduser -u 1000 -G www -s /bin/sh -D www

# Entrypoint dev : si le bind-mount n'a pas de vendor/ (checkout fraîchement
# cloné), lance composer install au démarrage avant de lancer php-fpm.
# (prod : le vendor est baked dans l'image, pas de bind — Dockerfile.prod n'en a pas besoin)
COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

USER www

EXPOSE 9000
CMD ["php-fpm"]
