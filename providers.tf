terraform {
    required_version = ">= 1.3.0"

    required_providers {
      digitalocean = {
        source  = "digitalocean/digitalocean"
        version = "~> 2.0"
      }
      google = {
        source  = "hashicorp/google"
        version = ">= 4.0"
      }
      aws = {
        source  = "hashicorp/aws"
        version = ">= 5.0"
      }
    }
}
