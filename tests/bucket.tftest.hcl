mock_provider "digitalocean" {
  mock_data "digitalocean_project" {
    defaults = {
      id = "mock-project-id"
    }
  }
}

mock_provider "google" {}
mock_provider "aws" {}

variables {
  do_token          = "mock-token"
  spaces_access_id  = "mock-access-id"
  spaces_secret_key = "mock-secret-key"
  bucket_name       = "my-bucket"
  region            = "nyc3"
  do_project        = "my-project"
}

run "defaults" {
  command = plan

  assert {
    condition     = digitalocean_spaces_bucket.bucket.name == "my-bucket-nyc3"
    error_message = "Bucket name must be '{bucket_name}-{region}'."
  }

  assert {
    condition     = digitalocean_spaces_bucket.bucket.region == "nyc3"
    error_message = "Bucket region must match var.region."
  }

  assert {
    condition     = digitalocean_spaces_bucket.bucket.acl == "private"
    error_message = "Default ACL must be 'private'."
  }

  assert {
    condition     = digitalocean_spaces_bucket.bucket.force_destroy == false
    error_message = "Default force_destroy must be false."
  }

  assert {
    condition     = digitalocean_spaces_bucket.bucket.versioning[0].enabled == false
    error_message = "Versioning must be disabled by default."
  }

  assert {
    condition     = length(digitalocean_spaces_bucket_logging.logging) == 0
    error_message = "No logging resource should be created without logging_bucket."
  }

  assert {
    condition     = length(digitalocean_spaces_key.access_keys) == 0
    error_message = "No access keys should be created by default."
  }

  assert {
    condition     = length(google_secret_manager_regional_secret.secret) == 0
    error_message = "No GCP regional secrets should be created by default."
  }

  assert {
    condition     = length(aws_secretsmanager_secret.secret) == 0
    error_message = "No AWS secrets should be created by default."
  }
}

run "public_acl" {
  command = plan

  variables {
    acl = "public-read"
  }

  assert {
    condition     = digitalocean_spaces_bucket.bucket.acl == "public-read"
    error_message = "ACL should be set to 'public-read'."
  }
}

run "versioning_enabled" {
  command = plan

  variables {
    versioning = true
  }

  assert {
    condition     = digitalocean_spaces_bucket.bucket.versioning[0].enabled == true
    error_message = "Versioning should be enabled when var.versioning = true."
  }
}

run "force_destroy_enabled" {
  command = plan

  variables {
    force_destroy = true
  }

  assert {
    condition     = digitalocean_spaces_bucket.bucket.force_destroy == true
    error_message = "force_destroy should be true when var.force_destroy = true."
  }
}

run "logging_bucket" {
  command = plan

  variables {
    logging_bucket = {
      target_bucket = "logs-bucket"
      target_prefix = "my-bucket/"
    }
  }

  assert {
    condition     = length(digitalocean_spaces_bucket_logging.logging) == 1
    error_message = "Logging resource should be created when logging_bucket is set."
  }

  assert {
    condition     = digitalocean_spaces_bucket_logging.logging[0].target_bucket == "logs-bucket"
    error_message = "Logging target_bucket should match var.logging_bucket.target_bucket."
  }

  assert {
    condition     = digitalocean_spaces_bucket_logging.logging[0].target_prefix == "my-bucket/"
    error_message = "Logging target_prefix should match var.logging_bucket.target_prefix."
  }
}

run "single_lifecycle_rule" {
  command = plan

  variables {
    lifecycle_rules = [
      {
        id              = "expire-old"
        prefix          = "logs/"
        enabled         = true
        expiration_days = 90
      }
    ]
  }

  assert {
    condition     = length(digitalocean_spaces_bucket.bucket.lifecycle_rule) == 1
    error_message = "One lifecycle rule should be created."
  }

  assert {
    condition     = digitalocean_spaces_bucket.bucket.lifecycle_rule[0].id == "expire-old"
    error_message = "Lifecycle rule id should match."
  }

  assert {
    condition     = digitalocean_spaces_bucket.bucket.lifecycle_rule[0].enabled == true
    error_message = "Lifecycle rule should be enabled."
  }

  assert {
    condition     = anytrue([for e in digitalocean_spaces_bucket.bucket.lifecycle_rule[0].expiration : e.days == 90])
    error_message = "Expiration days should be 90."
  }
}

run "disabled_lifecycle_rule" {
  command = plan

  variables {
    lifecycle_rules = [
      {
        id      = "cleanup"
        enabled = false
      }
    ]
  }

  assert {
    condition     = digitalocean_spaces_bucket.bucket.lifecycle_rule[0].enabled == false
    error_message = "Lifecycle rule should honour enabled = false."
  }
}

run "multiple_lifecycle_rules" {
  command = plan

  variables {
    lifecycle_rules = [
      {
        id              = "rule-a"
        enabled         = true
        expiration_days = 30
      },
      {
        id                                     = "rule-b"
        enabled                                = true
        noncurrent_version_expiration_days     = 7
        abort_incomplete_multipart_upload_days = 3
      }
    ]
  }

  assert {
    condition     = length(digitalocean_spaces_bucket.bucket.lifecycle_rule) == 2
    error_message = "Two lifecycle rules should be created."
  }
}
