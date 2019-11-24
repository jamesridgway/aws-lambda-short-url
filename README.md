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
Initialise the backend to use an S3 bucket to store the state (this only needs to be done once):
```
$ terraform init -backend-config "bucket=terraform-states.example.com"
```
Alternatively you can remove `terraform.tf` which defines the backend store - this will cause terraform to default to local file storage.

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

admin_api_key          = uWyv6B1NPI0vWxVPeQD46ctlmWd6l7x3YLSYCRf0
cloudfront_domain_name = d111111abcdef8.cloudfront.net
short_url_domain       = example.com
```

## Using the API
Deploying the infrastructure with terraform will take only a few minutes and once the CloudFront distribution has been fully initialised you'll be ready to start creating URLs.

### Creating a Short URL

Creating a URL is done with a `POST` request to the `/admin` endpoint. The `x-api-key` header should be set to the `Admin API Key` value that was generated in the output of the terraform setup:

```
curl -X POST \
	-d '{"url": "https://www.james-ridgway.co.uk/blog/build-your-own-custom-short-url-generator-using-aws"}' \
	-H "x-api-key: XXXXX" \
	http://exmple.com/admin
```

The response will provide you with the full short URL and token value in JSON output:

```
{
	"short_url": "https://example.com/cwM1iQ",
	"url": "https://www.james-ridgway.co.uk/blog/build-your-own-custom-short-url-generator-using-aws",
	"token": "cwM1iQ"
}
```

### Visit a Short URL
So here's an example of one of my short URL: [https://jmsr.io/cwM1iQ](https://jmsr.io/cwM1iQ). This link is a short link to my [Build your own custom Short URL generator using AWS](https://www.james-ridgway.co.uk/blog/build-your-own-custom-short-url-generator-using-aws) blog post.

CloudFront serves up the empty S3 object as shown below using CURL with the vebose flag. You get a `301 Moved Permanently` response with the `Location` header set to the full URL.

```
$ curl -v https://jmsr.io/cwM1iQ
*   Trying 54.192.197.16...
* Connected to jmsr.io (54.192.197.16) port 443 (#0)
* found 148 certificates in /etc/ssl/certs/ca-certificates.crt
* found 597 certificates in /etc/ssl/certs
* ALPN, offering http/1.1
* SSL connection using TLS1.2 / ECDHE_RSA_AES_128_GCM_SHA256
*        server certificate verification OK
*        server certificate status verification SKIPPED
*        common name: jmsr.io (matched)
*        server certificate expiration date OK
*        server certificate activation date OK
*        certificate public key: RSA
*        certificate version: #3
*        subject: CN=jmsr.io
*        start date: Mon, 07 May 2018 00:00:00 GMT
*        expire date: Fri, 07 Jun 2019 12:00:00 GMT
*        issuer: C=US,O=Amazon,OU=Server CA 1B,CN=Amazon
*        compression: NULL
* ALPN, server accepted to use http/1.1
> GET /cwM1iQ HTTP/1.1
> Host: jmsr.io
> User-Agent: curl/7.47.0
> Accept: */*
> 
< HTTP/1.1 301 Moved Permanently
< Content-Length: 0
< Connection: keep-alive
< Date: Sat, 12 May 2018 08:36:48 GMT
< Location: https://www.james-ridgway.co.uk/blog/build-your-own-custom-short-url-generator-using-aws
< Server: AmazonS3
< X-Cache: Miss from cloudfront
< Via: 1.1 95a4581bed116b6338fc42595fee6f43.cloudfront.net (CloudFront)
< X-Amz-Cf-Id: s4q4k2DkWwc6jxNvA2XWQYK_wJC51_QDag2CucX-a67aq3si78_9Gw==
< 
* Connection #0 to host jmsr.io left intact
```

### Deleting a Short URL

Deleting an endpoint is also done via a `DELETE` request to `/admin/<token>`, for example:

```
curl -X DELETE -H "x-api-key: XXXXX" http://example.com/admin/cwM1iQ
```
