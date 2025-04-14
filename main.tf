locals {
  cluster_name           = "k-${var.environment_name}-${var.region_name}"
  subnet_name            = "k-${var.environment_name}-${var.region_name}"
  key_vault_name         = "k-kv-${var.whitelabel_short}-${var.environment_name}-${var.region_name}"
  workload_identity_name = "k-id-${var.whitelabel_short}-${var.environment_name}-${var.region_name}"
  nsg_resourse_name      = "k-nsg-${var.whitelabel_short}-${var.environment_name}-${var.region_name}"
  lb_public_ip_name      = "k-lbip-${var.whitelabel_short}-${var.environment_name}-${var.region_name}"
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
resource "azurerm_resource_group" "aks_rg0" {
  count    = var.create_aks_resource_group ? 1 : 0
  name     = var.aks_cluster_resource_group_name
  location = var.location
}

# Load Azure Resource Group
data "azurerm_resource_group" "aks_rg" {
  name = var.create_aks_resource_group ? azurerm_resource_group.aks_rg0[0].name : var.aks_cluster_resource_group_name
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
  resource_group_id   = data.azurerm_resource_group.aks_rg.id
  resource_group_name = data.azurerm_resource_group.aks_rg.name
  #node_resource_group    = data.azurerm_resource_group.node_rg.name
  node_resource_group   = "MC_${var.aks_cluster_resource_group_name}"
  system_node_pool_name = local.system_node_pool_name
  aks_private           = var.aks_private
  #private_dns_zone_id = module.kv_private_dns_zone.private_dns_zone_id

  location              = data.azurerm_resource_group.aks_rg.location
  enable_node_public_ip = var.enable_node_public_ip
  cluster_name          = local.cluster_name
  dns_prefix            = "aks${var.environment_name}"
  system_vm_size        = var.system_vm_size
  vnet_subnet_id        = module.vnet.aks_subnet_id
  lock_resources        = var.lock_resources
  tags                  = var.default_tags
  kubernetes_version    = var.kubernetes_version
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
  node_groups = var.aks_node_groups
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
  version = "7.7.0"

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

resource "azurerm_management_lock" "keyvalt_lock" {
  count      = var.lock_resources ? 1 : 0
  name       = "${local.key_vault_name}-lock"
  scope      = module.keyvault.key_vault_id
  lock_level = "CanNotDelete" # Other option is "ReadOnly"
  notes      = "This lock prevents accidental deletion of keyvault service"
}

data "azurerm_resources" "dns" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.vnet_resource_group_name
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

resource "azurerm_private_dns_zone" "keyvault_dns_zone" {
  count = length(data.azurerm_resources.dns.resources) == 0 ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name  = length(var.vnet_resource_group_name) > 0 ? var.vnet_resource_group_name : data.azurerm_resource_group.aks_rg.name
}

# Create Private Endpoint for Key Vault
module "keyvault_private_endpoint" {
  source  = "claranet/private-endpoint/azurerm"
  version = "7.1.1"

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
  #private_dns_zones_ids = [data.azurerm_resources.dns.resources.0.id]
  private_dns_zones_ids = [length(data.azurerm_resources.dns.resources) == 0 ? resource.azurerm_private_dns_zone.keyvault_dns_zone[0].id : data.azurerm_resources.dns.resources.0.id]
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
  lock_resources         = var.lock_resources
  resource_group_name    = data.azurerm_resource_group.aks_rg.name
  oidc_issuer_url        = var.aks_enabled ? module.aks_cluster[0].oidc_issuer_url : null
  workload_identity_name = local.workload_identity_name
}

resource "azurerm_public_ip" "lb_public_ip" {
  name                = local.lb_public_ip_name
  location            = data.azurerm_resource_group.aks_rg.location
  resource_group_name = var.aks_cluster_resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Add a management lock for the public IP to prevent accidental deletion or updates
resource "azurerm_management_lock" "lb_public_ip_lock" {
  count      = var.lock_resources ? 1 : 0
  name       = "${azurerm_public_ip.lb_public_ip.name}-lock"
  scope      = azurerm_public_ip.lb_public_ip.id
  lock_level = "CanNotDelete" # Other option is "ReadOnly"
  notes      = "This lock prevents accidental deletion of the public IP"
}

module "custom" {
  source                   = "./modules/custom"
  count                    = var.ep_enabled ? 1 : 0
  project_short_name       = "ep"
  whitelabel               = var.whitelabel
  aks_subnet_id            = module.vnet.aks_subnet_id
  whitelabel_short         = var.whitelabel_short
  environment_name         = var.environment_name
  region_name              = var.region_name
  lock_resources           = var.lock_resources
  location                 = data.azurerm_resource_group.aks_rg.location
  resource_group_name      = data.azurerm_resource_group.aks_rg.name
  vnet_resource_group_name = var.vnet_resource_group_name
  oidc_issuer_url          = var.aks_enabled ? module.aks_cluster[0].oidc_issuer_url : "null"
}

resource "null_resource" "setup_infra" {
  depends_on = [
    module.aks_cluster[0].aks_version,
    module.custom.workload_identity_client_id,
    module.identity.workload_identity_client_id
  ]
  triggers = {
    //always_run = timestamp()
    infrastructure_hash = sha256(join("", [
      var.ep_enabled ? module.custom[0].workload_identity_client_id : "null",
      var.aks_enabled ? module.aks_cluster[0].oidc_issuer_url : "null",
      data.azurerm_client_config.current.tenant_id,
      data.azurerm_client_config.current.object_id,
      (length(data.azurerm_resources.dns.resources) == 0) ? resource.azurerm_private_dns_zone.keyvault_dns_zone[0].id : data.azurerm_resources.dns.resources.0.id,
      module.identity.workload_identity_client_id,
      module.aks_cluster[0].aks_version,
      module.aks_cluster[0].aks_host,
      module.keyvault.key_vault_uri,
      module.keyvault.key_vault_id
    ]))
  }
  provisioner "local-exec" {
    command = "./setup-infra.sh && ./setup-base.sh"
  }
}

resource "null_resource" "setup_ep" {
  depends_on = [null_resource.setup_infra]
  count      = var.ep_enabled ? 1 : 0
  triggers = {
    //always_run = timestamp()
    infrastructure_hash = sha256(join("", [
      var.ep_enabled ? module.custom[0].workload_identity_client_id : "null",
      var.aks_enabled ? module.aks_cluster[0].oidc_issuer_url : "null",
      data.azurerm_client_config.current.tenant_id,
      data.azurerm_client_config.current.object_id,
      (length(data.azurerm_resources.dns.resources) == 0) ? resource.azurerm_private_dns_zone.keyvault_dns_zone[0].id : data.azurerm_resources.dns.resources.0.id,
      module.identity.workload_identity_client_id,
      module.aks_cluster[0].aks_version,
      module.aks_cluster[0].aks_host,
      module.keyvault.key_vault_uri,
      module.keyvault.key_vault_id
    ]))
  }
  provisioner "local-exec" {
    command = "./setup-ep.sh"
  }
}

resource "null_resource" "uninstall_ep" {
  depends_on = [null_resource.setup_infra]
  count      = var.ep_enabled ? 0 : 1
  triggers = {
    //always_run = timestamp()
    infrastructure_hash = sha256(join("", [
      var.ep_enabled ? module.custom[0].workload_identity_client_id : "null",
      var.aks_enabled ? module.aks_cluster[0].oidc_issuer_url : "null",
      data.azurerm_client_config.current.tenant_id,
      data.azurerm_client_config.current.object_id,
      (length(data.azurerm_resources.dns.resources) == 0) ? resource.azurerm_private_dns_zone.keyvault_dns_zone[0].id : data.azurerm_resources.dns.resources.0.id,
      module.identity.workload_identity_client_id,
      module.aks_cluster[0].aks_version,
      module.aks_cluster[0].aks_host,
      module.keyvault.key_vault_uri,
      module.keyvault.key_vault_id
    ]))
  }
  provisioner "local-exec" {
    command = "./uninstall-ep.sh"
  }
}
