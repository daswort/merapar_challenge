output "function_url" {
  description = "Public URL of the Lambda function"
  value       = aws_lambda_function_url.public_url.function_url
}
