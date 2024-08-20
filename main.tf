provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

data "azurerm_subscription" "current" {
}

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

data "azurerm_resource_group" "aks_rg" {
  name = var.create_aks_resource_group ? azurerm_resource_group.aks_rg[0].name : var.resource_group_name
}

#data "azurerm_resource_group" "node_rg" {
#  name = var.create_node_resource_group ? azurerm_resource_group.node_rg[0].name : "MC_${var.resource_group_name}"
#}

module "vnet" {
  source = "./modules/vnet"
  #resource_group_name = data.azurerm_resource_group.aks_rg.name
  resource_group_name = length(var.vnet_resource_group_name) > 0 ? var.vnet_resource_group_name : data.azurerm_resource_group.aks_rg.name
  location            = data.azurerm_resource_group.aks_rg.location
  enable_bastion      = var.enable_bastion
  create_subnet       = var.create_subnet
  create_vnet         = var.create_vnet

  vnet_name   = var.vnet_name
  vnet_cidr   = "10.0.0.0/16"
  subnet_name = "kubernetes-eus1-playground"
  #vnet_cidr           = "10.224.0.0/12"
  #vnet_subnet_id
  #aks_subnet_cidr     = "10.224.0.0/24"
  aks_subnet_cidr     = "10.0.36.0/22"
  bastion_subnet_cidr = "10.224.1.0/24"
}

# Create AKS cluster
module "aks_cluster" {
  count               = var.aks_enabled ? 1 : 0
  source              = "./modules/aks"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  #node_resource_group    = data.azurerm_resource_group.node_rg.name
  node_resource_group   = "MC_${var.resource_group_name}"
  location              = data.azurerm_resource_group.aks_rg.location
  enable_node_public_ip = var.enable_node_public_ip
  aks_cluster_name      = var.aks_cluster_name
  dns_prefix            = var.dns_prefix
  vm_size               = var.vm_size
  vnet_subnet_id        = module.vnet.aks_subnet_id
  tags                  = var.tags
  service_cidr          = "10.120.0.0/24"
  dns_service_ip        = "10.120.0.10"
  pod_cidr              = "192.168.0.0/16"
}

module "registry" {
  source                  = "./modules/registry"
  resource_group_name     = "devops-containerregistry"
  aks_kubelet_identity_id = module.aks_cluster[0].aks_kubelet_identity_id
  registry_name           = var.registry_name
}

module "keyvault" {
  source                  = "./modules/keyvault"
  keyvault_name           = "kuber-keyvault-test1"
  resource_group_name     = data.azurerm_resource_group.aks_rg.name
  location                = data.azurerm_resource_group.aks_rg.location
  aks_kubelet_identity_id = module.aks_cluster[0].aks_kubelet_identity_id
}

module "identity" {
  source              = "./modules/identity"
  location            = data.azurerm_resource_group.aks_rg.location
  keyvault_id         = module.keyvault.keyvault_id
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  oidc_issuer_url     = module.aks_cluster[0].oidc_issuer_url
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
  aks_resource_group_name = module.aks_cluster[0].node_resource_group
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
