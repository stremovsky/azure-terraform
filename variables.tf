variable "aks_enabled" {
  description = "Flag to enable or disable the AKS cluster creation"
  type        = bool
  default     = true
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
  type    = bool
  default = false
}

variable "create_subnet" {
  type    = bool
  default = false
}

variable "create_aks_resource_group" {
  type    = bool
  default = false
}

variable "create_node_resource_group" {
  type    = bool
  default = false
}

variable "aks_cluster_resource_group_name" {
  description = "Name of the resource group"
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
  type    = string
  default = "global-registry"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "westus"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "kubernetes-eus1-playground"
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

variable "default_vm_size" {
  description = "VM size for the nodes in the default node pool"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
  default = {
    environment = "Development"
  }
}

variable "whitelabel" {}
variable "acme_email" {}
variable "environment" {}
variable "region_name" {}
variable "aks_nodes_subnet_cidr" {}
variable "aks_pods_subnet_cidr" {}
variable "aks_services_subnet_cidr" {}
variable "aks_dns_server_ip" {}


variable "whitelabel_short" {}