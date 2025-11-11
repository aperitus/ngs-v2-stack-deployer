terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.114.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = ">= 2.0.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

module "stack_deployer" {
  source = "./modules/stack-deployer"

  stack_name                = var.stack_name
  location                  = var.location
  template_file             = var.template_file
  parameters_file           = var.parameters_file
  parameters_json           = var.parameters_json
  tags                      = var.tags
  excluded_principals       = var.excluded_principals
  excluded_actions          = var.excluded_actions
  action_on_unmanage        = var.action_on_unmanage
  subscription_id           = var.subscription_id
  schema_validation_enabled = var.schema_validation_enabled
}

output "stack_id" {
  value = module.stack_deployer.stack_id
}
