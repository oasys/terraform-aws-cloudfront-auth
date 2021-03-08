locals {
  aliases  = ["mywww.example.com"]
  hostname = "www.example.com"
}

# pre-existing user group
data "okta_group" "users" {
  name = "My Okta Group"
}

resource "okta_app_oauth" "app" {
  label                      = "My Okta App"
  type                       = "web"
  grant_types                = ["authorization_code"]
  response_types             = ["code"]
  token_endpoint_auth_method = "client_secret_basic"
  consent_method             = "TRUSTED"
  issuer_mode                = "CUSTOM_URL"
  login_mode                 = "DISABLED"

  hide_ios = true
  hide_web = true

  redirect_uris = [
    for domain in concat([local.hostname], local.aliases) :
    "https://${domain}/_callback"
  ]

  # per the NOTE in the docs to "prevent the groups being unassigned on subsequent runs"
  # https://registry.terraform.io/providers/oktadeveloper/okta/latest/docs/resources/app_group_assignment
  lifecycle {
    ignore_changes = [groups]
  }
}

resource "okta_app_group_assignment" "access" {
  app_id   = okta_app_oauth.app.id
  group_id = data.okta_group.users.id
}

# pre-existing and pre-validated TLS certificate
data "aws_acm_certificate" "cert" {
  domain = "*.example.com"
}

module "cloudfront_okta" {
  source        = "oasys/cloudfront-auth/aws"
  version       = "1.0.0"
  hostname      = local.hostname
  auth_provider = "OKTA"
  client_id     = okta_app_oauth.app.client_id
  client_secret = okta_app_oauth.app.client_secret
  base_url      = "https://login.example.com"
  acm_cert_arn  = data.aws_acm_certificate.cert.arn
  aliases       = local.aliases
}

# pre-existing DNS zone
data "aws_route53_zone" "zone" {
  name         = "example.com"
  private_zone = false
}

# add alias "records" to cloudfront distribution
resource "aws_route53_record" "alias" {
  for_each = toset(["A", "AAAA"])
  zone_id  = data.aws_route53_zone.zone.zone_id
  name     = local.hostname
  type     = each.key
  alias {
    name                   = module.cloudfront_okta.cloudfront_distribution.domain_name
    zone_id                = module.cloudfront_okta.cloudfront_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
