resource "digitalocean_spaces_bucket" "bucket" {
  name   = "${var.bucket_name}-${var.region}"
  region = var.region
  acl    = var.acl

  versioning {
    enabled = var.versioning
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      id      = lifecycle_rule.value.id
      prefix  = lifecycle_rule.value.prefix
      enabled = lifecycle_rule.value.enabled

      dynamic "expiration" {
        for_each = lifecycle_rule.value.expiration_days != null ? [lifecycle_rule.value.expiration_days] : []
        content {
          days = expiration.value
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = lifecycle_rule.value.noncurrent_version_expiration_days != null ? [lifecycle_rule.value.noncurrent_version_expiration_days] : []
        content {
          days = noncurrent_version_expiration.value
        }
      }

      abort_incomplete_multipart_upload_days = lifecycle_rule.value.abort_incomplete_multipart_upload_days
    }
  }
}

resource "digitalocean_spaces_bucket_logging" "logging" {
  count = var.logging_bucket != null ? 1 : 0

  bucket        = digitalocean_spaces_bucket.bucket.name
  target_bucket = var.logging_bucket.target_bucket
  target_prefix = var.logging_bucket.target_prefix
  region        = var.logging_bucket.region
}

resource "digitalocean_spaces_key" "access_keys" {
  for_each = { for k in var.access_keys : k.name => k }

  name = each.value.name

  grant {
    bucket     = digitalocean_spaces_bucket.bucket.name
    permission = each.value.permission
  }
}