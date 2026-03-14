resource "aws_lambda_function" "merapar_app" {
  filename         = "${path.module}/app.zip"
  function_name    = "merapar-fullstack-challenge"
  role             = aws_iam_role.lambda_role.arn 
  handler          = "main.handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/app.zip")

  environment {
    variables = {
      PARAMETER_NAME = aws_ssm_parameter.dynamic_string.name
    }
  }

  tags = {
    Project = "MeraparChallenge"
    Environment = "Dev"
  }
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/merapar-fullstack-challenge"
  retention_in_days = 7
}