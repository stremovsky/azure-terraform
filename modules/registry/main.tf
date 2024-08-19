#data "azurerm_container_registry" "registry" {
#  name = var.registry_name
#  resource_group_name = "devops-containerregistry"
#}

data "azurerm_resources" "registry" {
  #resource_group_name = "devops-containerregistry"
  resource_group_name = var.resource_group_name
  name                = var.registry_name
  type                = "Microsoft.ContainerRegistry/registries"
}

resource "azurerm_role_assignment" "acr_pull" {
  #principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  principal_id         = var.aks_kubelet_identity_id
  role_definition_name = "AcrPull"
  scope                = data.azurerm_resources.registry.resources.0.id
}
