#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=========================================================="
echo " Pimcore to OpenDXP Local Migration Script"
echo "=========================================================="

# ---------------------------------------------------------
# 1. Configuration (Adjust these values or use a .env file)
# ---------------------------------------------------------
SOURCE_PIMCORE_DIR=""    # Path to local Pimcore source (e.g., /home/luis/old-pimcore)
TARGET_OPENDXP_DIR="$(pwd)" # This script runs from the OpenDXP root directory

# Target DB Credentials
TARGET_DB_HOST="127.0.0.1"
TARGET_DB_USER="root"
TARGET_DB_PASS=""
TARGET_DB_NAME="opendxp"
TARGET_DB_PORT="3306"

# Source DB Credentials (if importing directly from source DB)
SOURCE_DB_HOST="127.0.0.1"
SOURCE_DB_USER="root"
SOURCE_DB_PASS=""
SOURCE_DB_NAME="pimcore"
SOURCE_DB_PORT="3306"
SOURCE_SQL_DUMP=""       # Or provide path to a pre-existing SQL dump file

# S3 Configuration
S3_ENDPOINT=""            # e.g., https://s3.eu-central-3.hetznerobjects.com
S3_BUCKET_PUBLIC=""
S3_BUCKET_PRIVATE=""
S3_PREFIX_ASSETS="opendxp/production/public"
S3_PREFIX_VERSIONS="opendxp/production/private"
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
AWS_DEFAULT_REGION="us-east-1"

# Load environment overrides if a migration .env file exists
if [ -f "migration.env" ]; then
    echo "Loading overrides from migration.env..."
    export $(grep -v '^#' migration.env | xargs)
fi

# Validate inputs
if [ -z "$SOURCE_PIMCORE_DIR" ] || [ ! -d "$SOURCE_PIMCORE_DIR" ]; then
    echo "Error: SOURCE_PIMCORE_DIR is not set or does not exist."
    echo "Please set it in migration.env or edit this script."
    exit 1
fi

# ---------------------------------------------------------
# Step 1: Copy Class and System Definitions to Git Workspace
# ---------------------------------------------------------
echo "--> Syncing class definitions to Git workspace..."
mkdir -p "$TARGET_OPENDXP_DIR/var/config"

CONFIG_DIRS=(
    "classes"
    "fieldcollections"
    "objectbricks"
    "classificationstore"
    "customviews"
    "data_hub"
    "image_thumbnails"
    "predefined_properties"
    "predefined_asset_metadata"
)

for dir in "${CONFIG_DIRS[@]}"; do
    if [ -d "$SOURCE_PIMCORE_DIR/var/config/$dir" ]; then
        echo "Copying $dir definition files..."
        rm -rf "$TARGET_OPENDXP_DIR/var/config/$dir"
        cp -r "$SOURCE_PIMCORE_DIR/var/config/$dir" "$TARGET_OPENDXP_DIR/var/config/"
    else
        echo "Config directory var/config/$dir not found in source, skipping."
    fi
done

echo "Success: Class configs copied. You can now run 'git status' and commit them."

# ---------------------------------------------------------
# Step 2: Migrate Database
# ---------------------------------------------------------
echo "--> Starting database migration..."
TEMP_DUMP="/tmp/pimcore_migration_dump.sql"

if [ -n "$SOURCE_SQL_DUMP" ] && [ -f "$SOURCE_SQL_DUMP" ]; then
    echo "Using existing SQL dump from $SOURCE_SQL_DUMP..."
    TEMP_DUMP="$SOURCE_SQL_DUMP"
else
    echo "Dumping source database $SOURCE_DB_NAME..."
    mysqldump -h "$SOURCE_DB_HOST" -P "$SOURCE_DB_PORT" -u "$SOURCE_DB_USER" -p"$SOURCE_DB_PASS" "$SOURCE_DB_NAME" > "$TEMP_DUMP"
fi

echo "Importing database dump into target database $TARGET_DB_NAME..."
mysql -h "$TARGET_DB_HOST" -P "$TARGET_DB_PORT" -u "$TARGET_DB_USER" -p"$TARGET_DB_PASS" "$TARGET_DB_NAME" < "$TEMP_DUMP"

if [ -z "$SOURCE_SQL_DUMP" ]; then
    rm -f "$TEMP_DUMP"
fi
echo "Success: Database imported successfully."

# ---------------------------------------------------------
# Step 3: Upload Assets to S3
# ---------------------------------------------------------
if [ -n "$S3_BUCKET_PUBLIC" ] && [ -n "$S3_ENDPOINT" ]; then
    echo "--> Syncing assets to S3..."
    
    # Configure AWS credentials for the command environment
    export AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY
    export AWS_DEFAULT_REGION

    # Sync public assets
    if [ -d "$SOURCE_PIMCORE_DIR/public/var/assets" ]; then
        echo "Uploading public assets to S3..."
        aws s3 sync "$SOURCE_PIMCORE_DIR/public/var/assets" \
            "s3://$S3_BUCKET_PUBLIC/$S3_PREFIX_ASSETS" \
            --endpoint-url "$S3_ENDPOINT"
    fi

    # Sync private versions (optional)
    if [ -d "$SOURCE_PIMCORE_DIR/var/versions" ] && [ -n "$S3_BUCKET_PRIVATE" ]; then
        echo "Uploading private version histories to S3..."
        aws s3 sync "$SOURCE_PIMCORE_DIR/var/versions" \
            "s3://$S3_BUCKET_PRIVATE/$S3_PREFIX_VERSIONS" \
            --endpoint-url "$S3_ENDPOINT"
    fi
    echo "Success: Assets synced to S3."
else
    echo "S3 configuration incomplete (S3_BUCKET_PUBLIC or S3_ENDPOINT empty). Skipping S3 upload."
fi

echo "=========================================================="
echo " Migration completed locally!"
echo " Next Steps:"
echo " 1. Run 'git add var/config/ && git commit' to save definitions."
echo " 2. Deploy your application to build classes and clear cache."
echo "=========================================================="
