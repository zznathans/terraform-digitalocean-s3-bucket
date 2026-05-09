variable "do_token" {
    type = string
}

variable "SPACES_ACCESS_ID" {
    type = string
}

variable "SPACES_SECRET_KEY" {
    type = string
}

variable "do_project" {
    type        = string
    description = "DigitalOcean project name"
}

variable "gcp_project" {
    type        = string
    default     = null
    description = "GCP project ID (required if push_gcp_secret = true)"
}

variable "tags" {
    type = list(string)
}

variable "bucket_name" {
    type = string
}

variable "region" {
    type = string
}

variable "acl" {
    type = string
    default = "private"
}

variable "versioning" {
    type = bool
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
      region        = string
      bucket        = string
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

variable "push_gcp_secret" {
    type = bool
    default = false
}

variable "gcp_region" {
    type = string
    default = null
}

