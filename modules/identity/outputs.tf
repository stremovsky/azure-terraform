#output "workload_identity_sp_client_id" {
#  value = azuread_service_principal.workload_identity_sp.client_id
#}

#output "workload_identity_resource_id" {
#  value = azuread_service_principal.workload_identity_sp.id
#}

output "workload_nginx_identity_client_id" {
  value = azurerm_user_assigned_identity.workload_nginx_identity.client_id
}