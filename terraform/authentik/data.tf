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
# N8N webhook endpoint URL for user notifications (n8n handles Slack threading)
# This is the URL endpoint, not a secret token
data "scaleway_secret" "n8n_webhook_user_notifications_url" {
  name = "n8n-webhook-user-notifications-url"
  path = "/apps/n8n"
}
data "scaleway_secret_version" "n8n_webhook_user_notifications_url" {
  secret_id = data.scaleway_secret.n8n_webhook_user_notifications_url.id
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

  # N8N webhook endpoint URL for user lifecycle notifications (signup, activation)
  # This is the URL to POST events to - n8n handles Slack threading and email notifications
  n8n_webhook_user_notifications = base64decode(data.scaleway_secret_version.n8n_webhook_user_notifications_url.data)
}
