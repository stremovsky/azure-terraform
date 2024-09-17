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

variable "keyvault_name" {
  description = "The name of the Azure Key Vault."
  type        = string
}

variable "tenant_id" {
  description = "The tenant ID for the Azure account."
  type        = string
}

variable "aks_kubelet_identity_id" {
  type = string
}

variable "user_principle_id" {
  description = "The principal ID of the user to assign RBAC roles."
  type        = string
}

# Tags
variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}