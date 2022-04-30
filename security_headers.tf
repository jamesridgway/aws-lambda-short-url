data "archive_file" "apply_security_headers" {
  type        = "zip"
  source_dir  = "lambda_functions/apply_security_headers"
  output_path = "lambda_functions/apply_security_headers.zip"
}

resource "aws_lambda_permission" "short_url_lambda_permssion_apply_security_headers_edgelambda" {
  provider      = aws.cloudfront_acm
  statement_id  = "AllowExecutionFromCloudFront"
  action        = "lambda:GetFunction"
  function_name = aws_lambda_function.apply_security_headers.arn
  principal     = "edgelambda.amazonaws.com"
}

resource "aws_lambda_permission" "short_url_lambda_permssion_apply_security_headers_lambda" {
  provider      = aws.cloudfront_acm
  statement_id  = "AllowExecutionFromCloudFront2"
  action        = "lambda:GetFunction"
  function_name = aws_lambda_function.apply_security_headers.arn
  principal     = "lambda.amazonaws.com"
}

resource "aws_lambda_function" "apply_security_headers" {
  provider         = aws.cloudfront_acm
  filename         = "lambda_functions/apply_security_headers.zip"
  function_name    = "apply_security_headers"
  role             = aws_iam_role.short_url_lambda_iam.arn
  handler          = "lambda_function.handler"
  source_code_hash = data.archive_file.apply_security_headers.output_base64sha256
  runtime          = "nodejs14.x"
  publish          = true
  tags = {
    Project = "short_urls"
  }
}
