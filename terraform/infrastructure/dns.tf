
# =============================================================================
# DNS ZONES
# =============================================================================
# This file creates the DNS zones for your domains (from config/project.yml).
# Application DNS records are managed in dns_apps.tf (reads from config/dns.yml).
# Org-specific records (email, verification) go in dns_local.tf.
# =============================================================================


# Primary DNS Zone (tools domain from project.yml)
resource "scaleway_domain_zone" "main" {
  domain    = local.tools_domain
  subdomain = ""
}

# Management DNS Zone (if different from tools domain)
resource "scaleway_domain_zone" "management" {
  count     = local.management_domain != local.tools_domain ? 1 : 0
  domain    = local.management_domain
  subdomain = ""
}


# -----------------------------------------------------------------------------
# NAMESERVER RECORDS (Scaleway Default)
# -----------------------------------------------------------------------------

resource "scaleway_domain_record" "ns_0" {
  dns_zone = scaleway_domain_zone.main.id
  name     = ""
  type     = "NS"
  data     = "ns0.dom.scw.cloud."
  ttl      = 1800
}

resource "scaleway_domain_record" "ns_1" {
  dns_zone = scaleway_domain_zone.main.id
  name     = ""
  type     = "NS"
  data     = "ns1.dom.scw.cloud."
  ttl      = 1800
}
