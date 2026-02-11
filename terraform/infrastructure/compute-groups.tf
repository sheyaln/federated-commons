# Shared inbound rules applied to every security group.
# Each group composes these with role-specific rules.
locals {
  shared_inbound_rules = [
    # HTTPS
    { protocol = "TCP", port = 443, port_range = "443-443", ip_range = "0.0.0.0/0" },
    { protocol = "UDP", port = 443, port_range = "443-443", ip_range = "0.0.0.0/0" },
    # HTTP
    { protocol = "TCP", port = 80, port_range = "80-80", ip_range = "0.0.0.0/0" },
    { protocol = "UDP", port = 80, port_range = "80-80", ip_range = "0.0.0.0/0" },
    # SSH
    { protocol = "TCP", port = 22, port_range = "22-22", ip_range = "0.0.0.0/0" },
    { protocol = "UDP", port = 22, port_range = "22-22", ip_range = "0.0.0.0/0" },
    # DNS
    { protocol = "UDP", port = 53, port_range = "53-53", ip_range = "0.0.0.0/0" },
    { protocol = "TCP", port = 53, port_range = "53-53", ip_range = "0.0.0.0/0" },
    # Monitoring (restricted to management server)
    { protocol = "TCP", port = 9100, port_range = "9100-9100", ip_range = var.management_ip },
    { protocol = "TCP", port = 8080, port_range = "8080-8080", ip_range = var.management_ip },
    { protocol = "TCP", port = 9080, port_range = "9080-9080", ip_range = var.management_ip },
  ]

  # Nextcloud Talk TURN/STUN -- only tools-prod and tools-staging
  turn_inbound_rules = [
    { protocol = "TCP", port = 3478, port_range = "3478-3478", ip_range = "0.0.0.0/0" },
    { protocol = "UDP", port = 3478, port_range = "3478-3478", ip_range = "0.0.0.0/0" },
    # eturnal relay port range (no single port, only range)
    { protocol = "UDP", port = null, port_range = "49152-49252", ip_range = "0.0.0.0/0" },
  ]

  # Wazuh Manager ports -- only management server
  wazuh_inbound_rules = [
    { protocol = "TCP", port = 1514, port_range = "1514-1514", ip_range = "0.0.0.0/0" },
    { protocol = "TCP", port = 1515, port_range = "1515-1515", ip_range = "0.0.0.0/0" },
    { protocol = "UDP", port = 514, port_range = "514-514", ip_range = "0.0.0.0/0" },
  ]
}

# -------------------------------------------------------------------
# Authentik: base rules only
# -------------------------------------------------------------------
resource "scaleway_instance_security_group" "authentik_group" {
  name        = "authentik-security-group"
  description = "Authentik server: HTTP/S, SSH, DNS, monitoring"

  enable_default_security = false
  external_rules          = null
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"
  stateful                = true

  dynamic "inbound_rule" {
    for_each = local.shared_inbound_rules
    content {
      action     = "accept"
      ip_range   = inbound_rule.value.ip_range
      protocol   = inbound_rule.value.protocol
      port       = inbound_rule.value.port
      port_range = inbound_rule.value.port_range
    }
  }
}

# -------------------------------------------------------------------
# Tools (prod + staging): base rules + TURN/STUN
# -------------------------------------------------------------------
resource "scaleway_instance_security_group" "tools_group" {
  name        = "tools-security-group"
  description = "Tools servers: HTTP/S, SSH, DNS, monitoring, Nextcloud Talk TURN/STUN"

  enable_default_security = false
  external_rules          = null
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"
  stateful                = true

  dynamic "inbound_rule" {
    for_each = concat(local.shared_inbound_rules, local.turn_inbound_rules)
    content {
      action     = "accept"
      ip_range   = inbound_rule.value.ip_range
      protocol   = inbound_rule.value.protocol
      port       = inbound_rule.value.port
      port_range = inbound_rule.value.port_range
    }
  }
}

# -------------------------------------------------------------------
# Management: base rules + Wazuh Manager
# -------------------------------------------------------------------
resource "scaleway_instance_security_group" "management_group" {
  name        = "management-security-group"
  description = "Management server: HTTP/S, SSH, DNS, monitoring, Wazuh Manager"

  enable_default_security = false
  external_rules          = null
  inbound_default_policy  = "drop"
  outbound_default_policy = "accept"
  stateful                = true

  dynamic "inbound_rule" {
    for_each = concat(local.shared_inbound_rules, local.wazuh_inbound_rules)
    content {
      action     = "accept"
      ip_range   = inbound_rule.value.ip_range
      protocol   = inbound_rule.value.protocol
      port       = inbound_rule.value.port
      port_range = inbound_rule.value.port_range
    }
  }
}
