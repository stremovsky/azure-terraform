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

# Workload Identity Configuration
variable "workload_identity_name" {
  description = "Name of the user-assigned managed identity used by the workload."
  type        = string
  default     = "workload-identity"
}

# OIDC Configuration
variable "oidc_issuer_url" {
  description = "OIDC issuer URL used for the federated identity."
  type        = string
}

# Key Vault Configuration
variable "keyvault_id" {
  description = "ID of the Azure Key Vault to which access will be granted."
  type        = string
}

variable "serviceaccount_namespace" {
  description = "Namespace of the service account to grant access to the Key Vault."
  type        = string
  default     = "default"
}

# Tags
variable "tags" {
  description = "Tags to apply to the resources"
  type        = map(string)
  default     = {}
}

variable "lock_resources" {
  type    = bool
  default = false
}