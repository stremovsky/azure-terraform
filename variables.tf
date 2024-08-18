# variables.tf

variable "aks_enabled" {
  description = "Flag to enable or disable the AKS cluster creation"
  type        = bool
  default     = true
}

variable "enable_node_public_ip" {
  description = "Flag to enable or disable public IP assigned to kunernetes nodes"
  type        = bool
  default     = true
}

variable "enable_bastion" {
  description = "Enable/disable Bastion host"
  type        = bool
  default     = false
}

variable "enable_nsg" {
  description = "Enable/disable nsg ssh access"
  type        = bool
  default     = false
}

variable "create_aks_resource_group" {
  type        = bool
  default     = true
}

variable "create_node_resource_group" {
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "myResourceGroup"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "westus2"
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "myAKSCluster"
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "myakscluster"
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
  default     = 1
}

variable "vm_size" {
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