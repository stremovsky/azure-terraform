provider "azurerm" {
  features {}
}

data "azurerm_subscription" "current" {
}

resource "azurerm_resource_group" "aks_rg" {
  count    = var.create_aks_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_resource_group" "node_rg" {
  count    = var.create_node_resource_group ? 1 : 0
  name     = "MC_${var.resource_group_name}"
  location = var.location
}

data "azurerm_resource_group" "aks_rg" {
  name = var.create_aks_resource_group ? azurerm_resource_group.aks_rg[0].name : var.resource_group_name
}

data "azurerm_resource_group" "node_rg" {
  name = var.create_node_resource_group ? azurerm_resource_group.node_rg[0].name : "MC_${var.resource_group_name}"
}

module "vnet" {
  source              = "./modules/vnet"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  location            = data.azurerm_resource_group.aks_rg.location
  enable_bastion      = var.enable_bastion

  #vnet_cidr           = "10.0.0.0/16"
  vnet_cidr           = "10.224.0.0/12"
  aks_subnet_cidr     = "10.224.0.0/24"
  bastion_subnet_cidr = "10.224.1.0/24"
}

# Create AKS cluster
module "aks_cluster" {
  count                 = var.aks_enabled ? 1 : 0
  source                = "./modules/aks"
  resource_group_name   = data.azurerm_resource_group.aks_rg.name
  node_resource_group   = data.azurerm_resource_group.node_rg.name
  location              = data.azurerm_resource_group.aks_rg.location
  enable_node_public_ip = var.enable_node_public_ip
  aks_cluster_name      = var.aks_cluster_name
  dns_prefix            = var.dns_prefix
  node_count            = var.node_count
  min_count             = var.min_count
  max_count             = var.max_count
  vm_size               = var.vm_size
  vnet_subnet_id        = module.vnet.aks_subnet_id
  tags                  = var.tags
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
  location                = data.azurerm_resource_group.aks_rg.location

  # Networking
  aks_subnet_id = module.vnet.aks_subnet_id
}

# Write the kubeconfig to a file (optional)
resource "local_file" "kubeconfig" {
  count    = var.aks_enabled ? 1 : 0
  filename = "${path.module}/kubeconfig"
  content  = module.aks_cluster[0].kube_config
}
