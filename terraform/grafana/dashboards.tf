# Infrastructure Overview Dashboard
# Shows all servers: management, tools-prod, authentik
resource "grafana_dashboard" "infrastructure_overview" {
  folder      = grafana_folder.infrastructure.id
  config_json = templatefile("${path.module}/dashboards/infrastructure-overview.json", {
    prometheus_uid = data.grafana_data_source.prometheus.uid
    loki_uid       = data.grafana_data_source.loki.uid
  })
}

# Traefik Overview Dashboard
# Shows all Traefik instances across servers
resource "grafana_dashboard" "traefik_overview" {
  folder      = grafana_folder.infrastructure.id
  config_json = templatefile("${path.module}/dashboards/traefik-overview.json", {
    prometheus_uid = data.grafana_data_source.prometheus.uid
    loki_uid       = data.grafana_data_source.loki.uid
  })
}

# Authentik Metrics Dashboard
# SSO and authentication monitoring
resource "grafana_dashboard" "authentik_metrics" {
  folder      = grafana_folder.security.id
  config_json = templatefile("${path.module}/dashboards/authentik-metrics.json", {
    prometheus_uid = data.grafana_data_source.prometheus.uid
    loki_uid       = data.grafana_data_source.loki.uid
  })
}

# Logs Explorer Dashboard
# Central log viewing across all servers
resource "grafana_dashboard" "logs_explorer" {
  folder      = grafana_folder.infrastructure.id
  config_json = templatefile("${path.module}/dashboards/logs-explorer.json", {
    prometheus_uid = data.grafana_data_source.prometheus.uid
    loki_uid       = data.grafana_data_source.loki.uid
  })
}

# Tools-Prod Application Stack Dashboard
resource "grafana_dashboard" "tools_prod_application_stack" {
  folder      = grafana_folder.applications.id
  config_json = templatefile("${path.module}/dashboards/tools-prod-application-stack.json", {
    prometheus_uid = data.grafana_data_source.prometheus.uid
    loki_uid       = data.grafana_data_source.loki.uid
  })
}

# Authentik Stack Monitoring Dashboard (legacy, kept for compatibility)
resource "grafana_dashboard" "authentik_stack_monitoring" {
  folder      = grafana_folder.applications.id
  config_json = templatefile("${path.module}/dashboards/authentik-stack-monitoring.json", {
    prometheus_uid = data.grafana_data_source.prometheus.uid
    loki_uid       = data.grafana_data_source.loki.uid
  })
}

# Tools-Prod Per-Application Detail Dashboard
resource "grafana_dashboard" "tools_prod_application_detail" {
  folder      = grafana_folder.applications.id
  config_json = templatefile("${path.module}/dashboards/tools-prod-application-detail.json", {
    prometheus_uid = data.grafana_data_source.prometheus.uid
    loki_uid       = data.grafana_data_source.loki.uid
  })
}
