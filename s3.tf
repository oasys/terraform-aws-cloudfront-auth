locals {
  s3_bucket_name = var.s3_bucket_name == null ? var.hostname : var.s3_bucket_name
}

resource "aws_s3_bucket" "site" {
  bucket = local.s3_bucket_name
  acl    = "private"
  # checkov:skip=CKV_AWS_21:versioning not needed
  # checkov:skip=CKV_AWS_18:access logging disabled for cost savings
  # checkov:skip=CKV_AWS_19:encryption disabled, public website
  # checkov:skip=CKV_AWS_52:no MFA delete, not canonical source
  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    actions   = ["s3:GetObject", ]
    resources = ["${aws_s3_bucket.site.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.site.arn]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }

  statement {
    actions   = ["s3:PutObject", "s3:PutObjectAcl"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [var.deploy_arn]
    }
  }

}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.s3_bucket_policy.json
}
