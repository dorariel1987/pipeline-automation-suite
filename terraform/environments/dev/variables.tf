variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "admin_object_ids" {
  type    = list(string)
  default = []
}
