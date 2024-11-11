resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  tags                = var.tags
  location            = var.location
  dns_prefix          = var.dns_prefix
  resource_group_name = var.resource_group_name
  node_resource_group = var.node_resource_group
  #private_dns_zone_id     = var.private_dns_zone_id
  private_cluster_enabled = var.aks_private

  default_node_pool {
    name      = var.system_node_pool_name
    vm_size   = var.system_vm_size
    min_count = var.system_min_count
    max_count = var.system_max_count
    # do not enforce node count to kill existing nodes in cluster
    #node_count                  = var.system_node_count
    enable_node_public_ip       = var.enable_node_public_ip
    temporary_name_for_rotation = "akstemppool"
    enable_auto_scaling         = true
    vnet_subnet_id              = var.vnet_subnet_id
    os_sku                      = var.system_os_sku
    os_disk_type                = var.system_disk_type
    os_disk_size_gb             = var.system_disk_size
  }

  network_profile {
    network_plugin      = var.network_plugin
    network_policy      = var.network_policy
    network_plugin_mode = var.network_plugin_mode
    pod_cidr            = var.pod_cidr
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
    load_balancer_sku   = var.load_balancer_sku
  }

  workload_autoscaler_profile {
    keda_enabled = true
  }
  identity {
    //type = "SystemAssigned"
    type = var.identity.type
    //identity_ids = [var.identity.identity_id]
  }
  # Enable OIDC issuer URL
  oidc_issuer_enabled = true
  # Enable Azure AD Workload Identity
  workload_identity_enabled = true

  dynamic "linux_profile" {
    for_each = length(var.ssh_key_file) > 0 ? [true] : []
    content {
      admin_username = var.linux_admin_user
      ssh_key {
        key_data = file(var.ssh_key_file)
      }
    }
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "windows_node_pool" {
  count               = var.app_node_pool_enable ? 1 : 0
  name                = var.app_node_pool_name
  tags                = var.tags
  enable_auto_scaling = true
  vm_size             = var.app_vm_size
  os_disk_size_gb     = var.app_disk_size
  os_disk_type        = var.app_disk_type
  os_type             = var.app_os_type
  max_count           = var.app_max_count
  min_count           = var.app_min_count
  # do not enforce node count to kill existing nodes in cluster
  #node_count            = var.app_node_count
  vnet_subnet_id        = var.vnet_subnet_id
  enable_node_public_ip = var.enable_node_public_ip
  node_labels           = var.app_node_pool_labels
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
}

resource "azurerm_kubernetes_cluster_node_pool" "windows_gpu_node_pool" {
  count               = var.gpu_node_pool_enable ? 1 : 0
  name                = var.gpu_node_pool_name
  tags                = var.tags
  enable_auto_scaling = true
  vm_size             = var.gpu_vm_size
  os_disk_size_gb     = var.gpu_disk_size
  os_disk_type        = var.gpu_disk_type
  os_type             = var.gpu_os_type
  max_count           = var.gpu_max_count
  min_count           = var.gpu_min_count
  # do not enforce node count to kill existing nodes in cluster
  #node_count            = var.app_node_count
  vnet_subnet_id        = var.vnet_subnet_id
  enable_node_public_ip = var.enable_node_public_ip
  node_labels           = var.gpu_node_pool_labels
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  #node_taints           = [
  #      "sku=gpu:NoSchedule",
  #]
}

// Grant read access to the AKS subnet
resource "azurerm_role_assignment" "network_contributor" {
  #principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  #role_definition_name = "Network Contributor"
  #role_definition_name = "Reader"
  role_definition_name = "Owner"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  scope                = var.vnet_subnet_id
}

data "azurerm_virtual_machine_scale_set" "windows_app_vmss" {
  depends_on          = [azurerm_kubernetes_cluster_node_pool.windows_node_pool]
  name                = "aks${var.app_node_pool_name}"
  resource_group_name = var.node_resource_group
  #kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  #kubernetes_cluster_name = azurerm_kubernetes_cluster.aks.name
}

# resource "azurerm_managed_disk" "disk_d" {
#   name                 = "disk-d-2tb"
#   location             = var.location
#   resource_group_name  = var.node_resource_group
#   storage_account_type = "Standard_LRS"
#   disk_size_gb         = 128
#   create_option        = "Empty"
# }


# resource "azurerm_virtual_machine_scale_set_extension" "add_disk_d" {
#   name                         = "new-disk-d"
#   virtual_machine_scale_set_id = data.azurerm_virtual_machine_scale_set.windows_gpu_vmss.id
#   publisher = "Microsoft.Compute"
#   type      = "CustomScriptExtension"
#   #type_handler_version         = "2.0"
#   type_handler_version = "1.10"
#   settings = jsonencode({
#     "commandToExecute" = "powershell -command 'Add-DataDisk -LUN 0 -DiskId ${azurerm_managed_disk.disk_d.id}'"
#   })
# }

# resource "null_resource" "attach_disk_d" {
#   depends_on = [data.azurerm_virtual_machine_scale_set.windows_app_vmss]
#   # --sku : Underlying storage SKU.  Allowed values: PremiumV2_LRS, Premium_LRS,
#   # Premium_ZRS, StandardSSD_LRS, StandardSSD_ZRS, Standard_LRS, UltraSSD_LRS.
#   provisioner "local-exec" {
#     command = <<EOT
#       az vmss disk attach \
#         --resource-group ${var.node_resource_group} \
#         --vmss-name "aks${var.app_node_pool_name}" \
#         --size-gb 2048 \
#         --lun 0 \
#         --caching ReadWrite
#     EOT
#   }
# }
