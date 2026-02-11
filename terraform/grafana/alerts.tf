# Authentik Alerting Rules
# These alert rules monitor critical authentication metrics and performance

# Contact point for notifications
resource "grafana_contact_point" "authentik_alerts" {
  name = "authentik-alerts"

  email {
    addresses = [local.infra_email]
    subject   = "[AUTHENTIK ALERT] {{ .GroupLabels.alertname }}"
    message   = <<-EOT
    {{ range .Alerts }}
    Alert: {{ .Annotations.summary }}
    Description: {{ .Annotations.description }}
    Instance: {{ .Labels.instance }}
    Severity: {{ .Labels.severity }}
    {{ end }}
    EOT
  }
}

# Alert notification policy
resource "grafana_notification_policy" "authentik_alerts" {
  contact_point = grafana_contact_point.authentik_alerts.name
  group_by      = ["alertname", "instance"]
  
  group_wait      = "10s"
  group_interval  = "10s"
  repeat_interval = "12h"
}

# Authentik High Login Failure Rate Alert
resource "grafana_rule_group" "authentik_login_failures" {
  name             = "authentik-login-failures"
  folder_uid       = grafana_folder.security.uid
  interval_seconds = 60

  rule {
    name           = "AuthentikHighLoginFailureRate"
    condition      = "C"
    exec_err_state = "Alerting"
    no_data_state  = "NoData"
    for            = "5m"

    data {
      ref_id = "A"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr         = "rate(authentik_events_total{job=\"authentik-app\", action=\"login_failed\"}[5m]) * 60"
        interval     = ""
        refId        = "A"
        legendFormat = "Failed Logins/min"
      })
    }

    data {
      ref_id = "C"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "-100"
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              params = [5]
              type   = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = ["A"]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          }
        ]
        datasource = {
          type = "__expr__"
          uid  = "-100"
        }
        expression = "A"
        hide       = false
        refId      = "C"
        type       = "threshold"
      })
    }

    annotations = {
      description = "Authentik is experiencing high login failure rate: {{ $value }} failures per minute"
      summary     = "High authentication failure rate detected"
    }

    labels = {
      severity = "warning"
      service  = "authentik"
      type     = "authentication"
    }
  }
}

# Authentik High Authentication Latency Alert
resource "grafana_rule_group" "authentik_latency" {
  name             = "authentik-latency"
  folder_uid       = grafana_folder.security.uid
  interval_seconds = 60

  rule {
    name           = "AuthentikHighLatency"
    condition      = "C"
    exec_err_state = "Alerting"
    no_data_state  = "NoData"
    for            = "5m"

    data {
      ref_id = "A"
      relative_time_range {
        from = 300
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr         = "histogram_quantile(0.95, rate(authentik_flow_execution_duration_seconds_bucket{job=\"authentik-app\"}[5m]))"
        interval     = ""
        refId        = "A"
        legendFormat = "95th percentile latency"
      })
    }

    data {
      ref_id = "C"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "-100"
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              params = [3]
              type   = "gt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = ["A"]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          }
        ]
        datasource = {
          type = "__expr__"
          uid  = "-100"
        }
        expression = "A"
        hide       = false
        refId      = "C"
        type       = "threshold"
      })
    }

    annotations = {
      description = "Authentik authentication latency is high: {{ $value }}s for 95th percentile"
      summary     = "High authentication latency detected"
    }

    labels = {
      severity = "warning"
      service  = "authentik"
      type     = "performance"
    }
  }
}

# Authentik Low Login Success Rate Alert
resource "grafana_rule_group" "authentik_success_rate" {
  name             = "authentik-success-rate"
  folder_uid       = grafana_folder.security.uid
  interval_seconds = 60

  rule {
    name           = "AuthentikLowSuccessRate"
    condition      = "C"
    exec_err_state = "Alerting"
    no_data_state  = "NoData"
    for            = "10m"

    data {
      ref_id = "A"
      relative_time_range {
        from = 600
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr         = "rate(authentik_events_total{job=\"authentik-app\", action=\"login\"}[5m]) / (rate(authentik_events_total{job=\"authentik-app\", action=\"login\"}[5m]) + rate(authentik_events_total{job=\"authentik-app\", action=\"login_failed\"}[5m])) * 100"
        interval     = ""
        refId        = "A"
        legendFormat = "Success Rate %"
      })
    }

    data {
      ref_id = "C"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "-100"
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              params = [95]
              type   = "lt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = ["A"]
            }
            reducer = {
              params = []
              type   = "avg"
            }
            type = "query"
          }
        ]
        datasource = {
          type = "__expr__"
          uid  = "-100"
        }
        expression = "A"
        hide       = false
        refId      = "C"
        type       = "threshold"
      })
    }

    annotations = {
      description = "Authentik login success rate is low: {{ $value }}%"
      summary     = "Low authentication success rate detected"
    }

    labels = {
      severity = "critical"
      service  = "authentik"
      type     = "authentication"
    }
  }
}

# Authentik Service Down Alert
resource "grafana_rule_group" "authentik_availability" {
  name             = "authentik-availability"
  folder_uid       = grafana_folder.security.uid
  interval_seconds = 30

  rule {
    name           = "AuthentikServiceDown"
    condition      = "C"
    exec_err_state = "Alerting"
    no_data_state  = "Alerting"
    for            = "1m"

    data {
      ref_id = "A"
      relative_time_range {
        from = 60
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        expr         = "up{job=\"authentik-app\"}"
        interval     = ""
        refId        = "A"
        legendFormat = "Authentik Service Status"
      })
    }

    data {
      ref_id = "C"
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "-100"
      model = jsonencode({
        conditions = [
          {
            evaluator = {
              params = [1]
              type   = "lt"
            }
            operator = {
              type = "and"
            }
            query = {
              params = ["A"]
            }
            reducer = {
              params = []
              type   = "last"
            }
            type = "query"
          }
        ]
        datasource = {
          type = "__expr__"
          uid  = "-100"
        }
        expression = "A"
        hide       = false
        refId      = "C"
        type       = "threshold"
      })
    }

    annotations = {
      description = "Authentik service is down or not responding to health checks"
      summary     = "Authentik service unavailable"
    }

    labels = {
      severity = "critical"
      service  = "authentik"
      type     = "availability"
    }
  }
}
