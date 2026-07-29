# CORS on the public asset buckets. The storefront (var.*.web_domain) loads theme
# assets from the S3 origin; browsers require CORS for fonts (.woff2), so without
# this the fonts are blocked cross-origin. Managed via the aws providers pointed
# at Hetzner Object Storage (providers.tf). The private buckets need no CORS.
resource "aws_s3_bucket_cors_configuration" "public_production" {
  provider = aws.production
  bucket   = var.production.s3.bucket_public

  cors_rule {
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = [var.production.web_domain]
    allowed_headers = ["*"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket_cors_configuration" "public_staging" {
  count    = var.enable_staging ? 1 : 0
  provider = aws.staging
  bucket   = var.staging.s3.bucket_public

  cors_rule {
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = [var.staging.web_domain]
    allowed_headers = ["*"]
    max_age_seconds = 3600
  }
}
