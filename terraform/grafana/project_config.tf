
# Central Project Configuration

# This file loads the shared config/project.yml and makes it available
# to all Terraform resources via local variables.


locals {
  # Load the central project configuration
  _config = yamldecode(file("${path.module}/../../config/project.yml"))
  
  # Project identity
  project_name = local._config.project.name
  org_name     = local._config.project.org_name
  org_slug     = local._config.project.org_slug
  
  # Domains
  tools_domain      = local._config.domains.tools
  management_domain = local._config.domains.management
  staging_domain    = local._config.domains.staging
  gateway_domain    = "gateway.${local._config.domains.tools}"
  
  # Emails
  infra_email = local._config.emails.infra
  
  # Cloud config
  cloud_region = local._config.cloud.region
}
