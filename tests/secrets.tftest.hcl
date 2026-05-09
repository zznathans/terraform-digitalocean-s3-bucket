mock_provider "digitalocean" {
  mock_data "digitalocean_project" {
    defaults = {
      id = "mock-project-id"
    }
  }

  mock_resource "digitalocean_spaces_key" {
    defaults = {
      access_key = "MOCK_ACCESS_KEY"
      secret_key = "MOCK_SECRET_KEY"
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
  access_keys = [
    { name = "app-key", permission = "readwrite" }
  ]
}

# GCP - regional secrets (default)

run "gcp_regional_secret_created" {
  command = plan

  variables {
    push_gcp_secret = true
    gcp_project     = "my-gcp-project"
    gcp_region      = "us-central1"
  }

  assert {
    condition     = length(google_secret_manager_regional_secret.secret) == 1
    error_message = "One regional secret should be created per access key."
  }

  assert {
    condition     = google_secret_manager_regional_secret.secret["app-key"].secret_id == "my-bucket-nyc3-app-key"
    error_message = "Regional secret ID should be '{bucket_name}-{region}-{key_name}'."
  }

  assert {
    condition     = google_secret_manager_regional_secret.secret["app-key"].project == "my-gcp-project"
    error_message = "Regional secret project should match var.gcp_project."
  }

  assert {
    condition     = google_secret_manager_regional_secret.secret["app-key"].location == "us-central1"
    error_message = "Regional secret location should match var.gcp_region."
  }

  assert {
    condition     = length(google_secret_manager_secret.secret) == 0
    error_message = "No global secrets should be created when gcp_secret_regional = true."
  }
}

run "gcp_regional_secret_labels" {
  command = plan

  variables {
    push_gcp_secret = true
    gcp_project     = "my-gcp-project"
    gcp_region      = "us-central1"
    tags            = { environment = "prod" }
  }

  assert {
    condition     = google_secret_manager_regional_secret.secret["app-key"].labels["managed-by"] == "terraform"
    error_message = "Secret label 'managed-by' should be 'terraform'."
  }

  assert {
    condition     = google_secret_manager_regional_secret.secret["app-key"].labels["environment"] == "prod"
    error_message = "Tags should be merged into secret labels."
  }
}

# GCP - global secrets

run "gcp_global_secret_auto_replication" {
  command = plan

  variables {
    push_gcp_secret     = true
    gcp_project         = "my-gcp-project"
    gcp_secret_regional = false
    gcp_replication     = { automatic = true, locations = [] }
  }

  assert {
    condition     = length(google_secret_manager_secret.secret) == 1
    error_message = "One global secret should be created."
  }

  assert {
    condition     = length(google_secret_manager_regional_secret.secret) == 0
    error_message = "No regional secrets should be created when gcp_secret_regional = false."
  }

  assert {
    condition     = google_secret_manager_secret.secret["app-key"].secret_id == "my-bucket-nyc3-app-key"
    error_message = "Global secret ID should be '{bucket_name}-{region}-{key_name}'."
  }
}

run "gcp_no_secrets_without_access_keys" {
  command = plan

  variables {
    push_gcp_secret = true
    gcp_project     = "my-gcp-project"
    gcp_region      = "us-central1"
    access_keys     = []
  }

  assert {
    condition     = length(google_secret_manager_regional_secret.secret) == 0
    error_message = "No GCP secrets should be created when access_keys is empty."
  }
}

# AWS secrets

run "aws_secret_created" {
  command = plan

  variables {
    push_aws_secret = true
    aws_region      = "us-east-1"
  }

  assert {
    condition     = length(aws_secretsmanager_secret.secret) == 1
    error_message = "One AWS secret should be created per access key."
  }

  assert {
    condition     = aws_secretsmanager_secret.secret["app-key"].name == "my-bucket-nyc3-app-key"
    error_message = "AWS secret name should be '{bucket_name}-{region}-{key_name}'."
  }
}

run "aws_secret_tags" {
  command = plan

  variables {
    push_aws_secret = true
    aws_region      = "us-east-1"
    tags            = { environment = "prod" }
  }

  assert {
    condition     = aws_secretsmanager_secret.secret["app-key"].tags["managed-by"] == "terraform"
    error_message = "Secret tag 'managed-by' should be 'terraform'."
  }

  assert {
    condition     = aws_secretsmanager_secret.secret["app-key"].tags["environment"] == "prod"
    error_message = "Tags should be merged into secret tags."
  }
}

run "aws_secret_with_replica" {
  command = plan

  variables {
    push_aws_secret = true
    aws_region      = "us-east-1"
    aws_replicas = [
      { region = "us-west-2" }
    ]
  }

  assert {
    condition     = length(aws_secretsmanager_secret.secret["app-key"].replica) == 1
    error_message = "One replica should be configured."
  }

  assert {
    condition     = anytrue([for r in aws_secretsmanager_secret.secret["app-key"].replica : r.region == "us-west-2"])
    error_message = "Replica region should match var.aws_replicas."
  }
}

run "aws_no_secrets_without_access_keys" {
  command = plan

  variables {
    push_aws_secret = true
    aws_region      = "us-east-1"
    access_keys     = []
  }

  assert {
    condition     = length(aws_secretsmanager_secret.secret) == 0
    error_message = "No AWS secrets should be created when access_keys is empty."
  }
}

run "aws_no_secrets_when_disabled" {
  command = plan

  variables {
    push_aws_secret = false
  }

  assert {
    condition     = length(aws_secretsmanager_secret.secret) == 0
    error_message = "No AWS secrets should be created when push_aws_secret = false."
  }
}
