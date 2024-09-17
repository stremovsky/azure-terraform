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

# Virtual Network Configuration
variable "create_vnet" {
  description = "Flag to determine if a new virtual network should be created"
  type        = bool
  default     = false
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for the virtual network"
  type        = string
}

# Subnet Configuration
variable "create_subnet" {
  description = "Flag to determine if a new subnet for AKS should be created"
  type        = bool
  default     = false
}

variable "subnet_name" {
  description = "Name of the subnet for AKS"
  type        = string
}

variable "aks_subnet_cidr" {
  description = "CIDR block for the AKS subnet"
  type        = string
}

# Bastion Subnet Configuration
variable "create_bastion_subnet" {
  description = "Flag to determine if a new subnet for Azure Bastion should be created"
  type        = bool
  default     = false
}

variable "bastion_subnet_cidr" {
  description = "CIDR block for the Azure Bastion subnet"
  type        = string
}

# Tags
variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}