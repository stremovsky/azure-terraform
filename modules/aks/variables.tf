variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "node_resource_group" {
  description = "Name of the resource group fopr kubernetes resources"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US 2"
}

variable "enable_node_public_ip" {
  type    = bool
  default = false
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "aks_private" {
  description = "Make private or public cluster"
  type        = bool
  default     = false
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "ssh_key_file" {
  description = "Path to the SSH public key file"
  type        = string
  default     = ""
}

variable "system_node_count" {
  type    = number
  default = 1
}

variable "system_min_count" {
  type    = number
  default = 1
}

variable "system_max_count" {
  type    = number
  default = 3
}

variable "app_os_type" {
  type    = string
  default = "Windows"
}

variable "app_node_count" {
  type    = number
  default = 1
}

variable "app_min_count" {
  type    = number
  default = 1
}

variable "app_max_count" {
  type    = number
  default = 10
}

variable "default_vm_size" {
  description = "VM size for the nodes in the default node pool"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "default_disk_size" {
  type    = number
  default = 40
}

variable "windows_vm_size" {
  type    = string
  default = "Standard_D4_v5"
}

variable "vnet_subnet_id" {
  type = string
}

variable "default_node_pool_name" {}
variable "windows_node_pool_name" {}
variable "service_cidr" {}
variable "dns_service_ip" {}
variable "pod_cidr" {}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
  default     = {}
}