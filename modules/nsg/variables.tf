variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US 2"
}

variable "aks_subnet_id" {
  type = string
}

variable "resourse_name" {
  type = string
}