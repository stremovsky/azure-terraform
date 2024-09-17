// Create Bastion Public IP resource
resource "azurerm_public_ip" "bastion_ip" {
  name                = "${var.bastion_name}-ip"
  tags                = var.tags
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

// Create Bastiopn Host resource
resource "azurerm_bastion_host" "bastion" {
  name                = var.bastion_name
  tags                = var.tags
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = var.vnet_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }

  depends_on = [
    azurerm_public_ip.bastion_ip
  ]
}