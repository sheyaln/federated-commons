# REUSABLE APP MODULE FOR AUTHENTIK

# 
# This module creates:
# 1. An Authentik Application with the specified configuration
# 2. Either an OAuth2 Provider OR a SAML Provider based on provider_type
#    - OAuth2: Creates provider with configurable scopes and OAuth2 settings
#    - SAML: Creates provider with SAML-specific configuration (ACS URL, audience, etc.)
# 3. Binds appropriate groups to the application for access control
# 4. Creates property mappings for the requested provider type:
#    - OAuth2: Creates scope mappings for OpenID Connect scopes
#    - SAML: Creates attribute mappings for SAML assertions

locals {
  # Determine which groups should have access based on access level
  target_groups = var.access_level == "admin" ? [var.group_ids.admin] : (
    var.access_level == "delegate" ? [var.group_ids.admin, var.group_ids.union_delegate] : (
      var.access_level == "treasurer" ? [var.group_ids.admin, var.group_ids.union_delegate, var.group_ids.union_treasurer] :
      [var.group_ids.admin, var.group_ids.union_delegate, var.group_ids.union_treasurer, var.group_ids.union_member]
    )
  )

  # OAuth2 scopes configuration - used directly from variable
  oauth2_scopes = var.oauth2_scopes

}

# Validation for OAuth2 provider requirements
check "oauth2_requirements" {
  assert {
    condition     = var.provider_type != "oauth2" || length(var.redirect_uris) > 0
    error_message = "redirect_uris must be provided when provider_type is 'oauth2'."
  }
}

# Validation for SAML provider requirements
check "saml_requirements" {
  assert {
    condition = var.provider_type != "saml" || (
      var.saml_assertion_consumer_service_url != null &&
      var.saml_audience != null
    )
    error_message = "saml_assertion_consumer_service_url and saml_audience must be provided when provider_type is 'saml'."
  }
}

# Create custom scope mappings for this application (OAuth2 only)
# These will be used to provide the exact claims needed by each application

# OpenID scope mapping (OAuth2 only)
resource "authentik_property_mapping_provider_scope" "openid" {
  count       = var.provider_type == "oauth2" && contains(local.oauth2_scopes, "openid") ? 1 : 0
  name        = "${var.application_slug}-openid-scope"
  scope_name  = "openid"
  description = "OpenID Connect scope for ${var.application_name}"
  expression  = "return {}"
}

# Profile scope mapping (OAuth2 only)
resource "authentik_property_mapping_provider_scope" "profile" {
  count       = var.provider_type == "oauth2" && contains(local.oauth2_scopes, "profile") ? 1 : 0
  name        = "${var.application_slug}-profile-scope"
  scope_name  = "profile"
  description = "Profile scope for ${var.application_name}"
  expression  = <<-EOT
name = user.name.split(" ")
given_name = name[0]
family_name = name[-1]
return {
    "name": user.name,
    "given_name": given_name, 
    "family_name": family_name,
    "preferred_username": user.username,
    "nickname": user.username,
}
EOT
}

# Email scope mapping (OAuth2 only)
resource "authentik_property_mapping_provider_scope" "email" {
  count       = var.provider_type == "oauth2" && contains(local.oauth2_scopes, "email") ? 1 : 0
  name        = "${var.application_slug}-email-scope"
  scope_name  = "email"
  description = "Email scope for ${var.application_name}"
  expression  = <<-EOT
return {
    "email": user.email,
    "email_verified": True
}
EOT
}

# Offline access scope mapping (OAuth2 only)
resource "authentik_property_mapping_provider_scope" "offline_access" {
  count       = var.provider_type == "oauth2" && contains(local.oauth2_scopes, "offline_access") ? 1 : 0
  name        = "${var.application_slug}-offline-access-scope"
  scope_name  = "offline_access"
  description = "Offline access scope for ${var.application_name}"
  expression  = "return {}"
}

# Authentik API scope mapping for admin applications (OAuth2 only)
resource "authentik_property_mapping_provider_scope" "authentik_api" {
  count       = var.provider_type == "oauth2" && contains(local.oauth2_scopes, "goauthentik.io/api") ? 1 : 0
  name        = "${var.application_slug}-authentik-api-scope"
  scope_name  = "goauthentik.io/api"
  description = "Authentik API access scope for ${var.application_name}"
  expression  = "return {}"
}

# Groups scope mapping for role-based applications like Grafana (OAuth2 only)
resource "authentik_property_mapping_provider_scope" "groups" {
  count       = var.provider_type == "oauth2" && contains(local.oauth2_scopes, "groups") ? 1 : 0
  name        = "${var.application_slug}-groups-scope"
  scope_name  = "groups"
  description = "Groups scope for ${var.application_name} role mapping"
  expression  = <<-EOT
return {
    "groups": [group.name for group in request.user.ak_groups.all()],
    "groups_full": [{"name": group.name, "id": str(group.pk)} for group in request.user.ak_groups.all()]
}
EOT
}

# Vikunja scope mapping for automatic team assignment (OAuth2 only)
# Returns vikunja_groups claim with team information for OIDC team sync
resource "authentik_property_mapping_provider_scope" "vikunja_scope" {
  count       = var.provider_type == "oauth2" && contains(local.oauth2_scopes, "vikunja_scope") ? 1 : 0
  name        = "${var.application_slug}-vikunja-scope"
  scope_name  = "vikunja_scope"
  description = "Vikunja team assignment scope for ${var.application_name}"
  expression  = <<-EOT
# Return vikunja_groups claim for automatic team assignment
# Each team needs a unique oidcID and a name

# Start with the main org team (all users get this)
teams = [
    {
        "name": "${var.vikunja_team_name}",
        "oidcID": "main-team",
        "description": "All ${var.vikunja_team_name} members"
    }
]

# Add Delegates team if user is in union-delegate group
user_groups = [g.name for g in request.user.ak_groups.all()]
if "union-delegate" in user_groups:
    teams.append({
        "name": "Delegates",
        "oidcID": "delegates-team",
        "description": "${var.vikunja_team_name} Delegates"
    })

return {"vikunja_groups": teams}
EOT
}

# SAML Property Mappings (SAML only)
# These are used to define SAML attributes that will be included in SAML assertions

# Email attribute mapping for SAML
resource "authentik_property_mapping_provider_saml" "email" {
  count         = var.provider_type == "saml" ? 1 : 0
  name          = "${var.application_slug}-saml-email"
  saml_name     = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
  friendly_name = "Email"
  expression    = "return user.email"
}

# First name attribute mapping for SAML
resource "authentik_property_mapping_provider_saml" "first_name" {
  count         = var.provider_type == "saml" ? 1 : 0
  name          = "${var.application_slug}-saml-firstname"
  saml_name     = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"
  friendly_name = "Given Name"
  expression    = "return user.first_name"
}

# Last name attribute mapping for SAML
resource "authentik_property_mapping_provider_saml" "last_name" {
  count         = var.provider_type == "saml" ? 1 : 0
  name          = "${var.application_slug}-saml-lastname"
  saml_name     = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"
  friendly_name = "Surname"
  expression    = "return user.last_name"
}

# Display name attribute mapping for SAML
resource "authentik_property_mapping_provider_saml" "display_name" {
  count         = var.provider_type == "saml" ? 1 : 0
  name          = "${var.application_slug}-saml-displayname"
  saml_name     = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
  friendly_name = "Display Name"
  expression    = "return user.name"
}

# Username attribute mapping for SAML
resource "authentik_property_mapping_provider_saml" "username" {
  count         = var.provider_type == "saml" ? 1 : 0
  name          = "${var.application_slug}-saml-username"
  saml_name     = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"
  friendly_name = "UPN"
  expression    = "return user.username"
}

# Groups attribute mapping for SAML (if groups scope is in the list)
# Note: For SAML, we check oauth2_scopes for consistency, even though it's technically a SAML attribute
resource "authentik_property_mapping_provider_saml" "groups" {
  count         = var.provider_type == "saml" && contains(var.oauth2_scopes, "groups") ? 1 : 0
  name          = "${var.application_slug}-saml-groups"
  saml_name     = "http://schemas.xmlsoap.org/claims/Group"
  friendly_name = "Groups"
  expression    = "return [group.name for group in request.user.ak_groups.all()]"
}

# Gather all scope mapping IDs (OAuth2 only)
locals {
  scope_mapping_ids = var.provider_type == "oauth2" ? compact(concat(
    authentik_property_mapping_provider_scope.openid[*].id,
    authentik_property_mapping_provider_scope.profile[*].id,
    authentik_property_mapping_provider_scope.email[*].id,
    authentik_property_mapping_provider_scope.offline_access[*].id,
    authentik_property_mapping_provider_scope.authentik_api[*].id,
    authentik_property_mapping_provider_scope.groups[*].id,
    authentik_property_mapping_provider_scope.vikunja_scope[*].id
  )) : []

  # Gather all SAML property mapping IDs (SAML only)  
  saml_property_mapping_ids = var.provider_type == "saml" ? compact(concat(
    authentik_property_mapping_provider_saml.email[*].id,
    authentik_property_mapping_provider_saml.first_name[*].id,
    authentik_property_mapping_provider_saml.last_name[*].id,
    authentik_property_mapping_provider_saml.display_name[*].id,
    authentik_property_mapping_provider_saml.username[*].id,
    authentik_property_mapping_provider_saml.groups[*].id
  )) : []
}

# Create the OAuth2 Provider (only if provider_type is oauth2)
resource "authentik_provider_oauth2" "provider" {
  count = var.provider_type == "oauth2" ? 1 : 0

  name               = "${var.application_name} Provider"
  client_id          = local.client_id
  client_secret      = local.client_secret
  client_type        = "confidential"
  authorization_flow = var.authorization_flow_uuid
  invalidation_flow  = var.invalidation_flow_uuid

  signing_key = var.generate_rsa_signing_key ? authentik_certificate_key_pair.rsa_signing_key[0].id : data.authentik_certificate_key_pair.default.id

  # Standard OAuth2 settings
  include_claims_in_id_token = true
  issuer_mode                = "per_provider"

  # Token settings
  access_token_validity   = var.access_token_validity
  refresh_token_validity  = var.refresh_token_validity
  refresh_token_threshold = "seconds=0"

  # Logout settings
  logout_method = "backchannel"

  # Allowed redirect URIs
  allowed_redirect_uris = var.redirect_uris

  # Scope mappings - assign the created scope mappings to this provider
  property_mappings   = local.scope_mapping_ids
  authentication_flow = var.authentication_flow_uuid
  sub_mode            = var.sub_mode

  lifecycle {
    ignore_changes = [
      signing_key,
      client_secret,
    ]
  }
}

# Create the SAML Provider (only if provider_type is saml)
resource "authentik_provider_saml" "provider" {
  count = var.provider_type == "saml" ? 1 : 0

  name                = "${var.application_name} SAML Provider"
  authorization_flow  = var.authorization_flow_uuid
  authentication_flow = var.authentication_flow_uuid
  invalidation_flow   = var.invalidation_flow_uuid

  # SAML service provider configuration
  acs_url    = var.saml_assertion_consumer_service_url
  audience   = var.saml_audience
  sp_binding = var.saml_service_provider_binding

  # Signing configuration
  signing_kp = var.generate_rsa_signing_key ? authentik_certificate_key_pair.rsa_signing_key[0].id : data.authentik_certificate_key_pair.default.id

  # SAML assertion settings
  digest_algorithm    = var.saml_digest_algorithm
  signature_algorithm = var.saml_signature_algorithm
  sign_assertion      = var.saml_sign_assertion

  # NameID mapping - use email if saml_name_id_use_email is true, otherwise use provided mapping
  name_id_mapping = var.saml_name_id_use_email ? authentik_property_mapping_provider_saml.email[0].id : var.saml_name_id_mapping

  # Default relay state
  default_relay_state = var.saml_default_relay_state

  # Property mappings - assign the created SAML property mappings to this provider
  property_mappings = local.saml_property_mapping_ids

  lifecycle {
    ignore_changes = [
      signing_kp,
    ]
  }
}


# Determine the provider ID based on provider type
locals {
  provider_id = var.provider_type == "oauth2" ? (
    length(authentik_provider_oauth2.provider) > 0 ? authentik_provider_oauth2.provider[0].id : null
    ) : (
    length(authentik_provider_saml.provider) > 0 ? authentik_provider_saml.provider[0].id : null
  )
}

# Create a dedicated group for this application to allow app-specific RBAC assignments
resource "authentik_group" "application" {
  name         = "app-${var.application_slug}"
  is_superuser = false

  attributes = jsonencode({
    description = "Users with access to ${var.application_name}"
  })
}

# Create the Application
resource "authentik_application" "application" {
  name              = var.application_name
  slug              = var.application_slug
  protocol_provider = local.provider_id

  group = var.category_group

  meta_launch_url = var.launch_url
  # UI settings
  meta_description = var.description
  open_in_new_tab  = true
  meta_icon        = var.icon_url != null ? var.icon_url : "default-logo.png"

  # Policy engine mode - ANY means user needs to match any binding
  # ALL means user needs to match all bindings
  policy_engine_mode = "any"

  lifecycle {
    ignore_changes = [
      # meta_icon, # Provider normalizes path with /media/public/ prefix causing drift
    ]
  }

}

# Bind groups to the application for access control
# This is Authentik's built-in RBAC.

# Admin group always has access
resource "authentik_policy_binding" "admin_group" {
  target = authentik_application.application.uuid
  group  = var.group_ids.admin
  order  = 0
}

# Application-specific group binding so teams can delegate access at the app level
resource "authentik_policy_binding" "application_group" {
  target = authentik_application.application.uuid
  group  = authentik_group.application.id
  order  = 0
}

# Union delegate group (has access to delegate and member level apps)
resource "authentik_policy_binding" "delegate_group" {
  # Delegates get access to: delegate-level apps AND member-level apps
  count = contains(["delegate", "member"], var.access_level) ? 1 : 0

  target = authentik_application.application.uuid
  group  = var.group_ids.union_delegate
  order  = 0
}

# Union treasurer group (has access to treasurer, delegate, and member level apps)
resource "authentik_policy_binding" "treasurer_group" {
  # Treasurers get access to: treasurer-level apps AND delegate-level apps AND member-level apps
  count = contains(["treasurer", "delegate", "member"], var.access_level) ? 1 : 0

  target = authentik_application.application.uuid
  group  = var.group_ids.union_treasurer
  order  = 0
}

# Union member group (only has access to member level apps)
resource "authentik_policy_binding" "member_group" {
  count = var.access_level == "member" ? 1 : 0

  target = authentik_application.application.uuid
  group  = var.group_ids.union_member
  order  = 0
}
