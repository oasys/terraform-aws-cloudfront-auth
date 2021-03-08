data "aws_iam_policy_document" "lambda_log_access" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:*:*:*",
    ]
    effect = "Allow"
  }
}

# This function is created in us-east-1 as required by CloudFront.
resource "aws_lambda_function" "cloudfront_auth" {
  #provider = aws.us-east-1
  # checkov:skip=CKV_AWS_50:x-ray tracing not used
  description      = "Managed by Terraform"
  runtime          = "nodejs12.x"
  role             = aws_iam_role.lambda_role.arn
  filename         = "${path.module}/lambda.zip"
  function_name    = "cloudfront_auth"
  handler          = "index.handler"
  publish          = true
  timeout          = 5
  source_code_hash = data.archive_file.lambda.output_base64sha256
  tags             = var.tags
}

data "aws_iam_policy_document" "lambda_assume_role" {
  // Trust relationships taken from blueprint
  // Allow lambda to assume this role.
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"
      identifiers = [
        "edgelambda.amazonaws.com",
        "lambda.amazonaws.com",
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

# Attach the logging access document to the above role.
resource "aws_iam_role_policy_attachment" "lambda_log_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_log_access.arn
}

# Create an IAM policy that will be attached to the role
resource "aws_iam_policy" "lambda_log_access" {
  name   = "cloudfront_auth_lambda_log_access"
  policy = data.aws_iam_policy_document.lambda_log_access.json
}
