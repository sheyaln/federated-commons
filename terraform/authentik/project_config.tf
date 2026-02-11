
# Central Project Configuration

# This file loads the shared config/project.yml and makes it available
# to all Terraform resources via local variables.
#
# DO NOT hardcode domain names or project settings elsewhere!
# Edit ../config/project.yml instead.
#
# Variables can be overridden via terraform.tfvars if needed (coalesce pattern)


locals {
  # Load the central project configuration
  _config = yamldecode(file("${path.module}/../../config/project.yml"))

  # Project identity (with variable override support)
  project_name = local._config.project.name
  org_name     = coalesce(var.organisation_name, local._config.project.org_name)
  org_slug     = coalesce(var.organisation_slug, local._config.project.org_slug)

  # Domains (with variable override support)
  tools_domain      = coalesce(var.domain, local._config.domains.tools)
  management_domain = local._config.domains.management
  staging_domain    = local._config.domains.staging
  # Gateway domain is derived from tools domain (convention: gateway.{tools_domain})
  gateway_domain = "gateway.${local.tools_domain}"

  # Emails
  infra_email = local._config.emails.infra
  admin_email = local._config.emails.admin
  from_name   = local._config.emails.from_name

  # Cloud config
  cloud_region = local._config.cloud.region
  s3_endpoint  = local._config.cloud.s3_endpoint
}
