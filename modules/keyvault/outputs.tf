output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "tenant_id" {
  value = azurerm_key_vault.kv.tenant_id
}
