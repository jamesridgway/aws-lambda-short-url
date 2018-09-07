data "archive_file" "apply_security_headers" {
    type        = "zip"
    source_dir  = "lambda_functions/apply_security_headers"
    output_path = "lambda_functions/apply_security_headers.zip"
}

data "archive_file" "create_shorturl" {
    type        = "zip"
    source_dir  = "lambda_functions/create_shorturl"
    output_path = "lambda_functions/create_shorturl.zip"
}

data "archive_file" "delete_shorturl" {
    type        = "zip"
    source_dir  = "lambda_functions/delete_shorturl"
    output_path = "lambda_functions/delete_shorturl.zip"
}

resource "aws_s3_bucket" "short_urls_bucket" {
  bucket = "${var.short_url_domain}"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
  tags = {
    Project = "short_urls"
  }
}

resource "aws_iam_role" "short_url_lambda_iam" {
  name = "short_url_lambda_iam"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "short_url_lambda_policy" {
  name = "short_url_lambda_policy"
  role = "${aws_iam_role.short_url_lambda_iam.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stm1",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Sid": "Stm2",
      "Effect": "Allow",
      "Action": [
        "lambda:GetFunction"
      ],
      "Resource": "${aws_lambda_function.apply_security_headers.arn}:*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "short_url_s3_policy" {
  name        = "short_url_s3_policy"
  description = "Short URL S3 policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObjectAcl",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
        "arn:aws:s3:::${var.short_url_domain}/",
        "arn:aws:s3:::jmsr.io/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "short_url_lambda_policy_s3_policy_attachment" {
    role       = "${aws_iam_role.short_url_lambda_iam.name}"
    policy_arn = "${aws_iam_policy.short_url_s3_policy.arn}"
}

resource "aws_lambda_function" "apply_security_headers" {
  provider         = "aws.cloudfront_acm"
  filename         = "lambda_functions/apply_security_headers.zip"
  function_name    = "apply_security_headers"
  role             = "${aws_iam_role.short_url_lambda_iam.arn}"
  handler          = "lambda_function.handler"
  source_code_hash = "${data.archive_file.create_shorturl.output_base64sha256}"
  runtime          = "nodejs8.10"
  publish          = true
  tags = {
    Project = "short_urls"
  }
}

resource "aws_lambda_function" "short_url_create" {
  filename         = "lambda_functions/create_shorturl.zip"
  function_name    = "short_url_create"
  role             = "${aws_iam_role.short_url_lambda_iam.arn}"
  handler          = "lambda_function.lambda_handler"
  source_code_hash = "${data.archive_file.create_shorturl.output_base64sha256}"
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

resource "aws_lambda_function" "short_url_delete" {
  filename         = "lambda_functions/delete_shorturl.zip"
  function_name    = "short_url_delete"
  role             = "${aws_iam_role.short_url_lambda_iam.arn}"
  handler          = "lambda_function.lambda_handler"
  source_code_hash = "${data.archive_file.delete_shorturl.output_base64sha256}"
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

resource "aws_api_gateway_rest_api" "short_urls_api_gateway" {
  name        = "Short URLs API"
  description = "API for managing short URLs."
}
resource "aws_api_gateway_usage_plan" "short_urls_admin_api_key_usage_plan" {
  name         = "Short URLs admin API key usage plan"
  description  = "Usage plan for the admin API key for Short URLS."
  api_stages {
    api_id = "${aws_api_gateway_rest_api.short_urls_api_gateway.id}"
    stage  = "${aws_api_gateway_deployment.short_url_api_deployment.stage_name}"
  }
}
resource "aws_api_gateway_usage_plan_key" "short_urls_admin_api_key_usage_plan_key" {
  key_id        = "${aws_api_gateway_api_key.short_urls_admin_api_key.id}"
  key_type      = "API_KEY"
  usage_plan_id = "${aws_api_gateway_usage_plan.short_urls_admin_api_key_usage_plan.id}"
}

resource "aws_api_gateway_api_key" "short_urls_admin_api_key" {
  name = "Short URLs Admin API Key"
}

resource "aws_api_gateway_resource" "short_url_api_resource_admin" {
  rest_api_id = "${aws_api_gateway_rest_api.short_urls_api_gateway.id}"
  parent_id   = "${aws_api_gateway_rest_api.short_urls_api_gateway.root_resource_id}"
  path_part   = "admin"
}

resource "aws_api_gateway_resource" "short_url_api_resource_admin_delete" {
  rest_api_id = "${aws_api_gateway_rest_api.short_urls_api_gateway.id}"
  parent_id   = "${aws_api_gateway_resource.short_url_api_resource_admin.id}"
  path_part   = "{token+}"
}

resource "aws_api_gateway_method" "short_url_api_delete" {
  rest_api_id   = "${aws_api_gateway_rest_api.short_urls_api_gateway.id}"
  resource_id   = "${aws_api_gateway_resource.short_url_api_resource_admin_delete.id}"
  http_method   = "DELETE"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method_response" "short_url_api_delete_response" {
  rest_api_id = "${aws_api_gateway_rest_api.short_urls_api_gateway.id}"
  resource_id = "${aws_api_gateway_resource.short_url_api_resource_admin_delete.id}"
  http_method = "${aws_api_gateway_method.short_url_api_delete.http_method}"
  status_code = "200"
  response_models = {
     "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "short_url_api_delete_lambda" {
  rest_api_id             = "${aws_api_gateway_rest_api.short_urls_api_gateway.id}"
  resource_id             = "${aws_api_gateway_resource.short_url_api_resource_admin_delete.id}"
  http_method             = "${aws_api_gateway_method.short_url_api_delete.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.short_url_delete.arn}/invocations"
}

resource "aws_api_gateway_integration_response" "short_url_api_delete_lambda_response" {
  depends_on = ["aws_api_gateway_integration.short_url_api_delete_lambda"]
  rest_api_id = "${aws_api_gateway_rest_api.short_urls_api_gateway.id}"
  resource_id = "${aws_api_gateway_resource.short_url_api_resource_admin_delete.id}"
  http_method = "${aws_api_gateway_method.short_url_api_delete.http_method}"
  status_code = "${aws_api_gateway_method_response.short_url_api_delete_response.status_code}"

  response_templates = {
    "application/json" = ""
  } 
}


resource "aws_lambda_permission" "short_url_lambda_permssion_short_url_delete" {
  depends_on = ["aws_api_gateway_integration.short_url_api_delete_lambda", "aws_lambda_function.short_url_delete"]
  statement_id  = "AllowExecutionFromAPIGateway2"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.short_url_delete.arn}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.short_urls_api_gateway.id}/*/${aws_api_gateway_method.short_url_api_delete.http_method}${aws_api_gateway_resource.short_url_api_resource_admin.path}/*"
}

resource "aws_api_gateway_method" "short_url_api_post" {
  rest_api_id   = "${aws_api_gateway_rest_api.short_urls_api_gateway.id}"
  resource_id   = "${aws_api_gateway_resource.short_url_api_resource_admin.id}"
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "short_url_api_post_lambda" {
  rest_api_id             = "${aws_api_gateway_rest_api.short_urls_api_gateway.id}"
  resource_id             = "${aws_api_gateway_resource.short_url_api_resource_admin.id}"
  http_method             = "${aws_api_gateway_method.short_url_api_post.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.short_url_create.arn}/invocations"
}

resource "aws_lambda_permission" "short_url_lambda_permssion_short_url_create" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.short_url_create.arn}"
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.short_urls_api_gateway.id}/*/${aws_api_gateway_method.short_url_api_post.http_method}${aws_api_gateway_resource.short_url_api_resource_admin.path}"
}

resource "aws_lambda_permission" "short_url_lambda_permssion_apply_security_headers_edgelambda" {
  provider      = "aws.cloudfront_acm"
  statement_id  = "AllowExecutionFromCloudFront"
  action        = "lambda:GetFunction"
  function_name = "${aws_lambda_function.apply_security_headers.arn}"
  principal     = "edgelambda.amazonaws.com"
}

resource "aws_lambda_permission" "short_url_lambda_permssion_apply_security_headers_lambda" {
  provider      = "aws.cloudfront_acm"
  statement_id  = "AllowExecutionFromCloudFront2"
  action        = "lambda:GetFunction"
  function_name = "${aws_lambda_function.apply_security_headers.arn}"
  principal     = "lambda.amazonaws.com"
}

resource "aws_api_gateway_deployment" "short_url_api_deployment" {
  depends_on = ["aws_api_gateway_integration.short_url_api_post_lambda", "aws_api_gateway_integration.short_url_api_delete_lambda"]

  rest_api_id = "${aws_api_gateway_rest_api.short_urls_api_gateway.id}"
  stage_name  = "Production"
}

resource "aws_acm_certificate" "short_url_domain_certificate" {
  provider          = "aws.cloudfront_acm"
  domain_name       = "${var.short_url_domain}"
  validation_method = "DNS"
  tags {
    Project = "short_urls"
  }
}

data "aws_route53_zone" "short_url_domain" {
  name = "${var.short_url_domain}"
}

resource "aws_route53_record" "short_url_domain_alias" {
  zone_id = "${data.aws_route53_zone.short_url_domain.zone_id}"
  name    = "${var.short_url_domain}"
  type    = "A"
  alias {
    name                   = "${aws_cloudfront_distribution.short_urls_cloudfront.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.short_urls_cloudfront.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "short_url_domain_cert_validation" {
  name    = "${aws_acm_certificate.short_url_domain_certificate.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.short_url_domain_certificate.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.short_url_domain.id}"
  records = ["${aws_acm_certificate.short_url_domain_certificate.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}


resource "aws_acm_certificate_validation" "short_url_domain_cert" {
  provider    = "aws.cloudfront_acm"
  certificate_arn         = "${aws_acm_certificate.short_url_domain_certificate.arn}"
  validation_record_fqdns = ["${aws_route53_record.short_url_domain_cert_validation.fqdn}"]
}

resource "aws_cloudfront_distribution" "short_urls_cloudfront" {
  depends_on = ["aws_lambda_function.apply_security_headers"]
  provider = "aws.cloudfront_acm"
  enabled  = true
  aliases  = ["${var.short_url_domain}"]
  origin {
    origin_id   = "origin-bucket-${aws_s3_bucket.short_urls_bucket.id}"
    domain_name = "${aws_s3_bucket.short_urls_bucket.website_endpoint}"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1.1"]
    }
  }
  origin {
    origin_id   = "origin-api-${aws_api_gateway_deployment.short_url_api_deployment.id}"
    domain_name = "${replace(replace(aws_api_gateway_deployment.short_url_api_deployment.invoke_url,"/Production", ""), "https://", "")}"
    origin_path = "/Production"

    custom_origin_config {
      origin_protocol_policy = "https-only"
      http_port              = "80"
      https_port             = "443"
      origin_ssl_protocols   = ["TLSv1.1"]
    }
  }
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "origin-bucket-${aws_s3_bucket.short_urls_bucket.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "origin-response"
      lambda_arn = "${aws_lambda_function.apply_security_headers.qualified_arn}"
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  ordered_cache_behavior {
    path_pattern     = "admin*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "origin-api-${aws_api_gateway_deployment.short_url_api_deployment.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "origin-response"
      lambda_arn = "${aws_lambda_function.apply_security_headers.qualified_arn}"
    }

    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = "${aws_acm_certificate_validation.short_url_domain_cert.certificate_arn}"
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.1_2016"
  }
  tags = {
    Project = "short_urls"
  }
}


output "Short URL Doamin" {
  value = "${var.short_url_domain}"
}
output "CloudFront Domain Name" {
  value = "${aws_cloudfront_distribution.short_urls_cloudfront.domain_name}"
}
output "Admin API Key" {
  value = "${aws_api_gateway_api_key.short_urls_admin_api_key.value}"
}