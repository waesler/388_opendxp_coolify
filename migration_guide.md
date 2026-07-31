# OpenDXP Migration & Server Deployment Guide

This guide details the manual steps and checks required to deploy this OpenDXP stack onto a different server smoothly.

## 1. Database Schema Migrations (Required when restoring older dumps)
If you are restoring/importing a database dump from an older environment, it may lack columns that the updated OpenDXP codebase expects. Run the following queries on the newly provisioned database *after* importing the SQL dump:

```sql
-- 1. Add missing 'isStudio' column on the 'users' table
ALTER TABLE users ADD COLUMN isStudio tinyint(1) NOT NULL DEFAULT 0;

-- 2. Add 'definitionModificationDate' to the 'classes' table (prevents class-rebuild errors)
ALTER TABLE classes ADD COLUMN definitionModificationDate bigint(20) DEFAULT NULL;

-- 3. Add 'payload' and 'isStudio' to the 'notifications' table (prevents 500 errors on dashboard load)
ALTER TABLE notifications ADD COLUMN payload longtext DEFAULT NULL, ADD COLUMN isStudio tinyint(1) NOT NULL DEFAULT 0;
```

---

## 2. Coolify Deployment & Build Settings

### Skip Scripts during Docker Build
The Dockerfile uses the `--no-scripts` flag during the `composer install` phase:
`RUN composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs --no-scripts`
This is critical because building the image happens without live database access; booting the Symfony kernel during build will crash the pipeline.

### Entrypoint Automation (Startup)
The container's `entrypoint.sh` automatically performs:
1. Database checks and clean installs if empty.
2. Installing required OpenDXP bundles automatically.
3. Rebuilding database structures (`opendxp:deployment:classes-rebuild`).
4. Publishing bundle assets (`assets:install`) so CSS and JS assets are loaded correctly.
5. Performing `cache:clear`.
6. Setting correct ownership (`www-data:www-data`) and permissions (`775`) on `var/` and `public/var/`.

All console commands inside the entrypoint are configured to run under `su -s /bin/sh -c "php bin/console ..." www-data` to prevent root-owned cache or logs from locking the filesystem.

### Post-Deployment Commands
If you use a **Post Deployment Command** inside the Coolify Web UI, make sure it either:
* **Or is removed entirely**, as the entrypoint script already handles cache warming and clears it cleanly with correct permissions on every startup. Running it as `root` (the default) will lock the cache files again.

### Disabling Health Check (Coolify Web)
The upstream `terraform-coolify-shopware-stack` module has the web container's HTTP health check hardcoded to `true`. To disable the health check, you must manually edit the downloaded module code inside the `.terraform/` folder before running the bootstrap command:
1. In `infra/.terraform/modules/production/apps.tf` and `infra/.terraform/modules/staging/apps.tf` (if staging is enabled), find `health_check_enabled = true` (around line 27).
2. Change it to: `health_check_enabled = false`.
3. Run `ddev coolify-bootstrap up` to apply the changes.

---

## 3. Database Proxies & Networking
* Shopware and OpenDXP databases run on different ports to prevent host port allocation conflicts.
* In the current setup, Shopware is exposed on port `3306`, and the OpenDXP database proxy is exposed on port `3307` (production).
* Make sure your `DATABASE_URL` points to the correct port (`3307` for OpenDXP) when wiring external tools or your local DDEV environment to the database.
