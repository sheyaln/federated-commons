# Scaleway Configuration
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

variable "grafana_url" {
  description = "URL of the Grafana instance"
  type        = string
  default     = "https://grafana.example.cc"
}

variable "prometheus_url" {
  description = "URL of the Prometheus instance"
  type        = string
  default     = "http://prometheus:9090"
}

variable "loki_url" {
  description = "URL of the Loki instance"
  type        = string
  default     = "http://loki:3100"
}

variable "environment" {
  description = "Environment name (staging, production, etc.)"
  type        = string
  default     = "production"
}

variable "alertmanager_url" {
  description = "URL of the Alertmanager instance"
  type        = string
  default     = "http://alertmanager:9093"
}
