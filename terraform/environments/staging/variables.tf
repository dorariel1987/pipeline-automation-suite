variable "environment" {
  type    = string
  default = "staging"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "admin_object_ids" {
  type    = list(string)
  default = []
}
