resource "aws_api_gateway_method" "short_url_api_post" {
  rest_api_id      = aws_api_gateway_rest_api.short_urls_api_gateway.id
  resource_id      = aws_api_gateway_resource.short_url_api_resource_admin.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "short_url_api_post_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.short_urls_api_gateway.id
  resource_id             = aws_api_gateway_resource.short_url_api_resource_admin.id
  http_method             = aws_api_gateway_method.short_url_api_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.short_url_create.arn}/invocations"
}
