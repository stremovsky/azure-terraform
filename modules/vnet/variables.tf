variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
}

variable "enable_bastion" {}
variable "create_subnet" {}
variable "create_vnet" {}
variable "subnet_name" {}
variable "vnet_name" {}
variable "vnet_cidr" {}
variable "aks_subnet_cidr" {}
variable "bastion_subnet_cidr" {}
