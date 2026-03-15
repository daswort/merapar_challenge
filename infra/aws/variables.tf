variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Project identifier used to compose resource names"
  type        = string
  default     = "merapar-challenge"
}

variable "environment" {
  description = "Deployment environment (Dev, Staging, Prod)"
  type        = string
  default     = "Dev"
}

variable "ssm_parameter_value" {
  description = "Initial value for the dynamic string served by the app"
  type        = string
  default     = "The word of the day is Merapar"
}

variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = string
  default     = "1.0"
}

variable "budget_notification_email" {
  description = "Email to receive budget alerts"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository (owner/repo) allowed to assume the CI/CD role"
  type        = string
}
