output "key_vault_name" {
  value = module.keyvault.key_vault_name
}

output "workload_identity_name" {
    value = local.workload_identity_name
}

output "workload_identity_client_id" {
  value = module.identity.workload_identity_client_id
}