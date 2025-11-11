variable "stack_name" {
  description = "Deployment Stack name"
  type        = string
}

variable "location" {
  description = "Azure region for the stack control plane"
  type        = string
  default     = "uksouth"
}

variable "template_file" {
  description = "Absolute or workspace-relative path to subscription-scope template JSON."
  type        = string
}

variable "parameters_file" {
  description = "Optional ARM parameters file path."
  type        = string
  default     = null
}

variable "parameters_json" {
  description = "Optional inline parameters object."
  type        = any
  default     = null
}

variable "tags" {
  description = "Tags for the stack resource."
  type        = map(string)
  default     = {}
}

variable "excluded_principals" {
  description = "Object IDs that bypass deny inside the stack."
  type        = list(string)
  default     = []
}

variable "excluded_actions" {
  description = "Allowed actions for excluded principals."
  type        = list(string)
  default     = [
    "Microsoft.Network/virtualNetworks/subnets/join/action",
    "Microsoft.Network/virtualNetworks/subnets/joinViaServiceEndpoint/action",
    "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
    "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
  ]
}

variable "action_on_unmanage" {
  description = "Detach/Delete behavior per scope."
  type = object({
    managementGroups = optional(string, "detach")
    resourceGroups   = optional(string, "detach")
    resources        = optional(string, "detach")
  })
  default = {
    managementGroups = "detach"
    resourceGroups   = "detach"
    resources        = "detach"
  }

  validation {
    condition = (
      contains(["detach", "delete"], lower(var.action_on_unmanage.managementGroups)) &&
      contains(["detach", "delete"], lower(var.action_on_unmanage.resourceGroups)) &&
      contains(["detach", "delete"], lower(var.action_on_unmanage.resources))
    )
    error_message = "action_on_unmanage values must be one of: detach | delete."
  }
}

variable "schema_validation_enabled" {
  description = "Enable azapi schema validation (default false to avoid provider false-positives)."
  type        = bool
  default     = false
}


variable "subscription_id" {
  description = "Override subscription ID for the Deployment Stack parent_id. If null, uses the active provider context."
  type        = string
  default     = null
}
