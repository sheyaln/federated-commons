# ── OAuth App Credentials Generation (OAuth2 only) ─────────────────────────

# Generate random client ID for this OAuth app (OAuth2 only)
resource "random_uuid" "oauth_client_id" {
  count = var.provider_type == "oauth2" ? 1 : 0
}

# Generate random client secret for this OAuth app (OAuth2 only)
# Using alphanumeric only to avoid shell/env escaping issues (e.g. $ in docker-compose)
resource "random_password" "oauth_client_secret" {
  count   = var.provider_type == "oauth2" ? 1 : 0
  length  = 40
  special = false

  # Prevent regenerating existing secrets when config changes
  lifecycle {
    ignore_changes = [length, special]
  }
}

# ── Scaleway Secret Creation and Storage ─────────────────────────

# Create Scaleway secret for this app
resource "scaleway_secret" "app_secret" {
  name        = "authentik-app-${var.application_slug}"
  description = "${var.application_name} ${upper(var.provider_type)} credentials"
  type        = "key_value"
  tags        = ["authentik", var.application_slug, var.provider_type]
  path        = "/authentik/${var.application_slug}"
}

# Store generated OAuth credentials in Scaleway secret (OAuth2 only)
resource "scaleway_secret_version" "oauth_credentials" {
  count     = var.provider_type == "oauth2" ? 1 : 0
  secret_id = scaleway_secret.app_secret.id
  data = jsonencode({
    provider_type = "oauth2"

    # OAuth2 Credentials
    client_id     = random_uuid.oauth_client_id[0].result
    client_secret = random_password.oauth_client_secret[0].result

    # OAuth2 Configuration (all converted to strings for Scaleway)
    scopes        = join(",", var.oauth2_scopes)
    redirect_uris = join(",", [for uri in var.redirect_uris : uri.url])

    # Token Configuration
    access_token_validity  = var.access_token_validity
    refresh_token_validity = var.refresh_token_validity

    # Subject mode
    sub_mode = var.sub_mode
  })
}

# Store SAML configuration in Scaleway secret (SAML only)
resource "scaleway_secret_version" "saml_credentials" {
  count     = var.provider_type == "saml" ? 1 : 0
  secret_id = scaleway_secret.app_secret.id
  data = jsonencode({
    provider_type = "saml"

    # Service Provider Configuration
    acs_url    = var.saml_assertion_consumer_service_url
    audience   = var.saml_audience
    sp_binding = var.saml_service_provider_binding

    # Identity Provider Endpoints (relative to authentik domain)
    metadata_url = "/application/saml/${var.application_slug}/metadata/"
    sso_url      = "/application/saml/${var.application_slug}/sso/binding/${var.saml_service_provider_binding}/"
    slo_url      = "/application/saml/${var.application_slug}/slo/binding/${var.saml_service_provider_binding}/"

    # SAML Configuration (all converted to strings for Scaleway)
    sign_assertion      = tostring(var.saml_sign_assertion)
    digest_algorithm    = var.saml_digest_algorithm
    signature_algorithm = var.saml_signature_algorithm
    default_relay_state = var.saml_default_relay_state != null ? var.saml_default_relay_state : ""
  })
}

# ── Local values for use in main.tf ─────────────────────────

locals {
  client_id     = var.provider_type == "oauth2" && length(random_uuid.oauth_client_id) > 0 ? random_uuid.oauth_client_id[0].result : ""
  client_secret = var.provider_type == "oauth2" && length(random_password.oauth_client_secret) > 0 ? random_password.oauth_client_secret[0].result : ""
}
