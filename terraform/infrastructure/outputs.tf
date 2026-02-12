# Output IP addresses for all instances
output "tools_prod_ip" {
  description = "Public IP address of the production server"
  value       = module.tools_prod.ip_address
}

output "tools_prod_private_ip" {
  description = "Private network IP address of the production server"
  value       = module.tools_prod.private_ip
}

output "management_ip" {
  description = "Public IP address of the management server"
  value       = var.create_management ? module.management[0].ip_address : ""
}

output "management_private_ip" {
  description = "Private network IP address of the management server"
  value       = var.create_management ? module.management[0].private_ip : ""
}

output "tools_staging_ip" {
  description = "Public IP address of the staging server (if created)"
  value       = var.create_staging ? module.tools_staging[0].ip_address : ""
}

output "tools_staging_private_ip" {
  description = "Private network IP address of the staging server (if created)"
  value       = var.create_staging ? module.tools_staging[0].private_ip : ""
}

output "authentik_prod_ip" {
  description = "Public IP address of the authentik server"
  value       = var.create_authentik ? module.authentik_prod.ip_address : ""
}

output "authentik_prod_private_ip" {
  description = "Private network IP address of the authentik server"
  value       = var.create_authentik ? module.authentik_prod.private_ip : ""
}

# Generate Ansible inventory from Terraform state
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.ini.tftpl", {
    management_ip     = var.create_management ? module.management[0].ip_address : ""
    tools_prod_ip     = module.tools_prod.ip_address
    authentik_prod_ip = var.create_authentik ? module.authentik_prod.ip_address : ""
    staging_ip        = var.create_staging ? module.tools_staging[0].ip_address : ""
  })
  filename        = "${path.module}/../../ansible/inventory.ini"
  file_permission = "0644"
}

