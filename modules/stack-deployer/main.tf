data "azurerm_client_config" "current" {}

locals {
  subscription_id_effective = coalesce(var.subscription_id, data.azurerm_client_config.current.subscription_id)
}

resource "azapi_resource" "deployment_stack" {
  type      = "Microsoft.Resources/deploymentStacks@2024-03-01"
  name      = var.stack_name
  parent_id = "/subscriptions/${local.subscription_id_effective}"
  location  = var.location
  tags      = var.tags

  schema_validation_enabled = var.schema_validation_enabled

  body = {
    properties = merge(
      {
        description      = "Net Guard Deployment Stack (Wrapper)"
        actionOnUnmanage = var.action_on_unmanage
        denySettings = {
          mode               = "denyWriteAndDelete"
          excludedPrincipals = var.excluded_principals
          excludedActions    = var.excluded_actions
        }
      },
      local.template_content_effective == null ? {} : { template = jsondecode(local.template_content_effective) },
      local.parameters_effective == null ? {} : { parameters = jsondecode(local.parameters_effective) }
    )
  }
}
