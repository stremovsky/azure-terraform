# Resource Group Configuration
variable "resource_group_name" {
  description = "Name of the resource group where the resources will be deployed."
  type        = string
}

# Location Configuration
variable "location" {
  description = "Azure region to deploy the resources."
  type        = string
}

# Container Registry Configuration
variable "registry_name" {
  description = "Name of the existing Azure Container Registry"
  type        = string
}

# AKS Configuration
variable "aks_kubelet_identity_id" {
  description = "ID of the AKS kubelet identity that needs read access to the container registry"
  type        = string
}

# Variable to control registry creation
variable "create_registry" {
  description = "Boolean to control whether to create the Azure Container Registry"
  type        = bool
  default     = false
}

variable "acr_sku" {
  description = "The SKU of the Azure Container Registry (e.g., Basic, Standard, Premium)"
  type        = string
  default     = "Standard"
}

variable "admin_enabled" {
  description = "Whether the admin user is enabled for the Azure Container Registry"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Tags to assign to the Azure Container Registry"
  type        = map(string)
  default     = {}
}