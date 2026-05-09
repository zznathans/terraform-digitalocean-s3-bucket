locals {
  gcp_keys = var.push_gcp_secret ? { for k in var.access_keys : k.name => k } : {}

  gcp_secret_payload = {
    for name, k in local.gcp_keys : name => jsonencode({
      access_key  = base64encode(digitalocean_spaces_key.access_keys[name].access_key)
      secret_key  = base64encode(digitalocean_spaces_key.access_keys[name].secret_key)
      bucket_name = digitalocean_spaces_bucket.bucket.name
      endpoint    = "https://${var.region}.digitaloceanspaces.com"
    })
  }
}

# Regional secrets

resource "google_secret_manager_regional_secret" "secret" {
  for_each = var.gcp_secret_regional ? local.gcp_keys : {}

  project   = var.gcp_project
  location  = var.gcp_region
  secret_id = "${var.bucket_name}-${var.region}-${each.key}"

  labels = merge(var.tags, {
    managed-by = "terraform"
    app        = "${var.bucket_name}-${var.region}-s3-credentials"
  })
}

resource "google_secret_manager_regional_secret_version" "secret" {
  for_each = var.gcp_secret_regional ? local.gcp_keys : {}

  secret      = google_secret_manager_regional_secret.secret[each.key].id
  secret_data = local.gcp_secret_payload[each.key]
}

# Global secrets with replication policy

resource "google_secret_manager_secret" "secret" {
  for_each = !var.gcp_secret_regional ? local.gcp_keys : {}

  project   = var.gcp_project
  secret_id = "${var.bucket_name}-${var.region}-${each.key}"

  replication {
    dynamic "auto" {
      for_each = var.gcp_replication.automatic ? [1] : []
      content {}
    }

    dynamic "user_managed" {
      for_each = !var.gcp_replication.automatic ? [1] : []
      content {
        dynamic "replicas" {
          for_each = var.gcp_replication.locations
          content {
            location = replicas.value
          }
        }
      }
    }
  }

  labels = merge(var.tags, {
    managed-by = "terraform"
    app        = "${var.bucket_name}-${var.region}-s3-credentials"
  })
}

resource "google_secret_manager_secret_version" "secret" {
  for_each = !var.gcp_secret_regional ? local.gcp_keys : {}

  secret      = google_secret_manager_secret.secret[each.key].id
  secret_data = local.gcp_secret_payload[each.key]
}
