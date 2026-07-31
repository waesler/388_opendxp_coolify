# Project-wide (non-secret, not per-env): the Coolify project that owns both environments.
project_name = "OpenDXP"

# Production environment settings (non-secret). Secrets live in secrets.auto.tfvars.
production = {
  web_image         = "ghcr.io/waesler/388_opendxp_coolify/opendxp"
  web_image_tag     = "latest"
  web_domain        = "http://opendxp.128.140.126.141.sslip.io"
  app_env           = "prod"
  app_debug         = "0"
  monolog_log_level = "error"

  # Infra toggles (per-env; previously literals in main.tf). ES powers storefront/admin
  # search — needs a one-time index build after apply (see README). Mailpit off: prod
  # sends real mail via secrets_production.mailer_dsn.
  enable_elasticsearch = true
  enable_mailpit       = false
  enable_backup        = false
  backup = {
    s3_backup_bucket = "opendxp-backup"
    s3_backup_region = "hel1"
    s3_backup_domain = "https://hel1.your-objectstorage.com"
    s3_backup_path   = "production"
    # db_backups_to_keep / s3_backup_retain_days / db_schedule / s3_schedule use defaults
    # (60 / 30 / "0 2 * * *" / "30 2 * * *"). Override here if desired.
  }

  mariadb_conf = <<-CNF
    [mysqld]
    innodb_buffer_pool_size=1G
    group_concat_max_len=320000
    sql_mode=STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
    innodb_lock_wait_timeout=120
  CNF

  # cache may evict; session must NOT (evicting it = lost sessions). Lock lives in the DB.
  redis_conf = {
    cache   = <<-CONF
      appendonly no
      save ""
      maxmemory-policy volatile-lru
    CONF
    session = <<-CONF
      appendonly yes
      maxmemory-policy allkeys-lru
    CONF
  }

  # Per-env runtime knobs read by the OpenDXP base image (php-fpm pool + php.ini), merged over
  # the shared static_env. FPM_PM_* tune the web container's php-fpm; PHP_* set php.ini limits.
  static_env = {
    FPM_PM_MAX_CHILDREN      = "10"
    FPM_PM_START_SERVERS     = "4"
    FPM_PM_MIN_SPARE_SERVERS = "2"
    FPM_PM_MAX_SPARE_SERVERS = "6"
    FPM_PM_MAX_REQUESTS      = "0"
    PHP_MAX_UPLOAD_SIZE      = "128m"
    PHP_MAX_EXECUTION_TIME   = "300"
    PHP_MEMORY_LIMIT         = "1024m"
    S3_PREFIX_ASSETS         = "unimess/pimcore/assets"
    S3_PREFIX_THUMBNAILS     = "unimess/pimcore/thumbnails"
    S3_PREFIX_VERSIONS       = "opendxp/production/private"
  }

  # S3 object storage (credentials are in secrets.auto.tfvars). cdn_domain "" => public
  # files are served from the bucket endpoint; set it to a CDN host to front them.
  # Objects land under the auto "production/" in-bucket prefix (path_prefix defaults to
  # "<env>/"), so staging can share these same buckets. Set path_prefix = "" for root.
  s3 = {
    bucket_private = "unimess"
    bucket_public  = "unimess"
    region         = "nbg1"
    endpoint       = "https://nbg1.your-objectstorage.com"
    cdn_domain     = "https://nbg1.your-objectstorage.com/unimess"
    path_prefix    = "opendxp/production"
  }
}

# Env-agnostic ops/maintenance sidecar image, built + published by its own standalone repo
# (github.com/vanwittlaer/opendxp-ops-shell). One tag serves both environments; pin a
# released vX.Y.Z tag here for production instead of "latest" once the repo cuts a release.
backup_image     = "ghcr.io/vanwittlaer/opendxp-ops-shell"
backup_image_tag = "v1.1.1"
