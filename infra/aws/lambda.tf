data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../app"
  output_path = "${path.module}/app.zip"
}

resource "aws_lambda_function" "merapar_app" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "merapar-fullstack-challenge"
  role             = aws_iam_role.lambda_role.arn 
  handler          = "main.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

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