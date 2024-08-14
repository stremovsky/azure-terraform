
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix
  #private_cluster_enabled = true

  default_node_pool {
    name                  = "default"
    node_count            = var.node_count
    vm_size               = var.vm_size
    os_disk_size_gb       = 40
    enable_node_public_ip = false
    temporary_name_for_rotation = "akstemppool"

    os_disk_type = "Managed"
    os_sku       = "Ubuntu"

    enable_auto_scaling = true
    max_count           = 3
    min_count           = 1

    node_labels = {
      "ssh-access" = "true"
    }

    #upgrade_settings {
    #  max_surge = "33%"
    #}
  }

  identity {
    type = "SystemAssigned"
  }

  linux_profile {
    admin_username = "aksadmin"

    ssh_key {
      key_data = file("~/.ssh/azurekey.pub")
    }
  }

  tags = var.tags
}