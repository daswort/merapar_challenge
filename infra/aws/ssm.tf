resource "aws_ssm_parameter" "dynamic_string" {
  name        = "/${var.project_name}/dynamic_string"
  description = "Dynamic string for ${var.project_name}"
  type        = "String"
  value       = var.ssm_parameter_value
}