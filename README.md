# terraform/s3-bucket

Terraform configuration for a [DigitalOcean Spaces](https://docs.digitalocean.com/products/spaces/) bucket with optional versioning, lifecycle rules, access logging, access key management, and GCP Secret Manager integration.

## Requirements

| Name | Version |
|------|---------|
| [digitalocean](https://registry.terraform.io/providers/digitalocean/digitalocean/latest) | `~> 2.0` |
| [google](https://registry.terraform.io/providers/hashicorp/google/latest) | (any) |

## Usage

```hcl
module "my_bucket" {
  source = "./s3-bucket"

  do_token          = var.do_token
  SPACES_ACCESS_ID  = var.SPACES_ACCESS_ID
  SPACES_SECRET_KEY = var.SPACES_SECRET_KEY

  project     = "my-project"
  bucket_name = "my-app"
  region      = "nyc3"
  acl         = "private"
  versioning  = true
  tags        = ["production", "app"]

  # Optional: lifecycle rules
  lifecycle_rules = [
    {
      id                                     = "expire-logs"
      prefix                                 = "logs/"
      enabled                                = true
      expiration_days                        = 90
      noncurrent_version_expiration_days     = 30
      abort_incomplete_multipart_upload_days = 7
    }
  ]

  # Optional: access logging (omit to disable)
  logging_bucket = {
    region        = "nyc3"
    bucket        = "my-app-nyc3"
    target_bucket = "my-logs-bucket"
    target_prefix = "access-logs/"
  }

  # Optional: access keys (omit or set to [] to skip)
  access_keys = [
    {
      name       = "ci-reader"
      permission = "read"
    },
    {
      name       = "app-readwrite"
      permission = "readwrite"
    }
  ]

  # Optional: push each access key as a GCP Secret Manager secret
  push_gcp_secret = true
  gcp_region      = "us-central1"
}
```

## Variables

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `do_token` | `string` | — | yes | DigitalOcean API token |
| `SPACES_ACCESS_ID` | `string` | — | yes | Spaces access key ID |
| `SPACES_SECRET_KEY` | `string` | — | yes | Spaces secret key |
| `project` | `string` | — | yes | DigitalOcean project name to look up |
| `bucket_name` | `string` | — | yes | Base name of the bucket (region is appended automatically) |
| `region` | `string` | — | yes | DigitalOcean region slug (e.g. `nyc3`, `ams3`) |
| `acl` | `string` | `"private"` | no | Canned ACL: `private` or `public-read` |
| `versioning` | `bool` | — | yes | Enable object versioning |
| `tags` | `list(string)` | — | yes | Tags to apply to associated resources |
| `lifecycle_rules` | `list(object)` | `[]` | no | List of lifecycle rules (see below) |
| `logging_bucket` | `object` | `null` | no | Access log target config (omit to disable logging) |
| `access_keys` | `list(object)` | `[]` | no | Bucket-scoped access keys to create |
| `push_gcp_secret` | `bool` | `false` | no | When `true`, create a GCP Secret Manager secret for each access key |
| `gcp_region` | `string` | `null` | no | GCP region for Secret Manager regional secrets (required if `push_gcp_secret = true`) |

### `lifecycle_rules` object

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `id` | `string` | — | Unique rule identifier |
| `prefix` | `string` | `""` | Object key prefix the rule applies to |
| `enabled` | `bool` | — | Set `false` to disable without removing the rule |
| `expiration_days` | `number` | `null` | Expire current versions after N days |
| `noncurrent_version_expiration_days` | `number` | `null` | Expire non-current versions after N days |
| `abort_incomplete_multipart_upload_days` | `number` | `null` | Abort incomplete multipart uploads after N days |

### `logging_bucket` object

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `region` | `string` | — | Region of the logging target bucket |
| `bucket` | `string` | — | Source bucket name |
| `target_bucket` | `string` | — | Bucket to write access logs into |
| `target_prefix` | `string` | `"access-logs/"` | Key prefix for log objects |

### `access_keys` object

| Field | Type | Description |
|-------|------|-------------|
| `name` | `string` | Name for the access key |
| `permission` | `string` | `read` or `readwrite` |

## GCP Secret Manager integration

When `push_gcp_secret = true`, a `google_secret_manager_regional_secret` and corresponding secret version are created for **each** access key. Secrets are named `{bucket_name}-{region}-{key_name}`.

Each secret version stores a JSON payload:

```json
{
  "access_key":  "<spaces key id>",
  "secret_key":  "<spaces secret>",
  "bucket_name": "<bucket name>",
  "endpoint":    "https://<region>.digitaloceanspaces.com"
}
```

This structure is compatible with [External Secrets Operator](https://external-secrets.io/) — individual fields can be extracted via a `SecretStore` `remoteRef` with a `property` selector.

## Resources

| Resource | Description |
|----------|-------------|
| `digitalocean_spaces_bucket.bucket` | The Spaces bucket |
| `digitalocean_spaces_bucket_logging.logging` | Access log shipping (created only when `logging_bucket` is set) |
| `digitalocean_spaces_key.access_keys` | Bucket-scoped access keys (one per entry in `access_keys`) |
| `google_secret_manager_regional_secret.secret` | GCP secret per access key (created only when `push_gcp_secret = true`) |
| `google_secret_manager_regional_secret_version.secret` | Secret version holding credentials JSON (created only when `push_gcp_secret = true`) |
| `data.digitalocean_project.project` | Looks up the DigitalOcean project by name |

- [ ] [Set up protected environments](https://docs.gitlab.com/ee/ci/environments/protected_environments.html)
