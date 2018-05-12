variable "region" {
  default = "eu-west-1"
  description = "The AWS reegion to use for the Short URL project."
}
variable "short_url_domain" {
  type = "string"
  description = "The domain name to use for short URLs."
}
variable "account_id" {
  type = "string"
  description = "Your AWS account ID."
}