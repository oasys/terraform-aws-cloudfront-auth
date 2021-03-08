locals {
  s3_bucket_name = var.s3_bucket_name == null ? var.hostname : var.s3_bucket_name
  redirect_uri   = var.redirect_uri == null ? "https://${var.hostname}/_callback" : var.redirect_uri
}
