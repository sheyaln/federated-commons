terraform {
  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.0"
    }
  }
}

# VPC for Kubernetes clusters
resource "scaleway_vpc" "vpc" {
  name = "vpc-prod"
  tags = ["prod"]
}

# Private network for Kubernetes clusters
resource "scaleway_vpc_private_network" "network" {
  name   = "network-prod"
  vpc_id = scaleway_vpc.vpc.id
  ipv4_subnet {
    subnet = "10.0.0.0/22"
  }
  tags = ["prod", "network"]
}
