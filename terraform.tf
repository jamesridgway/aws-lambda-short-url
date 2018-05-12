terraform {
  backend "s3" {
    key    = "jamesridgway/projects/aws-lambda-short-url"
    region = "eu-west-1"
  }
}
