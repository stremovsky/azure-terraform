locals {
  key_vault_name         = "k-kv-${var.project_short_name}-${var.environment_name}-${var.region_name}"
  workload_identity_name = "k-id-${var.project_short_name}-${var.environment_name}-${var.region_name}"
}

data "azurerm_client_config" "current" {}

# Load Azure Resource Group
data "azurerm_resource_group" "aks_rg" {
  name = var.aks_cluster_resource_group_name
}

module "keyvault" {
  source  = "claranet/keyvault/azurerm"
  version = "7.5.0"

  custom_name          = local.key_vault_name
  client_name          = var.whitelabel
  environment          = var.environment_name
  location             = data.azurerm_resource_group.aks_rg.location
  location_short       = data.azurerm_resource_group.aks_rg.location
  resource_group_name  = data.azurerm_resource_group.aks_rg.name
  stack                = "cust1"
  extra_tags           = var.default_tags
  default_tags_enabled = false

  rbac_authorization_enabled = true
  logs_destinations_ids      = []

  purge_protection_enabled = false

  # Current user should be here to be able to create keys and secrets
  admin_objects_ids = [
    data.azurerm_client_config.current.object_id
  ]

  # Specify Network ACLs
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"

    virtual_network_subnet_ids = [
      var.aks_subnet_id # Existing subnet where the service endpoint is configured
    ]
  }
}

data "azurerm_resources" "dns" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = length(var.vnet_resource_group_name) > 0 ? var.vnet_resource_group_name : data.azurerm_resource_group.aks_rg.name
  type                = "Microsoft.Network/privateDnsZones"
}

# Create Private Endpoint for Key Vault
module "keyvault_private_endpoint" {
  source  = "claranet/private-endpoint/azurerm"
  version = "7.0.3"

  location             = data.azurerm_resource_group.aks_rg.location
  location_short       = data.azurerm_resource_group.aks_rg.location
  client_name          = var.whitelabel
  environment          = var.environment_name
  stack                = "cust1"
  extra_tags           = var.default_tags
  default_tags_enabled = false

  resource_group_name = data.azurerm_resource_group.aks_rg.name

  name_suffix = "pv"

  subnet_id = var.aks_subnet_id

  target_resource  = module.keyvault.key_vault_id
  subresource_name = "vault"

  private_dns_zones_ids = [data.azurerm_resources.dns.resources.0.id]
}

resource "azurerm_private_dns_a_record" "keyvault_dns_record" {
  name                = local.key_vault_name # Name of your Key Vault
  zone_name           = "privatelink.vaultcore.azure.net"
  resource_group_name = length(var.vnet_resource_group_name) > 0 ? var.vnet_resource_group_name : data.azurerm_resource_group.aks_rg.name
  ttl                 = 3600
  records             = [module.keyvault_private_endpoint.private_endpoint_ip_address]
}

module "identity" {
  source                   = "../../modules/identity"
  tags                     = var.default_tags
  location                 = data.azurerm_resource_group.aks_rg.location
  keyvault_id              = module.keyvault.key_vault_id
  resource_group_name      = data.azurerm_resource_group.aks_rg.name
  oidc_issuer_url          = var.oidc_issuer_url
  workload_identity_name   = local.workload_identity_name
  serviceaccount_namespace = var.project_short_name
}