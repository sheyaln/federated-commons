variable "application_name" {
  description = "Display name for the application"
  type        = string
}

variable "gateway_domain" {
  description = "Gateway domain for signing certificates (e.g., gateway.example.org)"
  type        = string
  default     = "gateway.example.org"
}

variable "org_name" {
  description = "Organization name for signing certificates"
  type        = string
  default     = "Federated Commons"
}

variable "application_slug" {
  description = "URL-friendly slug for the application"
  type        = string
}

variable "category_group" {
  description = "Category group for the application"
  type        = string
  default     = "Member Tools"
}

variable "provider_type" { # TODO: Remove, 
  description = "Provider type (oauth2, saml, etc). Defaults to oauth2."
  type        = string
  default     = "oauth2"

  validation {
    condition     = contains(["oauth2", "saml"], var.provider_type)
    error_message = "Provider type must be either 'oauth2' or 'saml'."
  }
}



variable "redirect_uris" {
  description = "Valid redirect URIs for the OAuth2 provider (required for OAuth2, ignored for SAML)"
  type = list(object({
    matching_mode = optional(string, "strict")
    url           = string
  }))
  default = []
}

variable "launch_url" {
  description = "Launch URL for the application"
  type        = string
  default     = null
}

variable "icon_url" {
  description = "Icon URL for the application (relative to Authentik media, e.g., 'application-icons/nextcloud.png')"
  type        = string
  default     = null
}

variable "change_icon" {
  description = "Whether to change the icon for the application during the Terraform apply"
  type        = bool
  default     = false
}

variable "description" {
  description = "Description for the application"
  type        = string
  default     = null
}

variable "access_level" {
  description = "Access level: admin, delegate, treasurer, or member"
  type        = string
  validation {
    condition     = contains(["admin", "delegate", "treasurer", "member"], var.access_level)
    error_message = "Access level must be one of: admin, delegate, treasurer, member."
  }
}

variable "group_ids" {
  description = "Map of group IDs for access control"
  type = object({
    admin           = string
    union_delegate  = string
    union_treasurer = string
    union_member    = string
  })
}

# OAuth2 Provider Configuration
variable "oauth2_scopes" {
  description = "List of OAuth2 scopes to include in the provider. Uses authentik's default scopes if not specified."
  type        = list(string)
  default     = ["openid", "profile", "email", "groups"]

  validation {
    condition = alltrue([
      for scope in var.oauth2_scopes : contains([
        "openid", "profile", "email", "entitlements", "offline_access", "groups",
        "goauthentik.io/api", "user", "read:user", "user:email", "read:org",
        "vikunja_scope"
      ], scope)
    ])
    error_message = "OAuth2 scopes must be valid authentik scopes. Valid scopes are: openid, profile, email, entitlements, offline_access, goauthentik.io/api, user, read:user, user:email, read:org, vikunja_scope."
  }
}

variable "vikunja_team_name" {
  description = "Team name for Vikunja OIDC team assignment"
  type        = string
  default     = null
}

variable "access_token_validity" {
  description = "Access token validity duration (e.g., 'minutes=10', 'hours=1')"
  type        = string
  default     = "minutes=10"
}

variable "refresh_token_validity" {
  description = "Refresh token validity duration (e.g., 'days=30', 'hours=24')"
  type        = string
  default     = "days=30"
}


variable "sub_mode" {
  description = "Subject mode for the application"
  type        = string
  default     = "user_email"
}

# Authentication Flow Configuration
variable "authentication_flow_uuid" {
  description = "Custom authentication flow slug to use instead of the default. If not provided, uses the default Authentik authentication flow."
  type        = string
}

variable "authorization_flow_uuid" {
  description = "Custom authorization flow UUID to use instead of the default. If not provided, uses the default Authentik authorization flow."
  type        = string
}

variable "invalidation_flow_uuid" {
  description = "Custom invalidation flow slug to use instead of the default. If not provided, uses the default Authentik invalidation flow."
  type        = string
}


variable "generate_rsa_signing_key" {
  description = "Whether to generate an RSA signing key for the application"
  type        = bool
  default     = false
}

# SAML Provider Configuration
variable "saml_assertion_consumer_service_url" {
  description = "SAML Assertion Consumer Service (ACS) URL for the service provider (required for SAML)"
  type        = string
  default     = null
}

variable "saml_audience" {
  description = "SAML audience/entity ID for the service provider (required for SAML)"
  type        = string
  default     = null
}

variable "saml_service_provider_binding" {
  description = "SAML service provider binding (redirect or post)"
  type        = string
  default     = "redirect"

  validation {
    condition     = contains(["redirect", "post"], var.saml_service_provider_binding)
    error_message = "SAML service provider binding must be either 'redirect' or 'post'."
  }
}

variable "saml_name_id_mapping" {
  description = "Property mapping for SAML NameID field. Uses default if not specified."
  type        = string
  default     = null
}

variable "saml_name_id_use_email" {
  description = "Use email address as the SAML NameID instead of the default (user UUID/sub)"
  type        = bool
  default     = false
}

variable "saml_digest_algorithm" {
  description = "SAML digest algorithm for signatures"
  type        = string
  default     = "http://www.w3.org/2001/04/xmlenc#sha256"
}

variable "saml_signature_algorithm" {
  description = "SAML signature algorithm for assertions"
  type        = string
  default     = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
}

variable "saml_sign_assertion" {
  description = "Whether to sign SAML assertions"
  type        = bool
  default     = true
}

variable "saml_default_relay_state" {
  description = "Default relay state for SAML SSO"
  type        = string
  default     = null
}
