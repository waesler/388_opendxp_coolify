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
        echo "Database is online! Parsing credentials..."
        
        # Parse DATABASE_URL into components
        DB_URL_PART=$(echo "$DATABASE_URL" | sed 's|mysql://||')
        DB_CREDS=$(echo "$DB_URL_PART" | cut -d'@' -f1)
        DB_CONN=$(echo "$DB_URL_PART" | cut -d'@' -f2 | cut -d'/' -f1)
        DB_USER=$(echo "$DB_CREDS" | cut -d':' -f1)
        DB_PASS=$(echo "$DB_CREDS" | cut -d':' -f2)
        DB_HOST=$(echo "$DB_CONN" | cut -d':' -f1)
        DB_PORT=$(echo "$DB_CONN" | cut -d':' -f2)
        DB_NAME=$(echo "$DB_URL_PART" | cut -d'/' -f2 | cut -d'?' -f1)
        DB_PORT=${DB_PORT:-3306}
        
        # Check if the database has tables (meaning it's already installed)
        TABLE_COUNT=$(php -r "
            try {
                \$pdo = new PDO('mysql:host=' . '$DB_HOST' . ';port=' . '$DB_PORT' . ';dbname=' . '$DB_NAME', '$DB_USER', '$DB_PASS');
                \$stmt = \$pdo->query(\"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '\$DB_NAME'\");
                echo (int) \$stmt->fetchColumn();
            } catch (Exception \$e) {
                echo 0;
            }
        ")
        
        if [ "${TABLE_COUNT:-0}" -eq 0 ]; then
            echo "Database is empty! Running OpenDXP core installation..."
            vendor/bin/opendxp-install \
                --admin-username=admin \
                --admin-password=admin \
                --mysql-host-socket="$DB_HOST" \
                --mysql-username="$DB_USER" \
                --mysql-password="$DB_PASS" \
                --mysql-database="$DB_NAME" \
                --mysql-port="$DB_PORT" \
                --skip-database-config \
                --no-interaction
        else
            echo "Database is already initialized ($TABLE_COUNT tables found)."
        fi
        
        echo "Ensuring bundles are installed..."
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
        
        # Rebuild PHP classes from config/database
        echo "Rebuilding PHP classes..."
        php bin/console pimcore:deployment:classes-rebuild --force -n

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
