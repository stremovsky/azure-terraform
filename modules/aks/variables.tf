# Resource Group Configuration
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group"
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
  default     = true
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

# Default nodepool configuration
variable "system_node_pool_name" {
  description = "Name of the system node pool"
  type        = string
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

# VM and Disk Configuration
variable "system_vm_size" {
  description = "VM size for the nodes in the system node pool"
  type        = string
  default     = "Standard_D2ps_v5" # 2 vCPU 8GB RAM
}

variable "system_disk_size" {
  description = "Disk size (in GB) for the system node pool"
  type        = number
  default     = 100
}

variable "system_disk_type" {
  description = "Disk type for the system node pool (e.g., Managed, Unmanaged)"
  type        = string
  default     = "Managed"
}

variable "system_os_sku" {
  description = "Operating system SKU for the system node pool (e.g., Ubuntu, Windows)"
  type        = string
  default     = "Ubuntu"
}


variable "node_groups" {
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

# Networking Configuration
variable "vnet_subnet_id" {
  description = "ID of the subnet to use for the AKS cluster"
  type        = string
}

variable "network_plugin" {
  description = "Network plugin to use (e.g., azure, kubenet)"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy to use (e.g., azure, calico)"
  type        = string
  default     = "azure"
}

variable "load_balancer_sku" {
  description = "SKU of the load balancer (e.g., basic, standard)"
  type        = string
  default     = "standard"
}

variable "network_plugin_mode" {
  description = "Mode of the network plugin (e.g., overlay)"
  type        = string
  default     = "overlay"
}

# Administrative Configuration
variable "linux_admin_user" {
  type    = string
  default = "aksadmin"
}

# Networking CIDRs
variable "service_cidr" {
  description = "CIDR block for services in the cluster"
  type        = string
}

variable "dns_service_ip" {
  description = "IP address for the DNS service in the cluster"
  type        = string
}

variable "pod_cidr" {
  description = "CIDR block for pods in the cluster"
  type        = string
}

variable "private_dns_zone_id" {
  description = "ID of the private DNS zone for the cluster"
  type        = string
  default     = null
}

# Tags
variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}

variable "identity" {
  type = map(string)
}

variable "kubernetes_version" {
  type    = string
  default = "1.29"
}

variable "lock_resources" {
  type    = bool
  default = false
}