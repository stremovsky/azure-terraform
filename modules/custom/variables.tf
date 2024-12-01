variable "resource_group_name" {
  description = "Name of the resource group where the resources will be deployed."
  type        = string
}

variable "location" {
  description = "Azure region to deploy the resources."
  type        = string
}


variable "project_short_name" {
  type = string
}

variable "whitelabel" {
  type = string
}

variable "whitelabel_short" {
  type = string
}

variable "environment_name" {
  type = string
}

variable "region_name" {
  type = string
}

variable "vnet_resource_group_name" {
  type = string
}

variable "oidc_issuer_url" {
  type = string
}

variable "default_tags" {
  description = "Default tags to use for new resources"
  type        = map(string)
  default = {
    environment = "Development"
  }
}

variable "aks_subnet_id" {
  type = string
}