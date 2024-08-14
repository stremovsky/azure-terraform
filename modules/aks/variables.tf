variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US"
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "vm_size" {
  description = "VM size for the nodes in the default node pool"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "vnet_subnet_id" {}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
  default     = {}
}