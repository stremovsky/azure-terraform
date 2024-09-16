output "cluster_name" {
  value = module.aks_cluster[0].cluster_name
}

output "aks_oidc_issuer_url" {
  value = module.aks_cluster[0].oidc_issuer_url
}

output "resource_group_name" {
  value       = var.aks_cluster_resource_group_name
  description = "The parent cluster resource group name"
}

output "kube_config" {
  value     = local_file.kubeconfig[0].filename
  sensitive = true
}

output "tetant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "workload_webapp_identity_client_id" {
  value = module.identity.workload_webapp_identity_client_id
}

output "keyvault_url" {
  value = module.keyvault.key_vault_uri
}

output current_user_principle_id {
  value = data.azurerm_client_config.current.object_id
}
