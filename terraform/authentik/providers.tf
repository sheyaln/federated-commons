terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "~> 2025.12.0"
    }
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    key = "authentik/terraform.tfstate"

    region = "fr-par"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true

    endpoints = {
      s3 = "https://s3.fr-par.scw.cloud"
    }
    bucket = "your-terraform-state-bucket"  # Update to your bucket name

    # encrypt      = true
    use_lockfile = true
  }
}

provider "tls" {}

provider "authentik" {
  url      = "https://${local.gateway_domain}"
  token    = var.authentik_token
  insecure = false
}

provider "scaleway" {
  region     = "fr-par"
  access_key = var.scaleway_access_key
  secret_key = var.scaleway_secret_key
}
