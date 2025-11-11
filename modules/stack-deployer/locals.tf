locals {
  tpl_from_file    = var.template_file != null && var.template_file != ""
  tpl_from_content = var.template_content != null && var.template_content != ""

  template_content_effective = local.tpl_from_file ? file(var.template_file) : (
    local.tpl_from_content ? var.template_content : null
  )

  parameters_effective = (
    var.parameters_json != null ? jsonencode(var.parameters_json) :
    (var.parameters_file != null && var.parameters_file != "" ? file(var.parameters_file) : null)
  )
}
