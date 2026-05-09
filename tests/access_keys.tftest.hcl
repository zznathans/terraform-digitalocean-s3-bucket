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

run "single_readwrite_key" {
  command = plan

  variables {
    access_keys = [
      { name = "app-key", permission = "readwrite" }
    ]
  }

  assert {
    condition     = length(digitalocean_spaces_key.access_keys) == 1
    error_message = "One access key should be created."
  }

  assert {
    condition     = digitalocean_spaces_key.access_keys["app-key"].name == "app-key"
    error_message = "Access key name should match."
  }

  assert {
    condition     = digitalocean_spaces_key.access_keys["app-key"].grant[0].permission == "readwrite"
    error_message = "Access key permission should be 'readwrite'."
  }

  assert {
    condition     = digitalocean_spaces_key.access_keys["app-key"].grant[0].bucket == "my-bucket-nyc3"
    error_message = "Access key grant should reference the bucket."
  }
}

run "single_read_key" {
  command = plan

  variables {
    access_keys = [
      { name = "reader", permission = "read" }
    ]
  }

  assert {
    condition     = digitalocean_spaces_key.access_keys["reader"].grant[0].permission == "read"
    error_message = "Access key permission should be 'read'."
  }
}

run "multiple_keys" {
  command = plan

  variables {
    access_keys = [
      { name = "writer", permission = "readwrite" },
      { name = "reader", permission = "read" }
    ]
  }

  assert {
    condition     = length(digitalocean_spaces_key.access_keys) == 2
    error_message = "Two access keys should be created."
  }

  assert {
    condition     = digitalocean_spaces_key.access_keys["writer"].grant[0].permission == "readwrite"
    error_message = "Writer key should have readwrite permission."
  }

  assert {
    condition     = digitalocean_spaces_key.access_keys["reader"].grant[0].permission == "read"
    error_message = "Reader key should have read permission."
  }
}
