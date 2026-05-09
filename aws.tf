resource "aws_secretsmanager_secret" "secret" {
  for_each = var.push_aws_secret ? { for k in var.access_keys : k.name => k } : {}

  name        = "${var.bucket_name}-${var.region}-${each.key}"
  description = "DigitalOcean Spaces credentials for ${var.bucket_name}-${var.region}-${each.key}"

  dynamic "replica" {
    for_each = var.aws_replicas
    content {
      region     = replica.value.region
      kms_key_id = replica.value.kms_key_id
    }
  }

  tags = {
    managed-by = "terraform"
    app        = "${var.bucket_name}-${var.region}-s3-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "secret" {
  for_each = var.push_aws_secret ? { for k in var.access_keys : k.name => k } : {}

  secret_id = aws_secretsmanager_secret.secret[each.key].id

  secret_string = jsonencode({
    access_key  = base64encode(digitalocean_spaces_key.access_keys[each.key].access_key)
    secret_key  = base64encode(digitalocean_spaces_key.access_keys[each.key].secret_key)
    bucket_name = digitalocean_spaces_bucket.bucket.name
    endpoint    = "https://${var.region}.digitaloceanspaces.com"
  })
}
