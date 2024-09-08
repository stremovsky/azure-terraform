# Network Security Group allowing SSH and ICMP protocols

resource "azurerm_network_security_group" "nsg" {
  name                = var.resourse_name
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-ICMP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = var.aks_subnet_id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

data "azurerm_resources" "aks_nsg" {
  resource_group_name = var.aks_node_resource_group_name
  type                = "Microsoft.Network/networkSecurityGroups"
}

resource "azurerm_network_security_rule" "ssh_rule" {
  name                        = "Allow-SSH"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.aks_node_resource_group_name
  network_security_group_name = data.azurerm_resources.aks_nsg.resources.0.name
}

resource "azurerm_network_security_rule" "icmp_rule" {
  name                        = "Allow-ICMP"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Icmp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.aks_node_resource_group_name
  network_security_group_name = data.azurerm_resources.aks_nsg.resources.0.name
}