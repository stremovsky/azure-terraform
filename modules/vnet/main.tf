resource "azurerm_virtual_network" "vnet" {
  count               = var.create_vnet ? 1 : 0
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]
}

data "azurerm_virtual_network" "vnet" {
  resource_group_name = var.resource_group_name
  name                = var.create_vnet ? azurerm_virtual_network.vnet[0].name : var.vnet_name
}

resource "azurerm_subnet" "aks_subnet" {
  count                = var.create_subnet ? 1 : 0
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = [var.aks_subnet_cidr]
}

data "azurerm_subnet" "aks_subnet" {
  resource_group_name  = var.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  name                 = var.create_subnet ? azurerm_subnet.aks_subnet[0].name : var.subnet_name
}

resource "azurerm_subnet" "bastion_subnet" {
  count                = var.enable_bastion ? 1 : 0
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = [var.bastion_subnet_cidr]
}