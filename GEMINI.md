# GEMINI.md

> [!IMPORTANT]
> This file must be kept updated at all times to ensure smooth handovers between sessions.

## Project Handover & Progress Summary

### 1. Hetzner S3 Integration (Shopware)
- **Problem**: Staging and production were coupled to the same S3 provider credentials/endpoints in the OpenTofu setup, preventing independent bucket configuration.
- **Solution**: 
  - Split the `aws` provider in `providers.tf` into `aws.production` and `aws.staging`.
  - Duplicated the CORS resource in `cors.tf` into `public_production` and `public_staging`.
  - Updated the `coolify-bootstrap` script to target the environment-specific CORS rules.

### 2. Optional Staging Environment
- **Problem**: Staging configuration was mandatory in OpenTofu variables.
- **Solution**: Added the `enable_staging` boolean flag (default `true`) and made staging objects nullable. Setting `enable_staging = false` completely skips staging module provisioning.

### 3. Separation of Shopware and OpenDXP
- **Problem**: Recreating OpenDXP within the same project directory caused naming and tooling conflicts.
- **Solution**:
  - The root directory (`/home/luis/swoofy`) is now purely for **Shopware**.
  - A self-contained directory `openDXP/` was created for the **OpenDXP** platform, initialized with the `open-dxp/skeleton` via Composer.
  - Cleaned up Shopware-specific tools (e.g. `shopware-cli` and storefront watchers) from the `openDXP/.ddev/` config.

### 4. Build & Registry setup for OpenDXP
- **Problem**: Coolify failed to pull the OpenDXP web image.
- **Solution**:
  - Created a production-ready `openDXP/opendxp/Dockerfile`.
  - Created a GitHub Action workflow `.github/workflows/opendxp-ci-cd.yml` to automatically build and push the OpenDXP image to GHCR upon changes to the `openDXP/` path.
  - Recommended pointing `web_image` in `openDXP/infra/production.tfvars` to this registry path.

### 5. Architectural Decisions for OpenDXP
- **Elasticsearch**: Optional. Can be disabled by setting `enable_elasticsearch = false` in `production.tfvars`.
- **RabbitMQ**: Optional. Symfony Messenger can be configured to use the MariaDB database as a transport queue (`MESSENGER_TRANSPORT_DSN=doctrine://default`) instead of RabbitMQ.

### 6. Troubleshooting & Automation Integration
- **RabbitMQ Port Conflict**: Production `rabbitmq_mgmt_port` was updated to `25673` to avoid host port allocation conflicts with the Shopware stack running on the same server.
- **Scheduler & Workers Commands**: Updated the `workers` service definition inside `openDXP/infra/.terraform/modules/production/workers.tf` to use `opendxp:maintenance` (instead of the Shopware-specific `scheduled-task:run` command) and mapped workers to consume the actual OpenDXP queues (`opendxp_core`, `opendxp_maintenance`, etc.).
- **Doctrine Mappings**: Configured `enum: string` and `bit: boolean` inside `doctrine.yaml` to allow database schema introspection without throwing errors on MariaDB.
- **Docker Startup Automation**: Created a custom startup script `.docker/entrypoint.sh` and set it as the Docker `ENTRYPOINT`. On container boot, it automatically:
  1. Checks database connectivity.
  2. Installs all required OpenDXP bundles (`OpenDxpSeoBundle`, `OpenDxpGlossaryBundle`, etc.) to build their database tables automatically.
  3. Recursively sets `www-data` ownership and correct permissions (`775`) on `var/` and `public/var/`.
  4. Runs `cache:clear`.
  5. Boots `supervisord` to serve the application.

### 7. Standalone Repository Split (OpenDXP)
- **Problem**: Need to split the combined Shopware & OpenDXP repository into two separate standalone repositories.
- **Solution**: Created a fully scaffolded standalone OpenDXP repository export at `/home/luis/opendxp_export/` with the application code and OpenTofu infrastructure moved directly to the root directory, alongside an updated `.github/workflows/opendxp-ci-cd.yml` workflow configured to build directly from the root context.

### 8. Flysystem S3 Storage Integration & Build Fixes
- **Problem**: Uploaded files and media assets were saved to container ephemeral storage, resulting in data loss on container redeploys.
- **Solution**:
  - Installed `league/flysystem-aws-s3-v3` library in the OpenDXP composer file.
  - Added [opendxp/config/packages/prod/flysystem.yaml](file:///home/luis/swoofy/opendxp/config/packages/prod/flysystem.yaml) to map public assets, thumbnails, and private versions directly to the Hetzner S3 bucket using the `aws` adapter.
  - Appended default dummy values for `DATABASE_URL` and S3 settings in [opendxp/.env](file:///home/luis/swoofy/opendxp/.env) to prevent compilation failure during container image builds.
  - Adjusted `bucket_private = "unimess"` and configured `path_prefix = "opendxp/production"` inside `openDXP/infra/production.tfvars` to cleanly separate assets in S3 without name collisions or invalid bucket paths.

### 9. Automated Database Schema Patching
- **Problem**: Older database dumps imported onto a clean-slate server lacked required schema columns (`isStudio`/`payload` on `notifications`, `isStudio` on `users`, `definitionModificationDate` on `classes`), causing recurrent HTTP 500 errors on backend load.
- **Solution**: Added SQL schema patches using `doctrine:query:sql "ALTER TABLE ... ADD COLUMN IF NOT EXISTS"` inside `entrypoint.sh` to automatically inject missing columns on container startup.

### 10. DataHub Bundle Installation
- **Problem**: The OpenDXP DataHub bundle was missing.
- **Solution**: 
  - Installed `open-dxp/data-hub-bundle` via Composer.
  - Registered it in `config/bundles.php` and automated its registration in `entrypoint.sh`.
  - Migrated configuration files inside `var/config/data_hub/*.yaml` from the obsolete `pimcore_data_hub:` key to the new `opendxp_data_hub:` namespace.

### 11. S3 Paths & Assets Loading Correction
- **Problem**: Media assets in the S3 bucket returned 404/500 errors.
- **Solution**: Identified that assets in the S3 bucket are located under `unimess/pimcore/assets/`. Corrected `S3_PREFIX_ASSETS`, `S3_PREFIX_THUMBNAILS`, and `cdn_domain` in `production.tfvars` to point to the actual unimess paths.

### 12. Bootstrap Command & Health Check Corrections
- **Problem**: Hardcoded HTTP health checks on the web container caused issues, and the bootstrap checklist referenced Shopware commands and incorrect Alpine UIDs (`82:82`).
- **Solution**: 
  - Disabled the health check by setting `health_check_enabled = false` inside `.terraform/` module files.
  - Updated `coolify-bootstrap` script output to use UID `33:33` (Debian/Ubuntu `www-data` standard) and corrected commands to use OpenDXP indexing (`opendxp:search-backend-reindex`) and removed Shopware theme compilers.

### 13. Local Thumbnail Storage Migration
- **Problem**: Latency in dynamic thumbnail generation and S3 API calls slowed down image delivery.
- **Solution**:
  - Modified [opendxp/config/packages/prod/flysystem.yaml](file:///home/luis/swoofy/opendxp/config/packages/prod/flysystem.yaml) to change the storage adapter for `opendxp.thumbnail.storage` from `aws` to `local` pointing to `%kernel.project_dir%/public/var/tmp`.
  - Documented the requirement to map a Coolify persistent storage volume to `/var/www/html/public/var/tmp` to ensure persistence across container redeploys.
