
resource "aws_acm_certificate" "short_url_domain_certificate" {
  provider          = aws.cloudfront_acm
  domain_name       = var.short_url_domain
  validation_method = "DNS"
  tags = {
    Project = "short_urls"
  }
}

resource "aws_acm_certificate_validation" "short_url_domain_cert" {
  provider                = aws.cloudfront_acm
  certificate_arn         = aws_acm_certificate.short_url_domain_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.short_url_domain_cert_validation : record.fqdn]
}

resource "aws_route53_record" "short_url_domain_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.short_url_domain_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.short_url_domain.id
}