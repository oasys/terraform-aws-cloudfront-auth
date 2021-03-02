
data "aws_s3_bucket" "site" {
  bucket = var.s3_bucket_name
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = var.s3_bucket_name
}

resource "aws_cloudfront_distribution" "dist" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  aliases             = concat([var.distribution], [var.s3_bucket_name], var.aliases)

  # checkov:skip=CKV_AWS_68:do not require WAF to reduce costs
  # checkov:skip=CKV_AWS_86:no access logging

  origin {
    origin_id   = data.aws_s3_bucket.site.id
    domain_name = data.aws_s3_bucket.site.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", ]
    target_origin_id       = data.aws_s3_bucket.site.id
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    forwarded_values {
      query_string = false
      headers = [
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method",
        "Origin"
      ]
      cookies {
        forward = "none"
      }
    }
    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = aws_lambda_function.cloudfront_auth.qualified_arn
    }
  }
  viewer_certificate {
    acm_certificate_arn = var.acm_cert_arn
    ssl_support_method  = "sni-only"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  #tags                = var.tags
}

# give cloudfront access to bucket
data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    actions   = ["s3:GetObject", ]
    resources = ["${data.aws_s3_bucket.site.arn}/*", ]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn, ]
    }
  }

  statement {
    actions   = ["s3:ListBucket", ]
    resources = [data.aws_s3_bucket.site.arn, ]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn, ]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = data.aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}
