variable "name_prefix" {
  description = "Short slug used as prefix for every resource name."
  type        = string
}

variable "environment" {
  description = "Logical environment (dev/staging/prod)."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "vnet_cidr" {
  description = "CIDR for the VNet."
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "CIDR for the AKS node subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "platform_subnet_cidr" {
  description = "CIDR for the platform subnet (Key Vault PEs, etc.)."
  type        = string
  default     = "10.0.2.0/24"
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
