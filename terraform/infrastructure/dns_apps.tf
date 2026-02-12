
# Dynamic DNS Records from dns.yml

# This file reads config/dns.yml and generates DNS records dynamically.
# The dns.yml file is gitignored to allow customization without committing.


locals {
  # Load apps configuration (gitignored file)
  apps_config_path = "${path.module}/../../config/dns.yml"
  apps_config      = fileexists(local.apps_config_path) ? yamldecode(file(local.apps_config_path)) : null

  # Map server names to their IP addresses from Terraform modules
  # This allows dns.yml to reference servers by name instead of module paths
  server_ips = local.apps_config != null ? {
    authentik  = module.authentik_prod.ip_address
    tools      = module.tools_prod.ip_address
    management = try(module.management[0].ip_address, null)
    staging    = try(module.tools_staging[0].ip_address, null)
  } : {}

  # Map domain keys to actual domain zones
  domain_zones = local.apps_config != null ? {
    tools      = scaleway_domain_zone.main.id
    management = length(scaleway_domain_zone.management) > 0 ? scaleway_domain_zone.management[0].id : null
    staging    = null
  } : {}

  # Flatten all A records from dns.yml into a single map
  # Key format: "{domain}_{subdomain}" to ensure uniqueness
  # Only include records where both domain zone AND server IP exist
  app_a_records = local.apps_config != null ? {
    for record in flatten([
      for domain_key, records in try(local.apps_config.dns_records, {}) : [
        for r in records : merge(r, {
          domain_key = domain_key
          unique_key = "${domain_key}_${replace(r.subdomain, "*", "wildcard")}"
        }) if r.type == "A" && lookup(local.domain_zones, domain_key, null) != null && lookup(local.server_ips, r.server, null) != null
      ]
    ]) : record.unique_key => record
  } : {}

  # Flatten all CNAME records from dns.yml
  app_cname_records = local.apps_config != null ? {
    for record in flatten([
      for domain_key, records in try(local.apps_config.dns_records, {}) : [
        for r in records : merge(r, {
          domain_key = domain_key
          unique_key = "${domain_key}_${r.subdomain}"
        }) if r.type == "CNAME" && lookup(local.domain_zones, domain_key, null) != null
      ]
    ]) : record.unique_key => record
  } : {}
}


# Application A Records (from dns.yml)


resource "scaleway_domain_record" "app_a" {
  for_each = local.app_a_records

  dns_zone = local.domain_zones[each.value.domain_key]
  name     = each.value.subdomain
  type     = "A"
  data     = local.server_ips[each.value.server]
  ttl      = try(each.value.ttl, 3600)

  lifecycle {
    prevent_destroy = true
  }
}

# Application CNAME Records (from dns.yml)


resource "scaleway_domain_record" "app_cname" {
  for_each = local.app_cname_records

  dns_zone = local.domain_zones[each.value.domain_key]
  name     = each.value.subdomain
  type     = "CNAME"
  data     = each.value.target
  ttl      = try(each.value.ttl, 3600)

  lifecycle {
    prevent_destroy = true
  }

}
