output "s3_bucket" {
  description = "S3 bucket"
  value       = aws_s3_bucket.site
}

output "cloudfront_distribution" {
  description = "CloudFront distribution"
  value       = aws_cloudfront_distribution.dist
}

output "lambda_function" {
  description = "Lambda function"
  value       = aws_lambda_function.cloudfront_auth
}
