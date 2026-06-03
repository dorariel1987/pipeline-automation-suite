terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.100" }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstateplatform"
    container_name       = "tfstate"
    key                  = "platform/dev.tfstate"
  }
}

provider "azurerm" {
  features {}
}

locals {
  name_prefix = "platform"
  tags = {
    project     = "pipeline-automation-suite"
    environment = var.environment
    managed_by  = "terraform"
  }
}

module "networking" {
  source      = "../../modules/networking"
  name_prefix = local.name_prefix
  environment = var.environment
  location    = var.location
  tags        = local.tags
}

module "acr" {
  source              = "../../modules/acr"
  name_prefix         = local.name_prefix
  environment         = var.environment
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name
  sku                 = "Standard"
  tags                = local.tags
}

module "aks" {
  source              = "../../modules/aks-cluster"
  name_prefix         = local.name_prefix
  environment         = var.environment
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name
  subnet_id           = module.networking.aks_subnet_id
  acr_id              = module.acr.id
  workload_min_count  = 1
  workload_max_count  = 3
  tags                = local.tags
}

module "key_vault" {
  source                   = "../../modules/key-vault"
  name_prefix              = local.name_prefix
  environment              = var.environment
  location                 = module.networking.resource_group_location
  resource_group_name      = module.networking.resource_group_name
  allowed_subnet_ids       = [module.networking.platform_subnet_id]
  aks_kubelet_principal_id = module.aks.kubelet_identity_object_id
  admin_object_ids         = var.admin_object_ids
  tags                     = local.tags
}
