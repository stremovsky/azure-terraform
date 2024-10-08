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
  description = "Enable/disable subnet creation"
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
  default = "registry1"
}

variable "registry_resource_group_name" {
  description = "Name of the resource group for registry"
  type        = string
  default     = "global-registry"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "westus"
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "akstesting"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "min_count" {
  description = "Minimal number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Maximal number of nodes in the default node pool"
  type        = number
  default     = 10
}

variable "system_vm_size" {
  description = "VM size for the nodes in the default node pool"
  type        = string
  #default     = "Standard_DS2_v2" # 2 vCPU 8GB 	x64
  default = "Standard_D2ps_v5" # 2 vCPU 8GB 	ARM64
}

variable "default_tags" {
  description = "Default tags to use for new resources"
  type        = map(string)
  default = {
    environment = "Development"
  }
}

variable "app_node_pool_enable" {
  type    = bool
  default = false
}

variable "gpu_node_pool_enable" {
  type    = bool
  default = false
}

variable "app_node_pool_labels" {
  type    = map(string)
  default = {}
}

variable "gpu_node_pool_labels" {
  type    = map(string)
  default = {}
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
variable "acme_email" {}
variable "aks_nodes_subnet_cidr" {}
variable "aks_pods_subnet_cidr" {}
variable "aks_services_subnet_cidr" {}
variable "aks_dns_server_ip" {}
variable "create_registry" {
  type    = bool
  default = false
}
