#!/bin/sh
set -e

echo "Starting OpenDXP entrypoint script..."

# Ensure write permissions on var/ and public/var/ right away
mkdir -p var public/var
chown -R www-data:www-data var public/var
chmod -R 775 var public/var

# Run PHP console cache clear and database setup
if [ -n "$DATABASE_URL" ]; then
    echo "Database URL is present. Checking database connectivity..."
    
    # Simple PHP snippet to check if we can connect to the database
    if php -r "
        \$url = getenv('DATABASE_URL');
        \$parts = parse_url(\$url);
        \$host = \$parts['host'];
        \$port = isset(\$parts['port']) ? \$parts['port'] : 3306;
        \$fp = @fsockopen(\$host, \$port, \$errno, \$errstr, 5);
        if (\$fp) {
            fclose(\$fp);
            exit(0);
        }
        exit(1);
    "; then
        echo "Database is online! Ensuring bundles are installed..."
        
        # Run bundle installs automatically
        for bundle in OpenDxpSeoBundle \
                      OpenDxpApplicationLoggerBundle \
                      OpenDxpCustomReportsBundle \
                      OpenDxpGlossaryBundle \
                      OpenDxpSimpleBackendSearchBundle \
                      OpenDxpStaticRoutesBundle \
                      OpenDxpTinymceBundle \
                      OpenDxpUuidBundle \
                      OpenDxpWordExportBundle \
                      OpenDxpXliffBundle \
                      OpenDxpGenericExecutionEngineBundle; do
            echo "Installing $bundle..."
            php bin/console opendxp:bundle:install "$bundle" --no-interaction --no-assets-install || echo "Failed to install $bundle (might already be installed)"
        done
        
        # Clear cache
        php bin/console cache:clear -n
    else
        echo "Database is not reachable. Skipping bundle installation."
    fi
fi

# Ensure permissions are correct before starting Nginx/Supervisor
chown -R www-data:www-data var public/var
chmod -R 775 var public/var

echo "OpenDXP entrypoint tasks finished. Launching Supervisor..."
exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
