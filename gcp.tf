resource "google_secret_manager_regional_secret" "secret" {
  for_each = var.push_gcp_secret ? { for k in var.access_keys : k.name => k } : {}

  project   = var.gcp_project
  location  = var.gcp_region
  secret_id = "${var.bucket_name}-${var.region}-${each.key}"

  labels = {
    managed-by = "terraform"
    app        = "${var.bucket_name}-${var.region}-s3-credentials"
  }
}

resource "google_secret_manager_regional_secret_version" "secret" {
  for_each = var.push_gcp_secret ? { for k in var.access_keys : k.name => k } : {}

  secret = google_secret_manager_regional_secret.secret[each.key].id

  # Secret data is a JSON object so ESO can extract individual fields via
  # a SecretStore remoteRef with property: access_key / secret_key
  secret_data = jsonencode({
    access_key  = base64encode(digitalocean_spaces_key.access_keys[each.key].access_key)
    secret_key  = base64encode(digitalocean_spaces_key.access_keys[each.key].secret_key)
    bucket_name = digitalocean_spaces_bucket.bucket.name
    endpoint    = "https://${var.region}.digitaloceanspaces.com"
  })
}
