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

variable "aks_kubelet_identity_id" {
  type = string
}

variable "keyvault_name" {
  type = string
}