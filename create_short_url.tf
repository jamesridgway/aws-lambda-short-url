data "archive_file" "create_shorturl" {
  type        = "zip"
  source_dir  = "lambda_functions/create_shorturl"
  output_path = "lambda_functions/create_shorturl.zip"
}

resource "aws_lambda_permission" "short_url_lambda_permssion_short_url_create" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.short_url_create.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.short_urls_api_gateway.id}/*/${aws_api_gateway_method.short_url_api_post.http_method}${aws_api_gateway_resource.short_url_api_resource_admin.path}"
}

resource "aws_lambda_function" "short_url_create" {
  filename         = "lambda_functions/create_shorturl.zip"
  function_name    = "short_url_create"
  role             = aws_iam_role.short_url_lambda_iam.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.create_shorturl.output_base64sha256
  runtime          = "python3.6"
  environment {
    variables = {
      BUCKET_NAME = "${var.short_url_domain}"
    }
  }
  tags = {
    Project = "short_urls"
  }
}
