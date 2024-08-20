output "aks_cluster_name" {
  value = module.aks_cluster[0].aks_cluster_name
}

output "aks_oidc_issuer_url" {
  value = module.aks_cluster[0].oidc_issuer_url
}

output "resource_group_name" {
  value       = var.resource_group_name
  description = "The name of the resource group"
}

output "kube_config" {
  value     = local_file.kubeconfig[0].filename
  sensitive = true
}

output "tetant_id" {
  value = module.keyvault.tenant_id
}

#output "workload_identity_sp_client_id" {
#  value = module.identity.workload_identity_sp_client_id
#}

#output "workload_identity_sp_resource_id" {
#  value = module.identity.workload_identity_resource_id
#}


output "workload_nginx_identity_client_id" {
  value = module.identity.workload_nginx_identity_client_id
}

output "keyvault_url" {
  value = module.keyvault.keyvault_url
}
