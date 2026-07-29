FROM opendxp/opendxp:php8.3-latest

WORKDIR /var/www/html

# Install Nginx and Supervisor
RUN apt-get update && apt-get install -y nginx supervisor && rm -rf /var/lib/apt/lists/*

# Copy application files
COPY --chown=www-data:www-data . .

# Configure Nginx and Supervisor
COPY .docker/nginx-prod.conf /etc/nginx/sites-available/default
COPY .docker/supervisord-prod.conf /etc/supervisor/conf.d/supervisord.conf

# Install dependencies using Composer
RUN composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs

# Ensure permissions and directories are correct
RUN mkdir -p var public/var && chown -R www-data:www-data var public/var && chmod -R 775 var public/var

EXPOSE 8000

CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
