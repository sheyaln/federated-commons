# Production instance
module "tools_prod" {
  source = "./modules/compute"

  instance_name      = "tools-prod"
  instance_type      = var.prod_type
  image              = var.image
  disk_size          = 100
  disk_type          = "sbs_volume"
  private_network_id = scaleway_vpc_private_network.fc_network_prod.id
  tags               = ["tools", "prod"]
  protected          = true
  security_group_id  = scaleway_instance_security_group.tools_group.id
}

# Management instance (conditional)
module "management" {
  count  = var.create_management ? 1 : 0
  source = "./modules/compute"

  instance_name      = "management"
  instance_type      = var.management_type
  image              = var.image
  disk_size          = 80
  disk_type          = "sbs_volume"
  private_network_id = scaleway_vpc_private_network.fc_network_prod.id
  tags               = ["management"]
  security_group_id  = scaleway_instance_security_group.management_group.id
}


# Staging instance (conditional)
module "tools_staging" {
  count  = var.create_staging ? 1 : 0
  source = "./modules/compute"

  instance_name      = "tools-staging"
  instance_type      = var.staging_type
  image              = var.image
  disk_size          = 80
  disk_type          = "sbs_volume"
  private_network_id = scaleway_vpc_private_network.fc_network_prod.id
  tags               = ["tools", "staging"]
  security_group_id  = scaleway_instance_security_group.tools_group.id
}

module "authentik_prod" {
  source = "./modules/compute"

  instance_name      = "authentik-prod"
  instance_type      = var.authentik_type
  image              = var.image
  disk_size          = 45
  disk_type          = "sbs_volume"
  private_network_id = scaleway_vpc_private_network.fc_network_prod.id
  tags               = ["authentik", "prod"]
  security_group_id  = scaleway_instance_security_group.authentik_group.id
}
