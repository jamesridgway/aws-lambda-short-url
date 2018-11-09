provider "aws" {
  region = "${var.region}"
}
provider "aws" {
  region = "us-east-1"
  alias  = "cloudfront_acm"
}

provider "archive" {
}

data "aws_caller_identity" "current" {
}