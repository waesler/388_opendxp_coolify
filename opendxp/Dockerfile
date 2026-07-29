FROM opendxp/opendxp:php8.3-latest

WORKDIR /var/www/html

# Copy application files
COPY --chown=www-data:www-data . .

# Install dependencies using Composer
RUN composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs

# Ensure permissions are correct
RUN chmod -R 775 var public/var
