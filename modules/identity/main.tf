# Create a User Assignes Identity
resource "azurerm_user_assigned_identity" "workload_webapp_identity" {
  location            = var.location
  resource_group_name = var.resource_group_name
  name                = var.workload_identity_name
  tags                = var.tags
}

# Assign Key Vault Secrets User role to the Service Principal
resource "azurerm_role_assignment" "kv_access" {
  #principal_id         = azuread_service_principal.workload_identity_sp.object_id
  principal_id         = azurerm_user_assigned_identity.workload_webapp_identity.principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = var.keyvault_id
  principal_type       = "ServicePrincipal"
}

# Assign Kubernetes Service Account to use Workload Identity created above
resource "azurerm_federated_identity_credential" "workload_federated_identity" {
  depends_on = [azurerm_role_assignment.kv_access]
  #count = var.oidc_issuer_url == null ? 0 : 1
  name                = "${var.workload_identity_name}-federated"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  parent_id           = azurerm_user_assigned_identity.workload_webapp_identity.id
  subject             = "system:serviceaccount:${var.serviceaccount_namespace}:${var.workload_identity_name}"
  issuer              = var.oidc_issuer_url
}

resource "azurerm_management_lock" "managed_identity_lock" {
  count      = var.lock_resources ? 1 : 0
  name       = "${var.workload_identity_name}-lock"
  scope      = azurerm_user_assigned_identity.workload_webapp_identity.id
  lock_level = "CanNotDelete" # Other option is "ReadOnly"
  notes      = "This lock prevents accidental deletion of managed identity"
}