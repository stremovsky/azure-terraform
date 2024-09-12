# Resource Group Configuration
variable "resource_group_name" {
  description = "Name of the resource group where the resources will be deployed."
  type        = string
}

variable "registry_name" {}

variable "aks_kubelet_identity_id" {}