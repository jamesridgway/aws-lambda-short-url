data "archive_file" "list_short_urls" {
  type        = "zip"
  source_dir  = "lambda_functions/list_shorturls"
  output_path = "lambda_functions/list_shorturls.zip"
}

resource "aws_lambda_permission" "short_url_lambda_permssion_short_url_list" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.short_url_list.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.short_urls_api_gateway.id}/*/${aws_api_gateway_method.short_url_api_get.http_method}${aws_api_gateway_resource.short_url_api_resource_admin.path}"
}

resource "aws_lambda_function" "short_url_list" {
  filename         = "lambda_functions/list_shorturls.zip"
  function_name    = "short_url_list"
  role             = aws_iam_role.short_url_lambda_iam.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.list_short_urls.output_base64sha256
  runtime          = "python3.6"
  timeout          = 10
  environment {
    variables = {
      BUCKET_NAME = "${var.short_url_domain}"
    }
  }
  tags = {
    Project = "short_urls"
  }
}
