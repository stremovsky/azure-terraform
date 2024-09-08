output "aks_subnet_id" {
  value = data.azurerm_subnet.aks_subnet.id
}

output "bastion_subnet_id" {
  value = var.create_bastion_subnet ? azurerm_subnet.bastion_subnet[0].id : ""
}