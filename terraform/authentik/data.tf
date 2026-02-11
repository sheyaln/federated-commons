##############################
# Social Logins Secrets      #
##############################

data "scaleway_secret" "social_logins_google" {
  name = "social-google-oauth-credentials"
  path = "/social-logins/google"
}
data "scaleway_secret_version" "social_logins_google" {
  secret_id = data.scaleway_secret.social_logins_google.id
  revision  = "latest"
}
#==============================================
data "scaleway_secret" "social_logins_apple" {
  name = "social-apple-oauth-credentials"
  path = "/social-logins/apple"
}
data "scaleway_secret_version" "social_logins_apple" {
  secret_id = data.scaleway_secret.social_logins_apple.id
  revision  = "latest"
}
#==============================================
data "scaleway_secret" "smtp_config" {
  name = "smtp-config"
}
data "scaleway_secret_version" "smtp_config" {
  secret_id = data.scaleway_secret.smtp_config.id
  revision  = "latest"
}
#==============================================

##############################
# Decoded Secrets (Locals)   #
##############################

locals {
  # Google OAuth credentials
  google_oauth = jsondecode(base64decode(data.scaleway_secret_version.social_logins_google.data))

  # Apple OAuth credentials
  apple_oauth = jsondecode(base64decode(data.scaleway_secret_version.social_logins_apple.data))

  # SMTP configuration
  smtp_config = jsondecode(base64decode(data.scaleway_secret_version.smtp_config.data))
}
