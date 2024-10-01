data "azurerm_client_config" "current" {}

# Create Azure Key Vault resource
resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  tags                = var.tags
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id

  soft_delete_retention_days = 7
  enable_rbac_authorization  = true
  sku_name                   = "standard"

  purge_protection_enabled      = var.purge_protection_enabled
  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    default_action             = var.network_acls.default_action
    bypass                     = var.network_acls.bypass
    virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
  }
}

# Grant RBAC permissions on the Azure Key Vault to the current user
resource "azurerm_role_assignment" "rbac" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.user_principle_id
}

# Wait for RBAC propagation
resource "time_sleep" "wait_for_rbac" {
  create_duration = "30s"
  depends_on      = [azurerm_role_assignment.rbac]
}

# Create a secret in the Azure Key Vault
#resource "azurerm_key_vault_secret" "test-secret" {
#  depends_on   = [time_sleep.wait_for_rbac]
#  name         = "test"
#  value        = "mysecretvalue"
#  key_vault_id = azurerm_key_vault.kv.id
#}

# Create a secret in the Azure Key Vault
#resource "azurerm_key_vault_secret" "secret2" {
#  depends_on   = [time_sleep.wait_for_rbac]
#  name         = "download-secret2"
#  value        = "mysecretvalue42"
#  key_vault_id = azurerm_key_vault.kv.id
#}

resource "azurerm_private_endpoint" "keyvault_private_endpoint" {
  name                = "kv-private-endpoint"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id # The subnet where AKS is deployed

  private_service_connection {
    name                           = "keyvault-privatelink"
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
}

resource "azurerm_private_dns_zone" "keyvault_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_dns_zone_link" {
  name                  = "keyvault-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault_dns_zone.name
  virtual_network_id    = var.vnet_id # The VNet where your AKS is deployed
}

resource "azurerm_private_dns_a_record" "keyvault_dns_record" {
  name                = "k-kv-pt-dev-eus1" # Name of your Key Vault
  zone_name           = azurerm_private_dns_zone.keyvault_dns_zone.name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  records             = [azurerm_private_endpoint.keyvault_private_endpoint.custom_dns_configs[0].ip_addresses[0]]
}