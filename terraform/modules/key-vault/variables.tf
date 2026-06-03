variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }

variable "allowed_subnet_ids" {
  type    = list(string)
  default = []
}

variable "aks_kubelet_principal_id" {
  type     = string
  default  = null
  nullable = true
}

variable "admin_object_ids" {
  description = "AAD object ids granted Key Vault Administrator."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
