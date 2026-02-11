output "application_uuid" {
  description = "UUID of the created application"
  value       = authentik_application.application.uuid
}

output "application_group_id" {
  description = "ID of the Authentik group created for this application"
  value       = authentik_group.application.id
}

output "application_slug" {
  description = "Slug of the created application"
  value       = authentik_application.application.slug
}

output "provider_id" {
  description = "ID of the provider (OAuth2 or SAML)"
  value       = local.provider_id
}

output "provider_type" {
  description = "Type of provider (oauth2 or saml)"
  value       = var.provider_type
}

# OAuth2-specific outputs
output "client_id" {
  description = "OAuth2 client ID (only available for OAuth2 providers)"
  value       = var.provider_type == "oauth2" && length(authentik_provider_oauth2.provider) > 0 ? authentik_provider_oauth2.provider[0].client_id : null
}

output "client_secret" {
  description = "OAuth2 client secret (only available for OAuth2 providers)"
  value       = var.provider_type == "oauth2" && length(authentik_provider_oauth2.provider) > 0 ? authentik_provider_oauth2.provider[0].client_secret : null
  sensitive   = true
}

# SAML-specific outputs
output "saml_metadata_url" {
  description = "SAML metadata URL (only available for SAML providers)"
  value       = var.provider_type == "saml" ? "/application/saml/${var.application_slug}/metadata/" : null
}

output "saml_sso_url" {
  description = "SAML SSO URL (only available for SAML providers)"
  value       = var.provider_type == "saml" ? "/application/saml/${var.application_slug}/sso/binding/${var.saml_service_provider_binding}/" : null
}

output "saml_slo_url" {
  description = "SAML SLO URL (only available for SAML providers)"
  value       = var.provider_type == "saml" ? "/application/saml/${var.application_slug}/slo/binding/${var.saml_service_provider_binding}/" : null
}
