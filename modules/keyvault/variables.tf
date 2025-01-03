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

variable "key_vault_name" {
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

variable "public_network_access_enabled" {
  description = "Whether to allow public network access to the Key Vault."
  type        = bool
  default     = false
}

variable "purge_protection_enabled" {
  description = "Whether to enable purge protection for the Key Vault."
  type        = bool
  default     = false
}

variable "network_acls" {
  type = object({
    default_action             = string
    bypass                     = string
    virtual_network_subnet_ids = list(string)
  })
  description = "Key Vault network ACLs settings"
  default = {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = []
  }
}

variable "environment" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vnet_id" {
  type = string
}

# Tags
variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}