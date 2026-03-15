output "function_url" {
  description = "Public URL of the Lambda function"
  value       = aws_lambda_function_url.public_url.function_url
}

output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions OIDC (set as AWS_ROLE_ARN secret)"
  value       = aws_iam_role.github_actions.arn
}
