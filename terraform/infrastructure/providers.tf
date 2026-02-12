terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = ">= 2.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
  backend "s3" {
    key    = "scaleway/terraform.tfstate"
    region = "fr-par"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true

    endpoints = {
      s3 = "https://s3.fr-par.scw.cloud"
    }
    bucket = "obs-terraform-state-prod-0"

    # encrypt      = true
    use_lockfile = true
  }
}

provider "scaleway" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
  project_id = var.project_id
}
