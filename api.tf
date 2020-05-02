resource "aws_api_gateway_rest_api" "short_urls_api_gateway" {
  name        = "Short URLs API"
  description = "API for managing short URLs."
}

resource "aws_api_gateway_usage_plan" "short_urls_admin_api_key_usage_plan" {
  name        = "Short URLs admin API key usage plan"
  description = "Usage plan for the admin API key for Short URLS."
  api_stages {
    api_id = aws_api_gateway_rest_api.short_urls_api_gateway.id
    stage  = aws_api_gateway_deployment.short_url_api_deployment.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "short_urls_admin_api_key_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.short_urls_admin_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.short_urls_admin_api_key_usage_plan.id
}

resource "aws_api_gateway_api_key" "short_urls_admin_api_key" {
  name = "Short URLs Admin API Key"
}

resource "aws_api_gateway_resource" "short_url_api_resource_admin" {
  rest_api_id = aws_api_gateway_rest_api.short_urls_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.short_urls_api_gateway.root_resource_id
  path_part   = "admin"
}

resource "aws_api_gateway_deployment" "short_url_api_deployment" {
  depends_on = [aws_api_gateway_integration.short_url_api_post_lambda, aws_api_gateway_integration.short_url_api_delete_lambda]

  rest_api_id = aws_api_gateway_rest_api.short_urls_api_gateway.id
  stage_name  = "Production"
}
