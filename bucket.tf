resource "digitalocean_spaces_bucket" "bucket" {
  name   = "${var.environment}-${var.region}-${var.name}"
  region = var.region
  force_destroy = var.force_destroy

  lifecycle_rule {
    id = "expiration"
    enabled = true
    abort_incomplete_multipart_upload_days = 3
    expiration {
        days = var.expiration
    }
  }
}
