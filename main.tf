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
  gpu_node_pool_name = "wingpu"
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

/*
module "kv_private_dns_zone" {
  source  = "claranet/private-endpoint/azurerm//modules/private-dns-zone"
  version = "7.0.3"

  stack                = "stack1"
  extra_tags           = var.default_tags
  default_tags_enabled = false
  resource_group_name  = data.azurerm_resource_group.aks_rg.name
  environment          = var.environment_name

  private_dns_zone_name      = "${var.environment_name}.privatelink.eastus.azmk8s.io"
  private_dns_zone_vnets_ids = [module.vnet.vnet_id]
}

# User Assigned Managed Identity (UAMI)
resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "aks-identity-${var.environment_name}"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  location            = data.azurerm_resource_group.aks_rg.location
}

# Assign Role to the Managed Identity to manage the Private DNS Zone
resource "azurerm_role_assignment" "dns_zone_contributor" {
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  role_definition_name = "Private DNS Zone Contributor"
  scope                = module.kv_private_dns_zone.private_dns_zone_id
}

resource "azurerm_role_assignment" "network_contributor" {
  role_definition_name = "Owner"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  scope                = module.vnet.aks_subnet_id
}
*/

# Create AKS cluster
module "aks_cluster" {
  count               = var.aks_enabled ? 1 : 0
  source              = "./modules/aks"
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  #node_resource_group    = data.azurerm_resource_group.node_rg.name
  node_resource_group   = "MC_${var.aks_cluster_resource_group_name}"
  system_node_pool_name = local.system_node_pool_name

  aks_private = var.aks_private
  #private_dns_zone_id = module.kv_private_dns_zone.private_dns_zone_id

  app_node_pool_name   = local.app_node_pool_name
  gpu_node_pool_name   = local.gpu_node_pool_name
  app_node_pool_enable = var.app_node_pool_enable
  gpu_node_pool_enable = var.gpu_node_pool_enable
  app_node_pool_labels = var.app_node_pool_labels
  gpu_node_pool_labels = var.gpu_node_pool_labels

  location              = data.azurerm_resource_group.aks_rg.location
  enable_node_public_ip = var.enable_node_public_ip
  cluster_name          = local.cluster_name
  dns_prefix            = "aks${var.environment_name}"
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

  identity = {
    type = "SystemAssigned"
    #type = "UserAssigned"
    # Reference the UAMI
    #identity_id = azurerm_user_assigned_identity.aks_identity.id
  }
}

module "registry" {
  source                  = "./modules/registry"
  count                   = var.aks_enabled ? 1 : 0
  registry_name           = var.registry_name
  tags                    = var.default_tags
  create_registry         = var.create_registry
  aks_kubelet_identity_id = module.aks_cluster[0].aks_kubelet_identity_id
  location                = data.azurerm_resource_group.aks_rg.location
  resource_group_name     = var.registry_resource_group_name
}

/*
module "keyvault" {
  source                  = "./modules/keyvault"
  key_vault_name          = local.key_vault_name
  tags                    = var.default_tags
  tenant_id               = data.azurerm_client_config.current.tenant_id
  user_principle_id       = data.azurerm_client_config.current.object_id
  resource_group_name     = data.azurerm_resource_group.aks_rg.name
  location                = data.azurerm_resource_group.aks_rg.location
  aks_kubelet_identity_id = module.aks_cluster[0].aks_kubelet_identity_id

  subnet_id = module.vnet.aks_subnet_id
  vnet_id   = module.vnet.vnet_id

  public_network_access_enabled = false
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"

    virtual_network_subnet_ids = [
      module.vnet.aks_subnet_id # Existing subnet where the service endpoint is configured
    ]
  }
}
*/

module "keyvault" {
  source  = "claranet/keyvault/azurerm"
  version = "7.5.0"

  custom_name          = local.key_vault_name
  client_name          = var.whitelabel
  environment          = var.environment_name
  location             = data.azurerm_resource_group.aks_rg.location
  location_short       = data.azurerm_resource_group.aks_rg.location
  resource_group_name  = data.azurerm_resource_group.aks_rg.name
  stack                = "stack1"
  extra_tags           = var.default_tags
  default_tags_enabled = false


  rbac_authorization_enabled = true
  logs_destinations_ids      = []

  purge_protection_enabled = false

  # WebApp or other applications Object IDs
  #  reader_objects_ids = [
  #var.webapp_service_principal_id
  #  ]

  # Current user should be here to be able to create keys and secrets
  admin_objects_ids = [
    data.azurerm_client_config.current.object_id
  ]

  # Specify Network ACLs
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"

    virtual_network_subnet_ids = [
      module.vnet.aks_subnet_id # Existing subnet where the service endpoint is configured
    ]
  }
}

data "azurerm_resources" "dns" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = length(var.vnet_resource_group_name) > 0 ? var.vnet_resource_group_name : data.azurerm_resource_group.aks_rg.name
  type                = "Microsoft.Network/privateDnsZones"
}

/*
module "kv_private_dns_zone" {
  source  = "claranet/private-endpoint/azurerm//modules/private-dns-zone"
  version = "7.0.3"

  #count = length(data.azurerm_resources.dns.resources) == 0 ? 1 : 0
  #lifecycle {
  #  prevent_destroy = true  # Prevent deletion during future runs
  #}

  stack                = "stack1"
  extra_tags           = var.default_tags
  default_tags_enabled = false
  resource_group_name  = length(var.vnet_resource_group_name) > 0 ? var.vnet_resource_group_name : data.azurerm_resource_group.aks_rg.name
  environment          = var.environment_name

  private_dns_zone_name      = "privatelink.vaultcore.azure.net"
  private_dns_zone_vnets_ids = [module.vnet.vnet_id]
}
*/

# Create Private Endpoint for Key Vault
module "keyvault_private_endpoint" {
  source  = "claranet/private-endpoint/azurerm"
  version = "7.0.3"

  location             = data.azurerm_resource_group.aks_rg.location
  location_short       = data.azurerm_resource_group.aks_rg.location
  client_name          = var.whitelabel
  environment          = var.environment_name
  stack                = "stack1"
  extra_tags           = var.default_tags
  default_tags_enabled = false

  resource_group_name = data.azurerm_resource_group.aks_rg.name

  name_suffix = "pv"

  #custom_private_endpoint_nic_name = "bar"

  subnet_id = module.vnet.aks_subnet_id

  target_resource  = module.keyvault.key_vault_id
  subresource_name = "vault"

  #private_dns_zones_names     = ["privatelink.vaultcore.azure.net"]
  #private_dns_zones_vnets_ids = [module.vnet.vnet_id]
  #private_dns_zones_ids = [length(data.azurerm_resources.dns.resources) == 0 ? module.kv_private_dns_zone[0].private_dns_zone_id : data.azurerm_resources.dns.resources.0.id]
  private_dns_zones_ids = [data.azurerm_resources.dns.resources.0.id]
  #private_dns_zones_ids = [module.kv_private_dns_zone[0].private_dns_zone_id]
}


resource "azurerm_private_dns_a_record" "keyvault_dns_record" {
  name                = local.key_vault_name # Name of your Key Vault
  zone_name           = "privatelink.vaultcore.azure.net"
  resource_group_name = length(var.vnet_resource_group_name) > 0 ? var.vnet_resource_group_name : data.azurerm_resource_group.aks_rg.name
  ttl                 = 3600
  records             = [module.keyvault_private_endpoint.private_endpoint_ip_address]
}

module "identity" {
  source                 = "./modules/identity"
  tags                   = var.default_tags
  location               = data.azurerm_resource_group.aks_rg.location
  keyvault_id            = module.keyvault.key_vault_id
  resource_group_name    = data.azurerm_resource_group.aks_rg.name
  oidc_issuer_url        = var.aks_enabled ? module.aks_cluster[0].oidc_issuer_url : null
  workload_identity_name = local.workload_identity_name
}

# Create Bastion host - not used
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

# Allow SSH, ICMP - not used
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
