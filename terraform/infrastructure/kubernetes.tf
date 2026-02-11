# Kubernetes cluster - DISABLED
# Module was removed - uncomment and recreate module if needed
#
# module "kubernetes" {
#   count  = var.create_kubernetes ? 1 : 0
#   source = "./modules/kubernetes"
#
#   region                    = var.region
#   private_network_id        = module.network[0].private_network_id
#   use_shared_cluster        = true
#   create_production_k8s     = false
#   staging_k8s_node_type     = var.k8s_node_type
#   staging_k8s_pool_size     = var.k8s_pool_size
#   staging_k8s_pool_min_size = var.k8s_pool_min_size
#   staging_k8s_pool_max_size = var.k8s_pool_max_size
#   shared_k8s_node_type      = var.k8s_node_type
#   shared_k8s_pool_size      = var.k8s_pool_size
#   shared_k8s_pool_min_size  = var.k8s_pool_min_size
#   shared_k8s_pool_max_size  = var.k8s_pool_max_size
#
#   providers = {
#     scaleway = scaleway
#   }
# }
