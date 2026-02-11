
# Terraform Variables

# NOTE: Default values for domain/org settings come from config/project.yml
# via project_config.tf. You can override them in terraform.tfvars if needed.
#
# Sensitive values (credentials, tokens) MUST be provided via terraform.tfvars
# or environment variables - they are never stored in project.yml


##############################
# Scaleway Configuration   #
##############################
variable "scaleway_access_key" {
  description = "Scaleway access key"
  type        = string
  sensitive   = true
}

variable "scaleway_secret_key" {
  description = "Scaleway secret key"
  type        = string
  sensitive   = true
}

##############################
# Authentik Configuration   #
##############################
variable "authentik_token" {
  description = "Authentik API token for Terraform provider authentication"
  type        = string
  sensitive   = true
}

#################################################################################
# Organization Variables
# NOTE: These have defaults but are typically overridden by project_config.tf
# which reads from config/project.yml. You can also override in terraform.tfvars.
#################################################################################

variable "domain" {
  description = "The primary domain for your organization (default from config/project.yml)"
  type        = string
  default     = null # Will use local.tools_domain from project_config.tf
}

variable "organisation_name" {
  description = "The organization name for Authentik branding (default from config/project.yml)"
  type        = string
  default     = null # Will use local.org_name from project_config.tf
}

variable "organisation_slug" {
  description = "The organization slug for Authentik (default from config/project.yml)"
  type        = string
  default     = null # Will use local.org_slug from project_config.tf
}

##############################
# Branding Configuration    #
##############################
variable "branding_logo" {
  description = "Path to the logo file for Authentik branding (relative to custom-assets)"
  type        = string
  default     = "logo.png"
}

variable "branding_favicon" {
  description = "Path to the favicon file for Authentik branding"
  type        = string
  default     = "favicon.png"
}

variable "branding_default_flow_background" {
  description = "Path to the default flow background image for Authentik"
  type        = string
  default     = "background.jpg"
}

##############################
# Notifications              #
##############################
variable "n8n_webhook_user_notifications" {
  description = "n8n webhook URL for user lifecycle notifications (signup, activation). Leave empty to disable webhook notifications."
  type        = string
  default     = ""
  sensitive   = true
}
