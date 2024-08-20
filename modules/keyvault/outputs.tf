output "keyvault_id" {
  value = azurerm_key_vault.kv.id
}

output "keyvault_url" {
  value = azurerm_key_vault.kv.vault_uri
}

output "tenant_id" {
  value = azurerm_key_vault.kv.tenant_id
}
