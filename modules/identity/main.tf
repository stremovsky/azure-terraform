# Azure AD Application for Workload Identity
#resource "azuread_application" "workload_identity_app" {
#  display_name = "workload-identity-app"
#  #owners       = [data.azuread_client_config.current.object_id]
#}

# Service Principal for Workload Identity
#resource "azuread_service_principal" "workload_identity_sp" {
#  client_id                    = azuread_application.workload_identity_app.client_id
#  app_role_assignment_required = false
#  #owners                       = [data.azuread_client_config.current.object_id]
#}

resource "azurerm_user_assigned_identity" "workload_nginx_identity" {
  location            = var.location
  name                = "workload-nginx-identity"
  resource_group_name = var.resource_group_name
}

# Assign Key Vault Secrets User role to the Service Principal
resource "azurerm_role_assignment" "kv_access" {
  #principal_id         = azuread_service_principal.workload_identity_sp.object_id
  principal_id         = azurerm_user_assigned_identity.workload_nginx_identity.principal_id
  role_definition_name = "Key Vault Secrets User"
  scope                = var.keyvault_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_federated_identity_credential" "workload_federated_identity" {
  name                = "workload-federated-identity"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  parent_id           = azurerm_user_assigned_identity.workload_nginx_identity.id
  subject             = "system:serviceaccount:default:nginx-service-account"
  issuer              = var.oidc_issuer_url
}
