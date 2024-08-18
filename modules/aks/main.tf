resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  node_resource_group = var.node_resource_group
  #private_cluster_enabled = true

  default_node_pool {
    name                        = "default"
    node_count                  = var.node_count
    vm_size                     = var.vm_size
    os_disk_size_gb             = 40
    enable_node_public_ip       = var.enable_node_public_ip
    temporary_name_for_rotation = "akstemppool"
    enable_auto_scaling         = true
    max_count                   = var.min_count
    min_count                   = var.max_count

    os_disk_type = "Managed"
    os_sku       = "Ubuntu"

    node_labels = {
      "ssh-access" = "true"
    }

    vnet_subnet_id = var.vnet_subnet_id
    #upgrade_settings {
    #  max_surge = "33%"
    #}
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy    = "azure"
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

resource "azurerm_kubernetes_cluster_node_pool" "windows_node_pool" {
  name                  = "windowspool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D2_v2"
  node_count            = 1
  os_disk_size_gb       = 100
  os_type               = "Windows"
  vnet_subnet_id        = var.vnet_subnet_id
}
