# Reference existing data sources (Provisioned via Ansible)
# These data sources are created by the monitoring/stack role
data "grafana_data_source" "prometheus" {
  name = "Prometheus"
}

data "grafana_data_source" "loki" {
  name = "Loki"
}

# Outputs for debugging
output "prometheus_datasource_uid" {
  value = data.grafana_data_source.prometheus.uid
}

output "loki_datasource_uid" {
  value = data.grafana_data_source.loki.uid
}
