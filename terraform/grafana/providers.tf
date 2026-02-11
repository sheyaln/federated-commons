terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }
  
  backend "s3" {
    key = "grafana/terraform.tfstate"

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

provider "scaleway" {
  region     = "fr-par"
  access_key = var.scaleway_access_key
  secret_key = var.scaleway_secret_key
}

data "scaleway_secret" "grafana_terraform_api_token" {
  name = "grafana-terraform-api-token"
  path = "/management/grafana"
}

data "scaleway_secret_version" "grafana_terraform_api_token" {
  secret_id = data.scaleway_secret.grafana_terraform_api_token.id
  revision  = "latest"
}

locals {
  grafana_api_token = base64decode(data.scaleway_secret_version.grafana_terraform_api_token.data)
}

provider "grafana" {
  url  = var.grafana_url
  auth = local.grafana_api_token
}
