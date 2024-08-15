output "aks_subnet_id" {
  value = azurerm_subnet.aks_subnet.id
}

output "bastion_subnet_id" {
  value = var.enable_bastion ? azurerm_subnet.bastion_subnet[0].id : ""
}