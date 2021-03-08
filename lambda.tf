data "aws_iam_policy_document" "lambda_log_access" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

# This function is created in us-east-1 as required by CloudFront.
resource "aws_lambda_function" "cloudfront_auth" {
  #provider = aws.us-east-1
  # checkov:skip=CKV_AWS_50:x-ray tracing not used
  description      = "${var.auth_provider} authentication for ${var.hostname}"
  runtime          = "nodejs12.x"
  role             = aws_iam_role.lambda_role.arn
  filename         = "${path.module}/lambda.zip"
  function_name    = "${replace(var.hostname, "/[^A-Za-z0-9-]/", "_")}-cloudfront_auth"
  handler          = "index.handler"
  publish          = true
  timeout          = 5
  source_code_hash = data.archive_file.lambda.output_base64sha256
  tags             = var.tags
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "edgelambda.amazonaws.com",
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_log_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_log_access.arn
}

resource "aws_iam_policy" "lambda_log_access" {
  name   = "cloudfront_auth_lambda_log_access"
  policy = data.aws_iam_policy_document.lambda_log_access.json
}
