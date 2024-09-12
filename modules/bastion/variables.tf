variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
}

variable "vnet_subnet_id" {
  description = "The ID of the subnet to which the network security group belongs"
  type        = string
}