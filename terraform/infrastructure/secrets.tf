
# Secrets Configuration

# Loads secrets from config/secrets.yml and creates them in Scaleway Secret
# Manager using the secrets module.
#
# The secrets.yml file is gitignored - each deployment defines their own.
# See config/secrets.yml.example for the expected format.


locals {
  # Load secrets configuration
  secrets_config_path = "${path.module}/../../config/secrets.yml"
  secrets_config      = fileexists(local.secrets_config_path) ? yamldecode(file(local.secrets_config_path)) : null
}


# Secrets Module


module "secrets" {
  source = "./modules/secrets"
  providers = {
    scaleway = scaleway
    random   = random
  }

  secrets        = try(local.secrets_config.secrets, {})
  project_config = local._config
}


# SCW Secrets IAM - Scoped API Key for Runtime Secret Fetching

# Creates an IAM application with a strictly scoped API key that can ONLY
# read secrets from Scaleway Secret Manager. This key is used by the
# scw-secrets Ansible role to fetch secrets at container runtime.
#
# Security Model:
# - IAM Application: Non-human user with no console access
# - API Key: Scoped to this application only
# - IAM Policy: Limited to SecretManagerReadOnly permission set
# - No ability to modify, delete, or create secrets
# - No access to any other Scaleway resources

resource "scaleway_iam_application" "scw_secrets_reader" {
  name        = "scw-secrets-reader"
  description = "Application for runtime secret fetching on VPS hosts. Read-only access to Secret Manager."
  tags        = ["automated", "secrets", "runtime"]
}

resource "scaleway_iam_policy" "scw_secrets_reader_policy" {
  name           = "scw-secrets-reader-policy"
  description    = "Read-only access to Secret Manager for runtime secret fetching"
  application_id = scaleway_iam_application.scw_secrets_reader.id

  rule {
    project_ids          = [var.project_id]
    permission_set_names = ["SecretManagerReadOnly"]
  }
}

resource "scaleway_iam_api_key" "scw_secrets_reader_key" {
  application_id = scaleway_iam_application.scw_secrets_reader.id
  description    = "API key for scw-secrets service on VPS hosts"
}

# Store the generated API key in Secret Manager for bootstrap
resource "scaleway_secret" "scw_secrets_api_credentials" {
  name        = "scw-secrets-reader-api-credentials"
  description = "Scoped API credentials for runtime secret fetching (read-only)"
  type        = "key_value"
  path        = "/infrastructure"
  tags        = ["automated", "iam", "bootstrap"]
}

resource "scaleway_secret_version" "scw_secrets_api_credentials_version" {
  secret_id = scaleway_secret.scw_secrets_api_credentials.id
  data = jsonencode({
    access_key      = scaleway_iam_api_key.scw_secrets_reader_key.access_key
    secret_key      = scaleway_iam_api_key.scw_secrets_reader_key.secret_key
    organization_id = scaleway_iam_application.scw_secrets_reader.organization_id
  })

  lifecycle {
    prevent_destroy = false # Set to true in production
  }
}


# Server Network Configuration Secret
#
# Stores all server IPs (public and private) in Secret Manager so Ansible
# can look them up at runtime. This avoids hardcoding IPs in config files.

resource "scaleway_secret" "server_network_config" {
  name        = "server-network-config"
  description = "Server IP addresses for inter-server communication and monitoring"
  type        = "opaque"
  path        = "/infrastructure"
  tags        = ["automated", "infrastructure", "network"]
}

resource "scaleway_secret_version" "server_network_config_version" {
  secret_id = scaleway_secret.server_network_config.id
  data = base64encode(jsonencode({
    servers = {
      management = {
        public_ip  = var.create_management ? module.management[0].ip_address : null
        private_ip = var.create_management ? module.management[0].private_ip : null
      }
      tools_prod = {
        public_ip  = module.tools_prod.ip_address
        private_ip = module.tools_prod.private_ip
      }
      authentik = {
        public_ip  = var.create_authentik ? module.authentik_prod.ip_address : null
        private_ip = var.create_authentik ? module.authentik_prod.private_ip : null
      }
      staging = {
        public_ip  = var.create_staging ? module.tools_staging[0].ip_address : null
        private_ip = var.create_staging ? module.tools_staging[0].private_ip : null
      }
    }
  }))

  lifecycle {
    # Replace version when IPs change (instance recreation)
    create_before_destroy = true
  }
}


# # Outputs


# output "secret_ids" {
#   description = "Map of secret names to their Scaleway secret IDs"
#   value       = module.secrets.secret_ids
# }

# output "secret_paths" {
#   description = "Map of secret names to their paths (for Ansible lookups)"
#   value       = module.secrets.secret_paths
# }

# output "manual_secrets_needed" {
#   description = "List of secrets that require manual upload to Scaleway"
#   value       = module.secrets.manual_secrets_needed
# }

# output "scw_secrets_reader_application_id" {
#   description = "IAM Application ID for the scw-secrets reader"
#   value       = scaleway_iam_application.scw_secrets_reader.id
# }

# output "scw_secrets_reader_access_key" {
#   description = "Access key for scw-secrets (store securely, do not log)"
#   value       = scaleway_iam_api_key.scw_secrets_reader_key.access_key
#   sensitive   = true
# }

# output "scw_secrets_reader_setup_info" {
#   description = "Information for setting up scw-secrets on hosts"
#   value = {
#     secret_name  = scaleway_secret.scw_secrets_api_credentials.name
#     secret_path  = scaleway_secret.scw_secrets_api_credentials.path
#     instructions = "Retrieve credentials using: scw secret version access-by-path secret-name=scw-secrets-reader-api-credentials revision=latest"
#   }
# }
