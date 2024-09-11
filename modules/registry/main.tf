#data "azurerm_container_registry" "registry" {
#  name = var.registry_name
#  resource_group_name = var.resource_group_name
#}

# Load existing container registry
data "azurerm_resources" "registry" {
  resource_group_name = var.registry_resource_group_name
  name                = var.registry_name
  type                = "Microsoft.ContainerRegistry/registries"
}

# Add read access to container registry to kubelet identity
resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = var.aks_kubelet_identity_id
  role_definition_name = "AcrPull"
  scope                = data.azurerm_resources.registry.resources.0.id
}
