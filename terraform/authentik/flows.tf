module "flows" {
  source = "./flows"

  google_social_login_uuid = authentik_source_oauth.google_social_login.uuid
  apple_social_login_uuid  = authentik_source_oauth.apple_social_login.uuid
  union_member_group_id    = authentik_group.union_member.id

  # SMTP configuration from Scaleway secrets
  smtp_host     = local.smtp_config.smtp_host
  smtp_port     = local.smtp_config.smtp_port
  smtp_username = local.smtp_config.smtp_username
  smtp_password = local.smtp_config.smtp_password

  # Organization configuration from project.yml
  domain            = local.tools_domain
  organisation_name = local.org_name
}
