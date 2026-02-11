# AUTHENTIK EMBEDDED OUTPOST FOR TRAEFIK FORWARD AUTH
#
# The embedded outpost is automatically created by Authentik and handles
# forward auth requests at /outpost.goauthentik.io/auth/traefik
#
# We use a data source to look it up and manage it to bind our proxy providers.

# Data source to look up the embedded outpost by its name
data "authentik_outpost" "embedded" {
  name = "authentik Embedded Outpost"
}

# Import block to bring the existing embedded outpost under Terraform management
import {
  to = authentik_outpost.embedded
  id = data.authentik_outpost.embedded.id
}

# Manage the embedded outpost to bind our proxy providers
resource "authentik_outpost" "embedded" {
  name = "authentik Embedded Outpost"
  type = "proxy"

  # Bind all forward auth proxy providers to the embedded outpost
  # n8n now uses direct OIDC instead of forward auth
  # Add new forward auth providers here as they're created
  protocol_providers = []

  config = jsonencode({
    authentik_host          = "https://${local.gateway_domain}/"
    authentik_host_browser  = "https://${local.gateway_domain}/"
    authentik_host_insecure = false
    log_level               = "info"
    object_naming_template  = "ak-outpost-%(name)s"
    refresh_interval        = "minutes=5"
  })

  lifecycle {
    # Prevent Terraform from trying to delete the embedded outpost
    prevent_destroy = true

    # Ignore changes to service_connection - Authentik manages this for embedded outpost
    ignore_changes = [
      service_connection,
    ]
  }
}
