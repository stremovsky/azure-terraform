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

variable "aks_cluster_resource_group_name" {
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