# Create Azure Container Registry
resource "azurerm_container_registry" "acr" {
  count               = var.create_registry ? 1 : 0
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = var.admin_enabled
  tags                = var.tags
}

data "azurerm_container_registry" "existing_registry" {
  count               = var.create_registry ? 0 : 1
  name                = var.registry_name
  resource_group_name = var.resource_group_name
}

# Local to safely select ACR ID
locals {
  acr_id = var.create_registry ? azurerm_container_registry.acr[0].id : data.azurerm_container_registry.existing_registry[0].id
}

# Add read access to container registry to kubelet identity
resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = var.aks_kubelet_identity_id
  role_definition_name = "AcrPull"
  scope                = local.acr_id
  #scope                = (var.create_registry == 1) ? azurerm_container_registry.acr[0].id : data.azurerm_container_registry.existing_registry[0].id
}
