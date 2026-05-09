# terraform/s3-bucket

Terraform configuration for a [DigitalOcean Spaces](https://docs.digitalocean.com/products/spaces/) bucket with optional versioning, lifecycle rules, access logging, access key management, and secret manager integration (GCP and/or AWS).

## Requirements

| Name | Version |
|------|---------|
| Terraform / OpenTofu | `>= 1.3.0` |
| [digitalocean](https://registry.terraform.io/providers/digitalocean/digitalocean/latest) | `~> 2.0` |
| [google](https://registry.terraform.io/providers/hashicorp/google/latest) | `>= 4.0` — only if `push_gcp_secret = true` |
| [aws](https://registry.terraform.io/providers/hashicorp/aws/latest) | `>= 5.0` — only if `push_aws_secret = true` |

> **Note:** The `google` and `aws` providers are always listed in `required_providers`, so Terraform will initialise them even when the corresponding feature flags are `false`. Configure provider credentials in the root module; unconfigured providers will produce an initialisation warning but will not cause failures when the feature flag is disabled.

## Usage

```hcl
module "my_bucket" {
  source = "./s3-bucket"

  do_token          = var.do_token
  spaces_access_id  = var.spaces_access_id
  spaces_secret_key = var.spaces_secret_key

  do_project  = "my-project"
  bucket_name = "my-app"
  region      = "nyc3"
  acl         = "private"
  versioning  = true

  # Optional: allow destroying non-empty bucket (e.g. in dev environments)
  force_destroy = false

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

  # Optional: push each access key to GCP Secret Manager (regional secret)
  push_gcp_secret     = true
  gcp_project         = "my-gcp-project-id"
  gcp_secret_regional = true
  gcp_region          = "us-central1"

  # Optional: push each access key to GCP Secret Manager (global secret, automatic replication)
  # push_gcp_secret     = true
  # gcp_project         = "my-gcp-project-id"
  # gcp_secret_regional = false
  # gcp_replication     = { automatic = true }

  # Optional: push each access key to GCP Secret Manager (global secret, user-managed replication)
  # push_gcp_secret     = true
  # gcp_project         = "my-gcp-project-id"
  # gcp_secret_regional = false
  # gcp_replication     = { automatic = false, locations = ["us-central1", "us-east1"] }

  # Optional: push each access key to AWS Secrets Manager
  push_aws_secret = true
  aws_region      = "us-east-1"
}
```

## Variables

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `do_token` | `string` | — | yes | DigitalOcean API token |
| `spaces_access_id` | `string` | — | yes | Spaces access key ID |
| `spaces_secret_key` | `string` | — | yes | Spaces secret key |
| `do_project` | `string` | — | yes | DigitalOcean project name to look up |
| `bucket_name` | `string` | — | yes | Base name of the bucket (region is appended automatically) |
| `region` | `string` | — | yes | DigitalOcean region slug (e.g. `nyc3`, `ams3`) |
| `acl` | `string` | `"private"` | no | Canned ACL: `private` or `public-read` |
| `versioning` | `bool` | `false` | no | Enable object versioning |
| `force_destroy` | `bool` | `false` | no | Allow destroying the bucket even when it contains objects |
| `lifecycle_rules` | `list(object)` | `[]` | no | List of lifecycle rules (see below) |
| `logging_bucket` | `object` | `null` | no | Access log target config (omit to disable logging) |
| `access_keys` | `list(object)` | `[]` | no | Bucket-scoped access keys to create |
| `push_gcp_secret` | `bool` | `false` | no | When `true`, create a GCP Secret Manager secret for each access key |
| `gcp_project` | `string` | `null` | no | GCP project ID (required if `push_gcp_secret = true`) |
| `gcp_secret_regional` | `bool` | `true` | no | `true` = regional secret (requires `gcp_region`); `false` = global secret (requires `gcp_replication`) |
| `gcp_region` | `string` | `null` | no | GCP region (required if `push_gcp_secret = true` and `gcp_secret_regional = true`) |
| `gcp_replication` | `object` | `{automatic=true, locations=[]}` | no | Replication policy for global GCP secrets (used when `gcp_secret_regional = false`) |
| `push_aws_secret` | `bool` | `false` | no | When `true`, create an AWS Secrets Manager secret for each access key |
| `aws_region` | `string` | `null` | no | AWS region for Secrets Manager (required if `push_aws_secret = true`) |

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
| `target_bucket` | `string` | — | Bucket to write access logs into |
| `target_prefix` | `string` | `"access-logs/"` | Key prefix for log objects |

### `access_keys` object

| Field | Type | Description |
|-------|------|-------------|
| `name` | `string` | Name for the access key |
| `permission` | `string` | `read` or `readwrite` |

### `gcp_replication` object

Only used when `push_gcp_secret = true` and `gcp_secret_regional = false`.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `automatic` | `bool` | `true` | When `true`, use automatic replication (Google-managed). When `false`, replicate to specific `locations`. |
| `locations` | `list(string)` | `[]` | GCP regions to replicate into (e.g. `["us-central1", "us-east1"]`). Only used when `automatic = false`. |

## CI/CD

The following environment variables must be available to the CI runner:

| Variable | Required | Description |
|----------|----------|-------------|
| `ACCESS_KEY` | yes | DigitalOcean Spaces access key ID, base64-encoded |
| `SECRET_KEY` | yes | DigitalOcean Spaces secret key, base64-encoded |
| `DO_API_KEY` | yes | DigitalOcean API token, base64-encoded |
| `GCP_CREDS` | if `push_gcp_secret = true` | Path to a GCP service account credentials JSON file |

Before running OpenTofu, decode the base64 values and export them as `TF_VAR_*` variables:

```sh
export TF_VAR_do_token=$(echo $DO_API_KEY | base64 -d)
export TF_VAR_spaces_access_id=$(echo $ACCESS_KEY | base64 -d)
export TF_VAR_spaces_secret_key=$(echo $SECRET_KEY | base64 -d)
export GOOGLE_APPLICATION_CREDENTIALS=$GCP_CREDS
```

`GCP_CREDS` is only required when `push_gcp_secret = true`. The GCP service account must have the `roles/secretmanager.admin` role (or equivalent) on the target project.

## GCP Secret Manager

When `push_gcp_secret = true`, a secret is created for **each** access key, named `{bucket_name}-{region}-{key_name}`. The GCP service account must have `roles/secretmanager.admin` on `gcp_project`.

### Secret payload

The `access_key` and `secret_key` values are **base64-encoded**. `bucket_name` and `endpoint` are stored as plaintext.

```json
{
  "access_key":  "<base64-encoded spaces key id>",
  "secret_key":  "<base64-encoded spaces secret>",
  "bucket_name": "<bucket name>",
  "endpoint":    "https://<region>.digitaloceanspaces.com"
}
```

This structure is compatible with [External Secrets Operator](https://external-secrets.io/) — individual fields can be extracted via a `SecretStore` `remoteRef` with a `property` selector.

### Regional vs global secrets

Set `gcp_secret_regional = true` (default) to create a **regional secret** pinned to `gcp_region`.

Set `gcp_secret_regional = false` to create a **global secret** with a replication policy controlled by `gcp_replication`:
- `{ automatic = true }` — Google-managed automatic replication (recommended for most use cases).
- `{ automatic = false, locations = ["us-central1", "us-east1"] }` — user-managed replication to specific regions.

## AWS Secrets Manager

When `push_aws_secret = true`, a secret is created for **each** access key in the region specified by `aws_region`, named `{bucket_name}-{region}-{key_name}`.

### Secret payload

The `access_key` and `secret_key` values are **base64-encoded**. `bucket_name` and `endpoint` are stored as plaintext.

```json
{
  "access_key":  "<base64-encoded spaces key id>",
  "secret_key":  "<base64-encoded spaces secret>",
  "bucket_name": "<bucket name>",
  "endpoint":    "https://<region>.digitaloceanspaces.com"
}
```

The AWS credentials used must have `secretsmanager:CreateSecret`, `secretsmanager:PutSecretValue`, and `secretsmanager:TagResource` permissions.

## Resources

| Resource | Description |
|----------|-------------|
| `digitalocean_spaces_bucket.bucket` | The Spaces bucket |
| `digitalocean_spaces_bucket_logging.logging` | Access log shipping (created only when `logging_bucket` is set) |
| `digitalocean_spaces_key.access_keys` | Bucket-scoped access keys (one per entry in `access_keys`) |
| `google_secret_manager_regional_secret.secret` | Regional GCP secret per access key (when `push_gcp_secret = true` and `gcp_secret_regional = true`) |
| `google_secret_manager_regional_secret_version.secret` | Regional secret version (when `push_gcp_secret = true` and `gcp_secret_regional = true`) |
| `google_secret_manager_secret.secret` | Global GCP secret per access key (when `push_gcp_secret = true` and `gcp_secret_regional = false`) |
| `google_secret_manager_secret_version.secret` | Global secret version (when `push_gcp_secret = true` and `gcp_secret_regional = false`) |
| `aws_secretsmanager_secret.secret` | AWS secret per access key (created only when `push_aws_secret = true`) |
| `aws_secretsmanager_secret_version.secret` | Secret version holding credentials JSON (created only when `push_aws_secret = true`) |
| `data.digitalocean_project.project` | Looks up the DigitalOcean project by name |
