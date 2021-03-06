# Terraform CloudFront OpenID Connect

## Introduction

This module will build a website that is protected by an
[OpenId](https://openid.net/what-is-openid/)-compatible
authentication provider.  It will provision a private S3
bucket, [Cloudfront](https://aws.amazon.com/cloudfront/),
and deploy a customized Lambda function using
[Lambda@Edge](https://aws.amazon.com/lambda/edge/).

Currently only OKTA is supported, but can easily be extended
to support others (Google/Microsoft/GitHub/Auth0/Centrify).

## Based on

This project uses the nodejs code from
[Widen](https://github.com/Widen/cloudfront-auth/) for the Lambda
function.  Their repository includes a `build.js` script that
interactively prompts for configuration items (client_id, client_secret,
etc.) and builds the lambda zip file.  This does not lend itself well
to automation; this repository replaces that logic with `build.tf`
and `local-exec` resources create the archive.

The Scale Factory team created the (now hibernating)
[terraform-cloudfront-auth](https://github.com/scalefactory/terraform-cloudfront-auth)
project to allow passing environment variables to the Widen `build.js`
script.  Their project still requires executing the nodejs script,
which does not work for environments where those dependencies are not
available, such as a [Terraform Cloud](https://www.terraform.io/cloud)
runner.

## Caveats

The
[archive_file](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/archive_file)
data source is used in this project.  Terraform will always generate
a plan to modify resources, even when a `terraform apply` will make no changes.
This will generate false positives when `terraform plan` is run periodically
to check for configuration drift.

## Usage

```terraform
data "aws_acm_certificate" "cert" {
  domain = "*.example.com"
}

module "cloudfront_okta" {
  source        = "github.com/oasys/terraform-aws-cloudfront-openid"
  hostname      = "www.example.com"
  acm_cert_arn  = data.aws_acm_certificate.cert.arn
  auth_provider = "OKTA"
  client_id     = okta_app_oauth.www.client_id
  client_secret = okta_app_oauth.www.client_secret
  redirect_uri  = "https://www.example.com/_callback"
  base_url      = "https://example.okta.com"
  deploy_arn    = var.deploy_arn
}
```

<!-- markdownlint-disable -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| archive | ~> 2.1 |
| aws | ~> 3.0 |
| local | ~> 2.1 |
| null | ~> 3.0 |
| tls | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| archive | ~> 2.1 |
| aws | ~> 3.0 |
| local | ~> 2.1 |
| null | ~> 3.0 |
| tls | ~> 3.0 |

## Modules

No Modules.

## Resources

| Name |
|------|
| [archive_file](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) |
| [aws_cloudfront_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) |
| [aws_cloudfront_origin_access_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity) |
| [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) |
| [aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) |
| [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) |
| [aws_lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) |
| [aws_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) |
| [aws_s3_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) |
| [aws_s3_bucket_public_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) |
| [local_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) |
| [null_resource](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) |
| [tls_private_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| acm\_cert\_arn | ARN of AWS Certificate Manager certificate for website. | `string` | n/a | yes |
| aliases | List of any aliases (CNAMEs) for the website. | `list(string)` | `[]` | no |
| always\_rebuild | Always create new lambda zip source directory.  Useful for environments, such as Terraform Cloud, where the terraform runner does not preserve local disk contents. | `bool` | `true` | no |
| auth\_provider | Authentication provider.  Currently only 'OKTA' is supported. | `string` | `"OKTA"` | no |
| base\_url | The base\_url or Org URL of the authentication provider. | `string` | n/a | yes |
| client\_id | The client\_id from authentication provider. | `string` | n/a | yes |
| client\_secret | The client\_secret from authentication provider. | `string` | n/a | yes |
| deploy\_arn | (Optional) IAM user to give permissions to update site (via s3 bucket). | `string` | `null` | no |
| hostname | Hostname of the managed website. | `string` | n/a | yes |
| redirect\_uri | The URI to redirect users to after successful login.  Defaults to /\_callback on hostname. | `string` | `null` | no |
| s3\_bucket\_name | Name of website S3 bucket.  Must be globally unique.  Defaults to hostname. | `string` | `null` | no |
| session\_duration | Length of time session will be valid. | `number` | `24` | no |
| tags | Common tags for created resources | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cloudfront\_distribution | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-restore -->
