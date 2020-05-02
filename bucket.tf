resource "aws_s3_bucket" "short_urls_bucket" {
  bucket = var.short_url_domain
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
  tags = {
    Project = "short_urls"
  }
}
