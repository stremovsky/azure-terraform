provider "azurerm" {
  features {}
}

module "aks_cluster" {
  count               = var.aks_enabled ? 1 : 0
  source              = "./modules/aks"
  resource_group_name = var.resource_group_name
  location            = var.location
  aks_cluster_name    = var.aks_cluster_name
  dns_prefix          = var.dns_prefix
  node_count          = var.node_count
  vm_size             = var.vm_size
  tags                = var.tags
}

# Write the kubeconfig to a file (optional)
resource "local_file" "kubeconfig" {
  count    = var.aks_enabled ? 1 : 0
  filename = "${path.module}/kubeconfig"
  content  = module.aks_cluster[0].kube_config
}
