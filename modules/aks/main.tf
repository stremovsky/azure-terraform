resource "azurerm_kubernetes_cluster" "aks" {
  name                    = var.aks_cluster_name
  location                = var.location
  dns_prefix              = var.dns_prefix
  resource_group_name     = var.resource_group_name
  node_resource_group     = var.node_resource_group
  private_cluster_enabled = var.aks_private

  default_node_pool {
    os_disk_size_gb             = 40
    name                        = "default"
    vm_size                     = var.vm_size
    min_count                   = var.system_min_count
    max_count                   = var.system_max_count
    node_count                  = var.system_node_count
    enable_node_public_ip       = var.enable_node_public_ip
    temporary_name_for_rotation = "akstemppool"
    enable_auto_scaling         = true

    os_sku       = "Ubuntu"
    os_disk_type = "Managed"

    node_labels = {
      "ssh-access" = "true"
    }
    vnet_subnet_id = var.vnet_subnet_id
  }

  network_profile {
    network_plugin      = "azure"
    load_balancer_sku   = "standard"
    network_policy      = "azure"
    network_plugin_mode = "overlay"
    pod_cidr            = var.pod_cidr
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip

  }

  identity {
    type = "SystemAssigned"
  }
  # Enable OIDC issuer URL
  oidc_issuer_enabled = true
  # Enable Azure AD Workload Identity
  workload_identity_enabled = true

  #linux_profile {
  #  admin_username = "aksadmin"
  #  ssh_key {
  #    key_data = file(var.ssh_key_file)
  #  }
  #}

  dynamic "linux_profile" {
    for_each = length(var.ssh_key_file) > 0 ? [true] : []
    content {
      admin_username = "aksadmin"
      ssh_key {
        key_data = file(var.ssh_key_file)
      }
    }
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "windows_node_pool" {
  name                  = "wipool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  enable_auto_scaling   = true
  vm_size               = "Standard_D4_v5"
  os_disk_size_gb       = 100
  os_type               = var.app_os_type
  max_count             = var.app_max_count
  min_count             = var.app_min_count
  node_count            = var.app_node_count
  vnet_subnet_id        = var.vnet_subnet_id
  node_labels = {
    "download" = "true"
  }
}
