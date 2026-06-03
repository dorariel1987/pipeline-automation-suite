variable "environment" {
  type    = string
  default = "prod"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "admin_object_ids" {
  type    = list(string)
  default = []
}
