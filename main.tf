locals {
  cluster_name           = "k-${var.environment_name}-${var.region_name}"
  subnet_name            = "k-${var.environment_name}-${var.region_name}"
  key_vault_name         = "k-kv-${var.whitelabel_short}-${var.environment_name}-${var.region_name}"
  workload_identity_name = "k-id-${var.whitelabel_short}-${var.environment_name}-${var.region_name}"
  nsg_resourse_name      = "k-nsg-${var.whitelabel_short}-${var.environment_name}-${var.region_name}"
  bastion_name           = "k-bastion-${var.whitelabel_short}-${var.environment_name}-${var.region_name}"
  # For Linux node pools, the length must be between 1-12 characters.
  system_node_pool_name = "default"
  # For Windows node pools, the length must be between 1-6 characters.
  app_node_pool_name = "wpool"
}

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

data "azurerm_client_config" "current" {}

# Create Azure Resource Group id create_aks_resource_group variable is true
resource "azurerm_resource_group" "aks_rg" {
  count    = var.create_aks_resource_group ? 1 : 0
  name     = var.aks_cluster_resource_group_name
  location = var.location
}

# Load Azure Resource Group
data "azurerm_resource_group" "aks_rg" {
  name = var.create_aks_resource_group ? azurerm_resource_group.aks_rg[0].name : var.aks_cluster_resource_group_name
}

module "vnet" {
  source = "./modules/vnet"
  # check if vnet should be loaded from other resource group
  resource_group_name   = length(var.vnet_resource_group_name) > 0 ? var.vnet_resource_group_name : data.azurerm_resource_group.aks_rg.name
  location              = data.azurerm_resource_group.aks_rg.location
  create_bastion_subnet = var.enable_bastion
  create_subnet         = var.create_subnet
  create_vnet           = var.create_vnet
  tags                  = var.default_tags
  subnet_name           = local.subnet_name
  vnet_name             = var.vnet_name
  vnet_cidr             = var.vnet_cidr
  aks_subnet_cidr       = var.aks_nodes_subnet_cidr
  bastion_subnet_cidr   = var.bastion_subnet_cidr
}

# Create AKS cluster
module "aks_cluster" {
  count               = var.aks_enabled ? 1 : 0
  source              = "./modules/aks"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  #node_resource_group    = data.azurerm_resource_group.node_rg.name
  node_resource_group   = "MC_${var.aks_cluster_resource_group_name}"
  system_node_pool_name = local.system_node_pool_name
  app_node_pool_name    = local.app_node_pool_name
  app_node_pool_labels  = var.app_node_pool_labels
  location              = data.azurerm_resource_group.aks_rg.location
  enable_node_public_ip = var.enable_node_public_ip
  cluster_name          = local.cluster_name
  dns_prefix            = var.dns_prefix
  system_vm_size        = var.system_vm_size
  vnet_subnet_id        = module.vnet.aks_subnet_id
  tags                  = var.default_tags
  #  "172.16.16.0/24"
  service_cidr = var.aks_services_subnet_cidr
  # "172.16.16.10"
  dns_service_ip = var.aks_dns_server_ip
  # "172.16.0.0/20"
  pod_cidr     = var.aks_pods_subnet_cidr
  ssh_key_file = ""
}

module "registry" {
  source                  = "./modules/registry"
  registry_name           = var.registry_name
  tags                    = var.default_tags
  create_registry         = var.create_registry
  aks_kubelet_identity_id = module.aks_cluster[0].aks_kubelet_identity_id
  location                = data.azurerm_resource_group.aks_rg.location
  resource_group_name     = var.registry_resource_group_name
}

module "keyvault" {
  source                  = "./modules/keyvault"
  key_vault_name          = local.key_vault_name
  tags                    = var.default_tags
  tenant_id               = data.azurerm_client_config.current.tenant_id
  user_principle_id       = data.azurerm_client_config.current.object_id
  resource_group_name     = data.azurerm_resource_group.aks_rg.name
  location                = data.azurerm_resource_group.aks_rg.location
  aks_kubelet_identity_id = module.aks_cluster[0].aks_kubelet_identity_id
}

#module "keyvault" {
#  source  = "claranet/keyvault/azurerm"
#  version = "7.5.0"

#  custom_name         = local.keyvault_name
#  client_name         = var.whitelabel
#  environment         = var.environment_name
#  location            = data.azurerm_resource_group.aks_rg.location
#  location_short      = data.azurerm_resource_group.aks_rg.location
#  resource_group_name = data.azurerm_resource_group.aks_rg.name
#  stack               = "stack1"

#  rbac_authorization_enabled = true
#  logs_destinations_ids = []

# WebApp or other applications Object IDs
#  reader_objects_ids = [
#    #var.webapp_service_principal_id
#  ]

# Current user should be here to be able to create keys and secrets
#  admin_objects_ids = [
#    data.azurerm_client_config.current.object_id
#  ]

# Specify Network ACLs
#  network_acls = {
#    bypass         = "AzureServices"
#    default_action = "Deny" # was Allow
#  }
#}

module "identity" {
  source                 = "./modules/identity"
  tags                   = var.default_tags
  location               = data.azurerm_resource_group.aks_rg.location
  keyvault_id            = module.keyvault.key_vault_id
  resource_group_name    = data.azurerm_resource_group.aks_rg.name
  oidc_issuer_url        = module.aks_cluster[0].oidc_issuer_url
  workload_identity_name = local.workload_identity_name
}

# Create Bastion host
module "bastion" {
  count               = var.enable_bastion ? 1 : 0
  source              = "./modules/bastion"
  bastion_name        = local.bastion_name
  tags                = var.default_tags
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  location            = data.azurerm_resource_group.aks_rg.location

  # Networking
  vnet_subnet_id = module.vnet.bastion_subnet_id
}

# Allow SSH, ICMP
module "nsg" {
  count               = var.enable_nsg ? 1 : 0
  source              = "./modules/nsg"
  resourse_name       = local.nsg_resourse_name
  tags                = var.default_tags
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  #resource_group_name = module.aks_cluster[0].node_resource_group
  aks_node_resource_group_name = module.aks_cluster[0].node_resource_group
  #aks_resource_group_name = data.azurerm_resource_group.node_rg.name
  location = data.azurerm_resource_group.aks_rg.location
  # Networking
  aks_subnet_id = module.vnet.aks_subnet_id
}

# Write the kubeconfig to a file (optional)
#resource "local_file" "kubeconfig" {
#  count    = var.aks_enabled ? 1 : 0
#  filename = "${path.module}/kubeconfig"
#  content  = module.aks_cluster[0].kube_config
#}
