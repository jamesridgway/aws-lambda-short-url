data "archive_file" "delete_shorturl" {
  type        = "zip"
  source_dir  = "lambda_functions/delete_shorturl"
  output_path = "lambda_functions/delete_shorturl.zip"
}

resource "aws_lambda_permission" "short_url_lambda_permssion_short_url_delete" {
  depends_on    = [aws_api_gateway_integration.short_url_api_delete_lambda, aws_lambda_function.short_url_delete]
  statement_id  = "AllowExecutionFromAPIGateway2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.short_url_delete.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.short_urls_api_gateway.id}/*/${aws_api_gateway_method.short_url_api_delete.http_method}${aws_api_gateway_resource.short_url_api_resource_admin.path}/*"
}

resource "aws_lambda_function" "short_url_delete" {
  filename         = "lambda_functions/delete_shorturl.zip"
  function_name    = "short_url_delete"
  role             = aws_iam_role.short_url_lambda_iam.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.delete_shorturl.output_base64sha256
  runtime          = "python3.9"
  environment {
    variables = {
      BUCKET_NAME = "${var.short_url_domain}"
    }
  }
  tags = {
    Project = "short_urls"
  }
}
