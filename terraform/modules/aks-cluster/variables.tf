variable "name_prefix" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id" { type = string }
variable "kubernetes_version" {
  type    = string
  default = "1.29"
}

variable "system_node_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "system_node_count" {
  type    = number
  default = 2
}

variable "workload_node_vm_size" {
  type    = string
  default = "Standard_D4s_v5"
}

variable "workload_min_count" {
  type    = number
  default = 2
}

variable "workload_max_count" {
  type    = number
  default = 10
}

variable "log_analytics_workspace_id" {
  type     = string
  default  = null
  nullable = true
}

variable "acr_id" {
  description = "Optional ACR resource id — kubelet identity will be granted AcrPull."
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
