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
  3. Recursively sets `www-data` ownership and correct permissions (`775`) on `var/` and `public/var/` to eliminate runtime 500 file-access errors.
  4. Runs `cache:clear`.
  5. Boots `supervisord` to serve the application.

