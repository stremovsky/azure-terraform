variable "aks_enabled" {
  description = "Flag to enable or disable the AKS cluster creation"
  type        = bool
  default     = true
}

variable "aks_private" {
  description = "Flag to enable or disable private AKS cluster"
  type        = bool
  default     = false
}

variable "enable_node_public_ip" {
  description = "Flag to enable or disable public IP assigned to kunernetes nodes"
  type        = bool
  default     = false
}

variable "enable_bastion" {
  description = "Enable/disable Bastion host"
  type        = bool
  default     = false
}

variable "bastion_subnet_cidr" {
  description = "Bastion subnet CIDR"
  type        = string
  default     = "10.224.1.0/24"
}

variable "enable_nsg" {
  description = "Enable/disable nsg ssh access"
  type        = bool
  default     = false
}

variable "create_vnet" {
  description = "Enable/disable vnet creation"
  type        = bool
  default     = false
}

variable "create_subnet" {
  description = "Enable/disable AKS subnet creation"
  type        = bool
  default     = false
}

variable "create_aks_resource_group" {
  description = "Enable/disable AKS resource group creation"
  type        = bool
  default     = false
}

variable "aks_cluster_resource_group_name" {
  description = "Name of the resource group for AKS cluster"
  type        = string
}

variable "vnet_name" {
  description = "Vnet resource name"
  type        = string
}

variable "vnet_cidr" {
  description = "Vnet CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vnet_resource_group_name" {
  description = "Name of the resource group if existing vnet is used"
  type        = string
}

variable "registry_name" {
  type    = string
  default = "jregistry1"
}

variable "registry_resource_group_name" {
  description = "Name of the resource group for registry"
  type        = string
  default     = "global-registry"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "akstesting"
}

variable "min_count" {
  description = "Minimal number of nodes in the default node pool"
  type        = number
  default     = 0
}

variable "max_count" {
  description = "Maximal number of nodes in the default node pool"
  type        = number
  default     = 10
}

variable "system_vm_size" {
  description = "VM size for the nodes in the default node pool"
  type        = string
  default     = "Standard_D2ps_v5" # 2 vCPU 8GB RAM
}

variable "default_tags" {
  description = "Default tags to use for new resources"
  type        = map(string)
  default = {
    environment = "Development"
  }
}

variable "environment_name" {
  description = "The environment name, such as dev, staging, or prod."
  type        = string
}

variable "region_name" {
  description = "The Azure region where the resources will be deployed."
  type        = string
}

variable "whitelabel" {}
variable "whitelabel_short" {}
variable "aks_nodes_subnet_cidr" {}
variable "aks_pods_subnet_cidr" {}
variable "aks_services_subnet_cidr" {}
variable "aks_dns_server_ip" {}

variable "create_registry" {
  type    = bool
  default = false
}

variable "kubernetes_version" {
  type    = string
  default = "1.29"
}

variable "aks_node_groups" {
  description = "List of node groups with their settings"
  type = list(object({
    name                 = string
    os_sku               = string
    os_type              = string
    vm_size              = string
    min_nodes            = number
    max_nodes            = number
    disk_size            = number
    disk_type            = string
    node_labels          = map(string),
    orchestrator_version = string
  }))
  //type = list
  default = []
}

variable "ep_enabled" {
  type    = bool
  default = false
}

variable "lock_resources" {
  type    = bool
  default = false
}