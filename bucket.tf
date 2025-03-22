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

data "digitalocean_project" "my_project" {
  name = var.project
}

resource "digitalocean_project_resources" "assoc" {
  project = data.digitalocean_project.my_project.id
  resources = [
    digitalocean_spaces_bucket.bucket.urn
  ]
}