data "azurerm_client_config" "current" {}

# Create Azure Key Vault resource
resource "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  tags                = var.tags
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id

  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  enable_rbac_authorization  = true
  sku_name                   = "standard"
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
#resource "azurerm_key_vault_secret" "example-secret" {
#  depends_on   = [time_sleep.wait_for_rbac]
#  name         = "secret3"
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
