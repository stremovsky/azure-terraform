
resource "azurerm_public_ip" "bastion_ip" {
  name                = "bastion-public-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "my-bastion"
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