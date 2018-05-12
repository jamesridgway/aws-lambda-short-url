# AWS Lambda Short URL Generator

Use terraform to quickly setup your own Short URL generator using a custom domain with AWS API Gateway, CloudFront, Lambda, Route 53 and S3.

## Approach

The plan is to use CloudFront to cache redirecting web pages at the edge of the CloudFront network that will redirect form the short URL to the full URL.

The redirecting web pages will be served up from S3. With S3 you can create an object with a meta data entry called `Website Redirect Location`. When an S3 bucket is configured to host a static website objects ( with a `Website Redirect Location` metadata entry) will be served up over HTTP as a redirecting webpage.

![AWS Lambda Short URL Generator - Approach Overview](https://www.james-ridgway.co.uk/system/images/images/000/000/010/original/approach.png)

API Gateway and AWS Lambda will be used to create and delete shortlinks via HTTP API calls. The API will be protected with an API key, and will be served up via the same CloudFront distrubtion.

Finally Route 53 will alias the custom domain name to the domain name of the CloudFront distribution.

## Prerequisites
Setup the domain that you want to use for your short URLs as a Hosted Zone in Route 53. Details of how to do this can be found [here](https://www.james-ridgway.co.uk/blog/build-your-own-custom-short-url-generator-using-aws).

## Deploy

Use terraform to apply the infrastructure change needed to run this short URL generator:

```
$ terraform apply
```

You'll be prompted for:

* The short URL domain you want to use (e.g. `example.com`)
* Your AWS account number

Once the infrastrucutre has been created it will be given an output similar to the following:

```
Outputs:

Admin API Key = uWyv6B1NPI0vWxVPeQD46ctlmWd6l7x3YLSYCRf0
CloudFront Domain Name = d111111abcdef8.cloudfront.net
Short URL Doamin = example.com
```



## Custom Domain (with HTTPS)

Setting up a custom domain with HTTPS requires a few manual steps to be completed. This will take you only a few minutes.

You can read the steps for setting up your custom domain [here](https://www.james-ridgway.co.uk/blog/build-your-own-custom-short-url-generator-using-aws).
