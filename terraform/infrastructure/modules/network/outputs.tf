output "vpc_id" {
  description = "ID of the VPC"
  value       = scaleway_vpc.vpc.id
}

output "private_network_id" {
  description = "ID of the private network"
  value       = scaleway_vpc_private_network.network.id
}

output "private_network_subnet" {
  description = "Subnet of the private network"
  value       = scaleway_vpc_private_network.network.ipv4_subnet[0].subnet
}
