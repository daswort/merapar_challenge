resource "aws_ssm_parameter" "dynamic_string" {
  name        = "/merapar/dynamic_string"
  description = "Variable dinamica para el reto de Merapar"
  type        = "String"
  value       = "The word of the day is Merapar"

  tags = {
    Project = "MeraparChallenge"
  }
}