resource "aws_api_gateway_resource" "short_url_api_resource_admin_delete" {
  rest_api_id = aws_api_gateway_rest_api.short_urls_api_gateway.id
  parent_id   = aws_api_gateway_resource.short_url_api_resource_admin.id
  path_part   = "{token+}"
}

resource "aws_api_gateway_method" "short_url_api_delete" {
  rest_api_id      = aws_api_gateway_rest_api.short_urls_api_gateway.id
  resource_id      = aws_api_gateway_resource.short_url_api_resource_admin_delete.id
  http_method      = "DELETE"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method_response" "short_url_api_delete_response" {
  rest_api_id = aws_api_gateway_rest_api.short_urls_api_gateway.id
  resource_id = aws_api_gateway_resource.short_url_api_resource_admin_delete.id
  http_method = aws_api_gateway_method.short_url_api_delete.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "short_url_api_delete_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.short_urls_api_gateway.id
  resource_id             = aws_api_gateway_resource.short_url_api_resource_admin_delete.id
  http_method             = aws_api_gateway_method.short_url_api_delete.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.short_url_delete.arn}/invocations"
}

resource "aws_api_gateway_integration_response" "short_url_api_delete_lambda_response" {
  depends_on  = [aws_api_gateway_integration.short_url_api_delete_lambda]
  rest_api_id = aws_api_gateway_rest_api.short_urls_api_gateway.id
  resource_id = aws_api_gateway_resource.short_url_api_resource_admin_delete.id
  http_method = aws_api_gateway_method.short_url_api_delete.http_method
  status_code = aws_api_gateway_method_response.short_url_api_delete_response.status_code

  response_templates = {
    "application/json" = ""
  }
}
