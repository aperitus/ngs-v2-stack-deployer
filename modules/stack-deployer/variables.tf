variable "stack_name" {
  description = "Name for the Deployment Stack (subscription scope)."
  type        = string
}

variable "location" {
  description = "Azure region for the Deployment Stack control plane (e.g., uksouth)."
  type        = string
  default     = "uksouth"
}

variable "template_file" {
  description = "Path to subscription-scope ARM template (exporter output). Mutually exclusive with template_content."
  type        = string
  default     = null
}

variable "template_content" {
  description = "Raw JSON string of the subscription-scope ARM template. Mutually exclusive with template_file."
  type        = string
  default     = null
}

variable "parameters_file" {
  description = "Path to an ARM parameters file for the template (optional)."
  type        = string
  default     = null
}

variable "parameters_json" {
  description = "Parameters JSON object to pass inline (alternative to parameters_file)."
  type        = any
  default     = null
}

variable "tags" {
  description = "Tags to apply to the Deployment Stack resource."
  type        = map(string)
  default     = {}
}

variable "excluded_principals" {
  description = "AAD object IDs that can bypass the stack's deny (break-glass)."
  type        = list(string)
  default     = []
}

variable "excluded_actions" {
  description = "Resource provider actions to exclude from the stack deny for the excluded principals."
  type        = list(string)
  default     = [
    "Microsoft.Network/virtualNetworks/subnets/join/action",
    "Microsoft.Network/virtualNetworks/subnets/joinViaServiceEndpoint/action",
    "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
    "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
  ]
}

variable "action_on_unmanage" {
  description = "Action to take on unmanage per scope (managementGroups/resourceGroups/resources)."
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
}

variable "schema_validation_enabled" {
  description = "Enable azapi schema validation (set false to bypass provider schema mismatch)."
  type        = bool
  default     = false
}


variable "subscription_id" {
  description = "Override subscription ID for the Deployment Stack parent_id. If null, uses the active provider context."
  type        = string
  default     = null
}
