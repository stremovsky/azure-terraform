resource "azurerm_kubernetes_cluster" "aks" {
  name                    = var.cluster_name
  tags                    = var.tags
  location                = var.location
  dns_prefix              = var.dns_prefix
  resource_group_name     = var.resource_group_name
  node_resource_group     = var.node_resource_group
  private_cluster_enabled = var.aks_private
  kubernetes_version      = var.kubernetes_version

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
    orchestrator_version        = var.kubernetes_version
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

resource "azurerm_management_lock" "aks_lock" {
  count      = var.lock_resources ? 1 : 0
  name       = "${var.cluster_name}-lock"
  scope      = azurerm_kubernetes_cluster.aks.id
  lock_level = "CanNotDelete" # Other option is "ReadOnly"
  notes      = "This lock prevents accidental deletion of AKS cluster"
}

resource "azurerm_management_lock" "default_node_pool_lock" {
  name       = "${var.cluster_name}-def-lock"
  scope      = "${azurerm_kubernetes_cluster.aks.id}/agentPools/default"
  lock_level = "CanNotDelete"
  notes      = "This lock prevents deletion of the default node pool"
}

resource "azurerm_management_lock" "mc_resource_group_lock" {
  count      = var.lock_resources ? 1 : 0
  name       = "${var.cluster_name}-mc-lock"
  #"/subscriptions/fdacd616-05ae-42d7-aa8b-ac3d67249b0a/resourceGroups/MC_k-playground-eus1"
  scope      = azurerm_kubernetes_cluster.aks.node_resource_group_id
  lock_level = "CanNotDelete" # Other option is "ReadOnly"
  notes      = "This lock prevents accidental deletion of AKS mc recource group"
}

# Retrieve the default Load Balancer
# data "azurerm_resources" "aks_default_lb" {
#   type                = "Microsoft.Network/loadBalancers"
#   resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
#   # Filter for the default Load Balancer
#   name = "kubernetes" # The default name for AKS Load Balancer
# }

resource "azurerm_management_lock" "aks_lb_lock" {
  name       = "${var.cluster_name}-lb-lock"
  #"/subscriptions/fdacd616-05ae-42d7-aa8b-ac3d67249b0a/resourceGroups/mc_k-playground-eus1/providers/Microsoft.Network/loadBalancers/kubernetes"
  scope      = "${azurerm_kubernetes_cluster.aks.node_resource_group_id}/providers/Microsoft.Network/loadBalancers/kubernetes"
  #scope      = data.azurerm_resources.aks_default_lb.resources.0.id
  lock_level = "CanNotDelete"
  notes      = "This lock prevents deletion of the AKS default load balancer"
}


resource "azurerm_kubernetes_cluster_node_pool" "node_pools" {
  for_each = { for idx, group in var.node_groups : group.name => group }

  name                  = each.value.name
  tags                  = var.tags
  enable_auto_scaling   = true
  vm_size               = each.value.vm_size
  os_disk_size_gb       = each.value.disk_size
  os_disk_type          = each.value.disk_type
  os_sku                = each.value.os_sku
  os_type               = each.value.os_type
  max_count             = each.value.max_nodes
  min_count             = each.value.min_nodes
  node_labels           = each.value.node_labels
  orchestrator_version  = each.value.orchestrator_version
  vnet_subnet_id        = var.vnet_subnet_id
  enable_node_public_ip = var.enable_node_public_ip
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
}

data "azurerm_resources" "aks_nsg" {
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
  type                = "Microsoft.Network/networkSecurityGroups"
}

resource "azurerm_management_lock" "aks_nsg_lock" {
  count      = var.lock_resources ? 1 : 0
  name       = "${var.cluster_name}-nsg-lock"
  #"/subscriptions/fdacd616-05ae-42d7-aa8b-ac3d67249b0a/resourceGroups/mc_k-playground-eus1/providers/Microsoft.Network/networkSecurityGroups/aks-agentpool-22949909-nsg"
  scope      = data.azurerm_resources.aks_nsg.resources.0.id
  lock_level = "CanNotDelete" # Other option is "ReadOnly"
  notes      = "This lock prevents accidental deletion of AKS ngs"
}

resource "azurerm_management_lock" "node_pool_lock" {
  for_each = var.lock_resources ? azurerm_kubernetes_cluster_node_pool.node_pools : {}

  name       = "${each.value.name}-lock"
  scope      = each.value.id
  lock_level = "CanNotDelete" # Other option is "ReadOnly"
  notes      = "This lock prevents deletion of the node pool: ${each.value.name}"
}

// Grant read access to the AKS subnet
resource "azurerm_role_assignment" "subnet_network_contributor" {
  #role_definition_name = "Owner" # Role can be: Reader, Network Contributor
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  scope                = var.vnet_subnet_id
}

resource "azurerm_role_assignment" "rg_network_contributor" {
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  scope                = var.resource_group_id
}

# data "azurerm_virtual_machine_scale_set" "windows_app_vmss" {
#   depends_on          = [azurerm_kubernetes_cluster_node_pool.windows_node_pool]
#   name                = "aks${var.app_node_pool_name}"
#   resource_group_name = var.node_resource_group
# }

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
