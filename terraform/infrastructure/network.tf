# Network resources for Kubernetes (conditional)
module "network" {
  count  = var.create_kubernetes ? 1 : 0
  source = "./modules/network"

  region = var.region

  providers = {
    scaleway = scaleway
  }
}

resource "scaleway_vpc_private_network" "network_prod" {
  name   = "network-prod"
  region = var.region

  tags = ["prod"]
}