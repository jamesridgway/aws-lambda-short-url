
resource "aws_acm_certificate" "short_url_domain_certificate" {
  provider          = aws.cloudfront_acm
  domain_name       = var.short_url_domain
  validation_method = "DNS"
  tags = {
    Project = "short_urls"
  }
}

resource "aws_route53_record" "short_url_domain_cert_validation" {
  name    = aws_acm_certificate.short_url_domain_certificate.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.short_url_domain_certificate.domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.short_url_domain.id
  records = [aws_acm_certificate.short_url_domain_certificate.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "short_url_domain_cert" {
  provider                = aws.cloudfront_acm
  certificate_arn         = aws_acm_certificate.short_url_domain_certificate.arn
  validation_record_fqdns = [aws_route53_record.short_url_domain_cert_validation.fqdn]
}
