output "aks_cluster_name" {
  value = module.aks_cluster[0].aks_cluster_name
}

output "resource_group_name" {
  value       = var.resource_group_name
  description = "The name of the resource group"
}

output "kube_config" {
  value     = local_file.kubeconfig[0].filename
  sensitive = true
}