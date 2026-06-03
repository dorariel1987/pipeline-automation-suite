terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.100" }
  }
}

resource "azurerm_container_registry" "this" {
  name                          = replace("acr${var.name_prefix}${var.environment}", "-", "")
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  admin_enabled                 = false
  public_network_access_enabled = var.environment == "prod" ? false : true

  retention_policy {
    enabled = true
    days    = var.retention_days
  }

  trust_policy {
    enabled = var.environment == "prod"
  }

  tags = var.tags
}
