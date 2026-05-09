variable "do_token" {
  type = string
}

variable "spaces_access_id" {
  type = string
}

variable "spaces_secret_key" {
  type = string
}

variable "do_project" {
  type        = string
  description = "DigitalOcean project name"
}

variable "bucket_name" {
  type = string
}

variable "region" {
  type = string
}

variable "acl" {
  type    = string
  default = "private"

  validation {
    condition     = contains(["private", "public-read"], var.acl)
    error_message = "acl must be \"private\" or \"public-read\"."
  }
}

variable "versioning" {
  type    = bool
  default = false
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "lifecycle_rules" {
  type = list(object({
    id                                     = string
    prefix                                 = optional(string, "")
    enabled                                = bool
    expiration_days                        = optional(number, null)
    noncurrent_version_expiration_days     = optional(number, null)
    abort_incomplete_multipart_upload_days = optional(number, null)
  }))
  default     = []
  description = "List of lifecycle rules. Set enabled = false on a rule to disable it without removing it."
}

variable "logging_bucket" {
  type = object({
    target_bucket = string
    target_prefix = optional(string, "access-logs/")
  })
  default = null
}

variable "access_keys" {
  type = list(object({
    name       = string
    permission = string
  }))
  default = []

  validation {
    condition     = alltrue([for k in var.access_keys : contains(["read", "readwrite"], k.permission)])
    error_message = "Each access key permission must be \"read\" or \"readwrite\"."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to merge into all supported resources. Applied as labels on GCP secrets and tags on AWS secrets. GCP requires lowercase keys and values."
}

variable "push_gcp_secret" {
  type    = bool
  default = false
}

variable "gcp_project" {
  type        = string
  default     = null
  description = "GCP project ID (required if push_gcp_secret = true)"
}

variable "gcp_secret_regional" {
  type        = bool
  default     = true
  description = "When true, create a regional secret (requires gcp_region). When false, create a global secret with replication policy (requires gcp_replication)."
}

variable "gcp_region" {
  type        = string
  default     = null
  description = "GCP region for Secret Manager (required if push_gcp_secret = true and gcp_secret_regional = true)"
}

variable "gcp_replication" {
  type = object({
    automatic = optional(bool, true)
    locations = optional(list(string), [])
  })
  default     = { automatic = true, locations = [] }
  description = "Replication policy for global GCP secrets (used when push_gcp_secret = true and gcp_secret_regional = false). Set automatic = true for automatic replication, or provide a locations list for user-managed replication."
}

variable "push_aws_secret" {
  type    = bool
  default = false
}

variable "aws_region" {
  type        = string
  default     = null
  description = "AWS region for Secrets Manager (required if push_aws_secret = true)"
}

variable "aws_replicas" {
  type = list(object({
    region     = string
    kms_key_id = optional(string, null)
  }))
  default     = []
  description = "Regions to replicate each AWS secret into. Each entry requires a region; kms_key_id is optional (defaults to aws/secretsmanager in that region)."
}
