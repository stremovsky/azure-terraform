output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.k.name
}

output "aks_kubelet_identity_id" {
  value = azurerm_kubernetes_cluster.k.kubelet_identity[0].object_id
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.k.node_resource_group
}

output "kube_config" {
  description = "The Kubernetes config to access the AKS cluster"
  value       = azurerm_kubernetes_cluster.k.kube_config_raw
  sensitive   = true
}

output "kube_admin_config" {
  description = "The Kubernetes admin config to access the AKS cluster"
  value       = azurerm_kubernetes_cluster.k.kube_admin_config_raw
  sensitive   = true
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.k.oidc_issuer_url
}