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

variable "aks_node_resource_group_name" {
  type = string
}

variable "aks_subnet_id" {
  type = string
}

variable "resourse_name" {
  type = string
}