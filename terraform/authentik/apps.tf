module "outline" {
  source = "./modules/app"

  application_name = "Wiki - Outline"
  application_slug = "outline"
  # provider config
  provider_type = "oauth2"
  redirect_uris = [
    {
      url = "https://wiki.${local.tools_domain}/auth/oidc.callback"
    }
  ]
  access_level = "member"

  # oauth2 config - documents intended scopes for collaborative wiki editing
  oauth2_scopes         = ["openid", "profile", "email", "groups", "offline_access"] # offline_access enables refresh tokens
  access_token_validity = "hours=1"                                                  # Longer tokens for document editing

  # custom login flow
  authentication_flow_uuid = module.flows.authentication_flow_login
  authorization_flow_uuid  = module.flows.default_provider_authorization_implicit_consent_id
  invalidation_flow_uuid   = module.flows.default_provider_invalidation_flow_id

  # ui stuff
  icon_url = "outline-icon.png"

  # groups for access
  group_ids = {
    admin           = authentik_group.admin.id
    union_delegate  = authentik_group.union_delegate.id
    union_member    = authentik_group.union_member.id
    union_treasurer = authentik_group.union_treasurer.id
  }

  depends_on = [
    authentik_group.admin,
    authentik_group.union_delegate,
    authentik_group.union_member,
    authentik_group.union_treasurer
  ]
}

# Grafana monitoring application (delegates get Editor, admins get Admin)
module "grafana" {
  source = "./modules/app"

  application_name = "Grafana"
  application_slug = "grafana"
  category_group   = "Technical Management"

  # provider config
  provider_type = "oauth2"
  redirect_uris = [
    {
      url = "https://grafana.${local.management_domain}/login/generic_oauth"
    }
  ]
  access_level = "delegate" # Delegates and admins can access

  # oauth2 config - include groups for role mapping
  oauth2_scopes = ["openid", "profile", "email", "groups", "offline_access"] # groups for role mapping, offline_access for refresh tokens

  # custom login flow
  authentication_flow_uuid = module.flows.authentication_flow_login
  authorization_flow_uuid  = module.flows.default_provider_authorization_implicit_consent_id
  invalidation_flow_uuid   = module.flows.default_provider_invalidation_flow_id

  # ui stuff
  icon_url = "grafana-icon.png"

  # groups for access
  group_ids = {
    admin           = authentik_group.admin.id
    union_delegate  = authentik_group.union_delegate.id
    union_member    = authentik_group.union_member.id
    union_treasurer = authentik_group.union_treasurer.id
  }

  depends_on = [
    authentik_group.admin,
    authentik_group.union_delegate,
    authentik_group.union_member,
    authentik_group.union_treasurer
  ]
}

# Zabbix Monitoring - SAML Authentication
# Zabbix uses php-saml library for SAML2 SSO
module "zabbix" {
  source = "./modules/app"

  application_name = "Zabbix"
  application_slug = "zabbix"
  launch_url       = "https://zabbix.${local.management_domain}"
  category_group   = "Technical Management"

  # SAML provider configuration
  provider_type = "saml"

  # SAML service provider settings
  # ACS URL is the endpoint where Authentik posts the SAML assertion
  saml_assertion_consumer_service_url = "https://zabbix.${local.management_domain}/index_sso.php?acs"

  # Audience/Entity ID must match what's configured in Zabbix SAML settings
  saml_audience = "zabbix"

  # SAML binding and signing
  saml_service_provider_binding = "post"
  saml_sign_assertion           = true
  saml_digest_algorithm         = "http://www.w3.org/2001/04/xmlenc#sha256"
  saml_signature_algorithm      = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"

  # Use email as the username/NameID for Zabbix user matching
  saml_name_id_use_email = true

  # Generate RSA signing key for SAML assertions
  generate_rsa_signing_key = true
  gateway_domain           = local.gateway_domain
  org_name                 = local.org_name

  access_level = "admin" # Only admins can access Zabbix

  # Authentication flows
  authentication_flow_uuid = module.flows.authentication_flow_login
  authorization_flow_uuid  = module.flows.default_provider_authorization_implicit_consent_id
  invalidation_flow_uuid   = module.flows.default_provider_invalidation_flow_id

  # ui stuff
  icon_url = "zabbix-icon.png"

  # groups for access
  group_ids = {
    admin           = authentik_group.admin.id
    union_delegate  = authentik_group.union_delegate.id
    union_member    = authentik_group.union_member.id
    union_treasurer = authentik_group.union_treasurer.id
  }

  depends_on = [
    authentik_group.admin,
    authentik_group.union_delegate,
    authentik_group.union_member,
    authentik_group.union_treasurer
  ]
}

module "nextcloud" {
  source = "./modules/app"

  application_name = "Cloud Storage"
  application_slug = "cloud"
  launch_url       = "https://cloud.${local.tools_domain}/apps/user_oidc/login/3"
  # provider config
  provider_type = "oauth2"
  redirect_uris = [
    {
      url           = "https://cloud.${local.tools_domain}/apps/user_oidc/code"
      matching_mode = "strict"
    }
  ]
  access_level = "member"

  generate_rsa_signing_key = true
  gateway_domain           = local.gateway_domain
  org_name                 = local.org_name

  # oauth2 config
  oauth2_scopes = ["openid", "profile", "email", "groups"]

  # custom login flow
  authentication_flow_uuid = module.flows.authentication_flow_login
  authorization_flow_uuid  = module.flows.default_provider_authorization_implicit_consent_id
  invalidation_flow_uuid   = module.flows.default_provider_invalidation_flow_id

  # ui stuff - customize with your org's icon
  icon_url = "nextcloud-icon.png"

  sub_mode = "user_id"

  # groups for access
  group_ids = {
    admin           = authentik_group.admin.id
    union_delegate  = authentik_group.union_delegate.id
    union_member    = authentik_group.union_member.id
    union_treasurer = authentik_group.union_treasurer.id
  }

}

# =============================================================================
# BOOKMARK APPS (External Links)
# =============================================================================
# Add bookmark modules here for external services you want to display
# in the Authentik application library. Example:
#
# module "example_bookmark" {
#   source = "./modules/bookmark"
#
#   application_name = "External Service"
#   application_slug = "external_service"
#   launch_url       = "https://example.com/your-form"
#   access_level     = "member"
#   category_group   = "Member Resources"
#
#   group_ids = {
#     admin           = authentik_group.admin.id
#     union_delegate  = authentik_group.union_delegate.id
#     union_member    = authentik_group.union_member.id
#     union_treasurer = authentik_group.union_treasurer.id
#   }
# }

module "espocrm" {
  source = "./modules/app"

  application_name = "EspoCRM"
  application_slug = "espocrm"
  launch_url       = "https://espo.${local.tools_domain}"

  # provider config
  provider_type = "oauth2"
  redirect_uris = [
    {
      url           = "https://espo.${local.tools_domain}/oauth-callback.php"
      matching_mode = "strict"
    }
  ]

  access_level = "delegate"

  # oauth2 config
  oauth2_scopes = ["openid", "profile", "email", "groups"]

  # custom login flow
  authentication_flow_uuid = module.flows.authentication_flow_login
  authorization_flow_uuid  = module.flows.default_provider_authorization_implicit_consent_id
  invalidation_flow_uuid   = module.flows.default_provider_invalidation_flow_id

  # ui stuff
  icon_url = "espocrm-icon.png"

  # groups for access
  group_ids = {
    admin           = authentik_group.admin.id
    union_delegate  = authentik_group.union_delegate.id
    union_member    = authentik_group.union_member.id
    union_treasurer = authentik_group.union_treasurer.id
  }
}

# n8n Workflow Automation - OIDC Authentication
module "n8n" {
  source = "./modules/app"

  application_name = "n8n Automation"
  application_slug = "n8n"
  launch_url       = "https://n8n.${local.management_domain}"
  category_group   = "Technical Management"
  provider_type    = "oauth2"

  # OIDC Configuration
  redirect_uris = [
    {
      url           = "https://n8n.${local.management_domain}/auth/oidc/callback"
      matching_mode = "strict"
    }
  ]

  # OAuth2 scopes for n8n OIDC
  oauth2_scopes = ["openid", "email", "profile"]

  access_level = "delegate"

  # custom login flow
  authentication_flow_uuid = module.flows.authentication_flow_login
  authorization_flow_uuid  = module.flows.default_provider_authorization_implicit_consent_id
  invalidation_flow_uuid   = module.flows.default_provider_invalidation_flow_id

  # ui stuff
  icon_url = "n8n-icon.png"

  # groups for access
  group_ids = {
    admin           = authentik_group.admin.id
    union_delegate  = authentik_group.union_delegate.id
    union_member    = authentik_group.union_member.id
    union_treasurer = authentik_group.union_treasurer.id
  }

  depends_on = [
    authentik_group.admin,
    authentik_group.union_delegate,
    authentik_group.union_member,
    authentik_group.union_treasurer
  ]
}

module "vikunja" {
  source = "./modules/app"

  application_name = "Vikunja Tasks"
  application_slug = "vikunja"
  category_group   = "Organization"
  provider_type    = "oauth2"

  # OIDC Configuration
  redirect_uris = [
    {
      url           = "https://tasks.${local.tools_domain}/auth/openid/authentik"
      matching_mode = "strict"
    }
  ]

  # OAuth2 scopes for Vikunja OIDC
  # vikunja_scope provides the vikunja_groups claim for automatic team assignment
  oauth2_scopes         = ["openid", "email", "profile", "vikunja_scope"]
  access_token_validity = "hours=1"

  # Vikunja team configuration - all users will be added to this team
  vikunja_team_name = local.org_name

  access_level = "member"

  # custom login flow
  authentication_flow_uuid = module.flows.authentication_flow_login
  authorization_flow_uuid  = module.flows.default_provider_authorization_implicit_consent_id
  invalidation_flow_uuid   = module.flows.default_provider_invalidation_flow_id

  # ui stuff
  icon_url = "vikunja-icon.png"

  # groups for access
  group_ids = {
    admin           = authentik_group.admin.id
    union_delegate  = authentik_group.union_delegate.id
    union_member    = authentik_group.union_member.id
    union_treasurer = authentik_group.union_treasurer.id
  }

  depends_on = [
    authentik_group.admin,
    authentik_group.union_delegate,
    authentik_group.union_member,
    authentik_group.union_treasurer
  ]
}

# Jitsi Meet - OIDC Authentication via custom adapter
# Uses a Flask-based OIDC adapter that handles the auth flow and issues JWTs
# The adapter sits at /oidc on the same domain as Jitsi
module "jitsi" {
  source = "./modules/app"

  application_name = "Jitsi Meet"
  application_slug = "jitsi"
  launch_url       = "https://meet.${local.tools_domain}"

  provider_type = "oauth2"
  redirect_uris = [
    {
      url           = "https://meet.${local.tools_domain}/oidc/redirect"
      matching_mode = "strict"
    }
  ]

  access_level = "member"

  oauth2_scopes = ["openid", "email", "profile"]

  # custom login flow
  authentication_flow_uuid = module.flows.authentication_flow_login
  authorization_flow_uuid  = module.flows.default_provider_authorization_implicit_consent_id
  invalidation_flow_uuid   = module.flows.default_provider_invalidation_flow_id

  # ui stuff
  icon_url = "jitsi-icon.png"

  # groups for access
  group_ids = {
    admin           = authentik_group.admin.id
    union_delegate  = authentik_group.union_delegate.id
    union_member    = authentik_group.union_member.id
    union_treasurer = authentik_group.union_treasurer.id
  }

  depends_on = [
    authentik_group.admin,
    authentik_group.union_delegate,
    authentik_group.union_member,
    authentik_group.union_treasurer
  ]
}

# Script Server (Wobbler) - Admin-only automation scripts runner
module "wobbler" {
  source = "./modules/app"

  application_name = "Wobbler"
  application_slug = "wobbler"
  category_group   = "Technical Management"

  # provider config
  provider_type = "oauth2"
  redirect_uris = [
    {
      url = "https://wobbler.${local.management_domain}/login.html"
    }
  ]
  access_level = "delegate" # Delegates and admins can access

  # oauth2 config
  oauth2_scopes = ["openid", "profile", "email", "groups"]

  # custom login flow
  authentication_flow_uuid = module.flows.authentication_flow_login
  authorization_flow_uuid  = module.flows.default_provider_authorization_implicit_consent_id
  invalidation_flow_uuid   = module.flows.default_provider_invalidation_flow_id

  # ui stuff
  icon_url = "wobbler-icon.png"

  # groups for access
  group_ids = {
    admin           = authentik_group.admin.id
    union_delegate  = authentik_group.union_delegate.id
    union_member    = authentik_group.union_member.id
    union_treasurer = authentik_group.union_treasurer.id
  }

  depends_on = [
    authentik_group.admin,
    authentik_group.union_delegate,
    authentik_group.union_member,
    authentik_group.union_treasurer
  ]
}

# Wazuh SIEM Dashboard - SAML Authentication
# Wazuh uses OpenSearch Dashboards which requires SAML for SSO
module "wazuh" {
  source = "./modules/app"

  application_name = "Wazuh SIEM"
  application_slug = "wazuh"
  launch_url       = "https://wazuh.${local.management_domain}"
  category_group   = "Technical Management"

  # SAML provider configuration
  provider_type = "saml"

  # SAML service provider settings
  # ACS URL is the endpoint where Authentik posts the SAML assertion
  saml_assertion_consumer_service_url = "https://wazuh.${local.management_domain}/_opendistro/_security/saml/acs"

  # Audience/Entity ID must match what's configured in Wazuh indexer config.yml
  saml_audience = "wazuh-saml"

  # SAML binding and signing
  saml_service_provider_binding = "post"
  saml_sign_assertion           = true
  saml_digest_algorithm         = "http://www.w3.org/2001/04/xmlenc#sha256"
  saml_signature_algorithm      = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"

  # Use email as the username/NameID instead of UUID
  saml_name_id_use_email = true

  # Include groups for role mapping in Wazuh
  oauth2_scopes = ["groups"]

  # Generate RSA signing key for SAML assertions
  generate_rsa_signing_key = true
  gateway_domain           = local.gateway_domain
  org_name                 = local.org_name

  access_level = "admin" # Only admins can access Wazuh SIEM

  # Authentication flows
  authentication_flow_uuid = module.flows.authentication_flow_login
  authorization_flow_uuid  = module.flows.default_provider_authorization_implicit_consent_id
  invalidation_flow_uuid   = module.flows.default_provider_invalidation_flow_id

  # ui stuff
  icon_url = "wazuh-icon.png"

  # groups for access
  group_ids = {
    admin           = authentik_group.admin.id
    union_delegate  = authentik_group.union_delegate.id
    union_member    = authentik_group.union_member.id
    union_treasurer = authentik_group.union_treasurer.id
  }

  depends_on = [
    authentik_group.admin,
    authentik_group.union_delegate,
    authentik_group.union_member,
    authentik_group.union_treasurer
  ]
}
