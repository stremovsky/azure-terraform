output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "kube_config" {
  description = "The Kubernetes config to access the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "kube_admin_config" {
  description = "The Kubernetes admin config to access the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
  sensitive   = true
}