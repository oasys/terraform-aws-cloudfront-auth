# replace functionality of cloudfront-auth/build/build.js
# to allow running in environment without nodejs, such as terraform cloud

data "archive_file" "lambda" {
  depends_on = [
    null_resource.copy_files,
    local_file.config,
    local_file.private_key,
    local_file.private_key,
  ]
  type        = "zip"
  output_path = "${path.module}/lambda.zip"
  source_dir  = "${path.module}/lambda"
}

resource "null_resource" "copy_files" {
  triggers = {
    always_run       = timestamp()
    vendor           = var.vendor
    client_id        = var.client_id
    client_secret    = var.client_secret
    redirect_uri     = var.redirect_uri
    base_url         = var.base_url
    distributions    = var.distribution
    session_duration = var.session_duration
  }
  provisioner "local-exec" {
    command = "rm -rf ${path.module}/lambda && mkdir ${path.module}/lambda"
  }
  provisioner "local-exec" {
    command = "cp -r ${path.module}/cloudfront-auth/node_modules ${path.module}/lambda/"
  }
  provisioner "local-exec" {
    command = "cp ${path.module}/cloudfront-auth/nonce.js ${path.module}/lambda/"
  }
  provisioner "local-exec" {
    command = "cp ${path.module}/cloudfront-auth/package.json ${path.module}/lambda/"
  }
  provisioner "local-exec" {
    command = "cp ${path.module}/cloudfront-auth/package-lock.json ${path.module}/lambda/"
  }
  provisioner "local-exec" {
    command = "cp ${path.module}/cloudfront-auth/authn/openid.index.js ${path.module}/lambda/index.js"
  }
  provisioner "local-exec" {
    command = "cp ${path.module}/cloudfront-auth/authz/okta.js ${path.module}/lambda/auth.js"
  }
}

resource "local_file" "private_key" {
  depends_on      = [null_resource.copy_files]
  filename        = "${path.module}/lambda/id_rsa"
  content         = tls_private_key.keypair.private_key_pem
  file_permission = "0600"
}

resource "local_file" "public_key" {
  depends_on      = [null_resource.copy_files]
  filename        = "${path.module}/lambda/id_rsa.pub"
  content         = tls_private_key.keypair.public_key_pem
  file_permission = "0644"
}

resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "config" {
  filename = "${path.module}/lambda/config.json"
  sensitive_content = jsonencode({
    "_terraform_refresh" : null_resource.copy_files.id,
    "AUTH_REQUEST" : {
      "client_id" : var.client_id,
      "response_type" : "code",
      "scope" : "openid email",
      "redirect_uri" : var.redirect_uri
    },
    "TOKEN_REQUEST" : {
      "client_id" : var.client_id,
      "client_secret" : var.client_secret,
      "redirect_uri" : var.redirect_uri,
      "grant_type" : "authorization_code"
    },
    "DISTRIBUTION" : var.distribution,
    "AUTHN" : var.vendor,
    "PRIVATE_KEY" : tls_private_key.keypair.private_key_pem,
    "PUBLIC_KEY" : tls_private_key.keypair.public_key_pem,
    "DISCOVERY_DOCUMENT" : "${var.base_url}/.well-known/openid-configuration",
    "SESSION_DURATION" : var.session_duration * 60 * 60,
    "BASE_URL" : var.base_url,
    "CALLBACK_PATH" : "/_callback",
    "AUTHZ" : var.vendor
  })
}
