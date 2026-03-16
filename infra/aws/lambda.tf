locals {
  function_name = "${var.project_name}-app"
}

resource "aws_lambda_function" "merapar_app" {
  filename         = "${path.module}/app.zip"
  function_name    = local.function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "main.handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/app.zip")

  environment {
    variables = {
      PARAMETER_NAME = aws_ssm_parameter.dynamic_string.name
    }
  }

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 7
}

resource "aws_lambda_function_url" "public_url" {
  function_name      = aws_lambda_function.merapar_app.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "public_access" {
  statement_id           = "AllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.merapar_app.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "public_invoke" {
  statement_id  = "AllowPublicInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.merapar_app.function_name
  principal     = "*"
}