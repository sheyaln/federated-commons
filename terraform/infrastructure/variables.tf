############
# Scaleway
############
variable "access_key" {
  description = "Scaleway access key"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Scaleway secret key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Scaleway region"
  type        = string
  default     = "fr-par"
}

variable "project_id" {
  description = "Scaleway project ID"
  type        = string
}


variable "image" {
  description = "Base image"
  default     = "ubuntu_jammy"
}

############
# Databases
############
variable "psql_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "obs-admin"
}

variable "psql_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

############
# Production
############
# variable "create_prod" {
#   description = "Create production server"
#   type        = bool
#   default     = true
# }

variable "prod_type" {
  description = "Instance type for production server"
  default     = "DEV1-L"
}

############
# Staging
############
variable "create_staging" {
  description = "Create staging server"
  type        = bool
  default     = false
}

variable "staging_type" {
  description = "Instance type for staging server"
  default     = "DEV1-M"
}

############
# Management
############
variable "create_management" {
  description = "Create management server"
  type        = bool
  default     = false
}

variable "management_type" {
  description = "Instance type for management server"
  default     = "DEV1-M"
}

variable "management_ip" {
  description = "Management server IP for security group rules (use 0.0.0.0/0 if management server doesn't exist yet)"
  type        = string
  default     = "0.0.0.0/0" # Open by default, restrict after management server is created
}

############
# Authentik
############
variable "create_authentik" {
  description = "Create authentik server"
  type        = bool
  default     = true
}

variable "authentik_type" {
  description = "Instance type for authentik server"
  default     = "DEV1-M"
}

############
# Kubernetes
############
variable "create_kubernetes" {
  description = "Create Kubernetes cluster and required network resources"
  type        = bool
  default     = false
}

variable "k8s_node_type" {
  description = "Node type for Kubernetes cluster"
  type        = string
  default     = "DEV1-M"
}

variable "k8s_pool_size" {
  description = "Initial size for Kubernetes pool"
  type        = number
  default     = 3
}

variable "k8s_pool_min_size" {
  description = "Minimum size for Kubernetes pool"
  type        = number
  default     = 1
}

variable "k8s_pool_max_size" {
  description = "Maximum size for Kubernetes pool"
  type        = number
  default     = 6
}
