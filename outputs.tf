output "ep_keyvault_name" {
  value = var.ep_enabled ? module.custom[0].key_vault_name : "null"
}

output "ep_workload_identity_name" {
  value = var.ep_enabled ? module.custom[0].workload_identity_name : "null"
}

output "ep_workload_identity_client_id" {
  value = var.ep_enabled ? module.custom[0].workload_identity_client_id : "null"
}

output "cluster_name" {
  value = var.aks_enabled ? module.aks_cluster[0].cluster_name : "null"
}

output "aks_oidc_issuer_url" {
  value = var.aks_enabled ? module.aks_cluster[0].oidc_issuer_url : "null"
}

output "resource_group_name" {
  value       = var.aks_cluster_resource_group_name
  description = "The parent cluster resource group name"
}

#output "kube_config" {
#  value     = local_file.kubeconfig[0].filename
#  sensitive = true
#}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "workload_identity_client_id" {
  value = module.identity.workload_identity_client_id
}

output "workload_identity_name" {
  value = module.identity.workload_identity_name
}

output "keyvault_url" {
  value = module.keyvault.key_vault_uri
}

output "keyvault_name" {
  value = module.keyvault.key_vault_name
}

output "current_user_principle_id" {
  value = data.azurerm_client_config.current.object_id
}

output "lb_public_ip" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}