provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = false
    }
  }
}

locals {
  keyvault_name          = "k-kv-${var.brand}-${var.environment}-${var.region_name}"
  workload_identity_name = "k-id-${var.brand}-${var.environment}-${var.region_name}"
  default_node_pool_name = "default-${var.brand}-${var.environment}-${var.region_name}"
  windows_node_pool_name = "wpool"
}


data "azurerm_subscription" "current" {
}

# Create Azure Resource Group id create_aks_resource_group variable is true
resource "azurerm_resource_group" "aks_rg" {
  count    = var.create_aks_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
}

#resource "azurerm_resource_group" "node_rg" {
#  count    = var.create_node_resource_group ? 1 : 0
#  name     = "MC_${var.resource_group_name}"
#  location = var.location
#}

# Load Azure Resource Group
data "azurerm_resource_group" "aks_rg" {
  name = var.create_aks_resource_group ? azurerm_resource_group.aks_rg[0].name : var.resource_group_name
}

#data "azurerm_resource_group" "node_rg" {
#  name = var.create_node_resource_group ? azurerm_resource_group.node_rg[0].name : "MC_${var.resource_group_name}"
#}

module "vnet" {
  source = "./modules/vnet"
  # check if vnet should be loaded from other resource group
  resource_group_name   = length(var.vnet_resource_group_name) > 0 ? var.vnet_resource_group_name : data.azurerm_resource_group.aks_rg.name
  location              = data.azurerm_resource_group.aks_rg.location
  create_bastion_subnet = var.enable_bastion
  create_subnet         = var.create_subnet
  create_vnet           = var.create_vnet

  subnet_name         = "kubernetes-eus1-playground"
  vnet_name           = var.vnet_name
  vnet_cidr           = "10.0.0.0/16"
  aks_subnet_cidr     = "10.0.36.0/22"
  bastion_subnet_cidr = "10.224.1.0/24"
}

# Create AKS cluster
module "aks_cluster" {
  count               = var.aks_enabled ? 1 : 0
  source              = "./modules/aks"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  #node_resource_group    = data.azurerm_resource_group.node_rg.name
  node_resource_group    = "MC_${var.resource_group_name}"
  default_node_pool_name = local.default_node_pool_name
  windows_node_pool_name = local.windows_node_pool_name
  location               = data.azurerm_resource_group.aks_rg.location
  enable_node_public_ip  = var.enable_node_public_ip
  cluster_name           = var.cluster_name
  dns_prefix             = var.dns_prefix
  default_vm_size        = var.default_vm_size
  vnet_subnet_id         = module.vnet.aks_subnet_id
  tags                   = var.tags
  service_cidr           = "172.16.16.0/24"
  dns_service_ip         = "172.16.16.10"
  pod_cidr               = "172.16.0.0/20"
  ssh_key_file           = ""
}

module "registry" {
  source                  = "./modules/registry"
  resource_group_name     = "devops-containerregistry"
  aks_kubelet_identity_id = module.aks_cluster[0].aks_kubelet_identity_id
  registry_name           = var.registry_name
}

module "keyvault" {
  source                  = "./modules/keyvault"
  keyvault_name           = local.keyvault_name
  resource_group_name     = data.azurerm_resource_group.aks_rg.name
  location                = data.azurerm_resource_group.aks_rg.location
  aks_kubelet_identity_id = module.aks_cluster[0].aks_kubelet_identity_id
}

module "identity" {
  source                 = "./modules/identity"
  location               = data.azurerm_resource_group.aks_rg.location
  keyvault_id            = module.keyvault.keyvault_id
  resource_group_name    = data.azurerm_resource_group.aks_rg.name
  oidc_issuer_url        = module.aks_cluster[0].oidc_issuer_url
  workload_identity_name = local.workload_identity_name
}

# Create Bastion host
module "bastion" {
  count               = var.enable_bastion ? 1 : 0
  source              = "./modules/bastion"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  location            = data.azurerm_resource_group.aks_rg.location

  # Networking
  vnet_subnet_id = module.vnet.bastion_subnet_id
}

# Allow SSH, ICMP
module "nsg" {
  count               = var.enable_nsg ? 1 : 0
  source              = "./modules/nsg"
  resourse_name       = "nsg-sg"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  #resource_group_name = module.aks_cluster[0].node_resource_group
  aks_node_resource_group_name = module.aks_cluster[0].node_resource_group
  #aks_resource_group_name = data.azurerm_resource_group.node_rg.name
  location = data.azurerm_resource_group.aks_rg.location

  # Networking
  aks_subnet_id = module.vnet.aks_subnet_id
}

# Write the kubeconfig to a file (optional)
resource "local_file" "kubeconfig" {
  count    = var.aks_enabled ? 1 : 0
  filename = "${path.module}/kubeconfig"
  content  = module.aks_cluster[0].kube_config
}
