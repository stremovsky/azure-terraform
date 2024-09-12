# Resource Group Configuration
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "node_resource_group" {
  description = "Name of the resource group for Kubernetes resources"
  type        = string
}

# Location Configuration
variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US 2"
}

# Cluster Configuration
variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "aks_private" {
  description = "Indicates if the cluster should be private or public"
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

# Node Pools Configuration
variable "enable_node_public_ip" {
  description = "Enable public IPs for nodes"
  type        = bool
  default     = false
}

variable "system_node_count" {
  description = "Number of nodes in the system node pool"
  type        = number
  default     = 1
}

variable "system_min_count" {
  description = "Minimum number of nodes in the system node pool for autoscaling"
  type        = number
  default     = 1
}

variable "system_max_count" {
  description = "Maximum number of nodes in the system node pool for autoscaling"
  type        = number
  default     = 3
}

variable "app_node_count" {
  description = "Number of nodes in the application node pool"
  type        = number
  default     = 1
}

variable "app_min_count" {
  description = "Minimum number of nodes in the application node pool for autoscaling"
  type        = number
  default     = 1
}

variable "app_max_count" {
  description = "Maximum number of nodes in the application node pool for autoscaling"
  type        = number
  default     = 10
}

variable "app_os_type" {
  description = "Operating system type for the application node pool (e.g., Linux, Windows)"
  type        = string
  default     = "Windows"
}

# VM and Disk Configuration
variable "system_vm_size" {
  description = "VM size for the nodes in the system node pool"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "system_disk_size" {
  type    = number
  default = 40
}

variable "syste_disk_type" {
  type    = string
  default = "Managed"
}

variable "system_os_sku" {
  type    = string
  default = "Ubuntu"
}

variable "app_vm_size" {
  type    = string
  default = "Standard_D4_v5"
}

variable "app_disk_size" {
  type    = number
  default = 256
}

variable "vnet_subnet_id" {
  type = string
}

variable "network_plugin" {
  type    = string
  default = "azure"
}

variable "network_policy" {
  type    = string
  default = "azure"
}

variable "load_balancer_sku" {
  type    = string
  default = "standard"
}

variable "network_plugin_mode" {
  type    = string
  default = "overlay"
}

variable "linux_admin_user" {
  type    = string
  default = "aksadmin"
}

variable "system_node_pool_name" {}
variable "app_node_pool_name" {}
variable "windows_node_pool_labels" {
  type = map(string)
}
variable "service_cidr" {}
variable "dns_service_ip" {}
variable "pod_cidr" {}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
  default     = {}
}