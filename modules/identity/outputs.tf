output "workload_webapp_identity_client_id" {
  value = azurerm_user_assigned_identity.workload_webapp_identity.client_id
}

output "workload_identity_name" {
  value = var.workload_identity_name
}