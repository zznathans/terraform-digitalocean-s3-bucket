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

run "invalid_acl_rejected" {
  command = plan

  variables {
    acl = "public"
  }

  expect_failures = [var.acl]
}

run "invalid_access_key_permission_rejected" {
  command = plan

  variables {
    access_keys = [
      { name = "bad-key", permission = "write" }
    ]
  }

  expect_failures = [var.access_keys]
}
