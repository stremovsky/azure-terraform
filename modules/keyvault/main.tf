data "azurerm_client_config" "current" {}

# Azure Key Vault
resource "azurerm_key_vault" "kv" {
  name                = var.keyvault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = var.aks_kubelet_identity_id

    secret_permissions = [
      "Get",
    ]
  }
}

resource "azurerm_key_vault_secret" "example-secret" {
  name         = "secret1"
  value        = "mysecretvalue"
  key_vault_id = azurerm_key_vault.kv.id
}
