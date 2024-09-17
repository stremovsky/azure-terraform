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

variable "vnet_subnet_id" {
  description = "The ID of the subnet to which the network security group belongs"
  type        = string
}

# Tags
variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}

variable "bastion_name" {
  description = "Name of the Bastion host"
  type        = string
}