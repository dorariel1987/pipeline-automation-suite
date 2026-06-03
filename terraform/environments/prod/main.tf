terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.100" }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstateplatform"
    container_name       = "tfstate"
    key                  = "platform/prod.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

locals {
  name_prefix = "platform"
  tags = {
    project     = "pipeline-automation-suite"
    environment = var.environment
    managed_by  = "terraform"
    cost_center = "platform"
  }
}

module "networking" {
  source               = "../../modules/networking"
  name_prefix          = local.name_prefix
  environment          = var.environment
  location             = var.location
  vnet_cidr            = "10.20.0.0/16"
  aks_subnet_cidr      = "10.20.1.0/24"
  platform_subnet_cidr = "10.20.2.0/24"
  tags                 = local.tags
}

module "acr" {
  source              = "../../modules/acr"
  name_prefix         = local.name_prefix
  environment         = var.environment
  location            = module.networking.resource_group_location
  resource_group_name = module.networking.resource_group_name
  sku                 = "Premium"
  retention_days      = 90
  tags                = local.tags
}

module "aks" {
  source                = "../../modules/aks-cluster"
  name_prefix           = local.name_prefix
  environment           = var.environment
  location              = module.networking.resource_group_location
  resource_group_name   = module.networking.resource_group_name
  subnet_id             = module.networking.aks_subnet_id
  acr_id                = module.acr.id
  system_node_count     = 3
  system_node_vm_size   = "Standard_D4s_v5"
  workload_node_vm_size = "Standard_D8s_v5"
  workload_min_count    = 3
  workload_max_count    = 20
  tags                  = local.tags
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
