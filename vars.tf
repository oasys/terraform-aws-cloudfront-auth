variable "vendor" {
  type    = string
  default = "OKTA"
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type      = string
  sensitive = true
}

variable "redirect_uri" {
  type = string
}

variable "base_url" {
  type = string
}

variable "session_duration" {
  description = "hours"
  type        = number
  default     = 24
}

variable "distribution" {
  type = string
}

variable "acm_cert_arn" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "aliases" {
  type    = list(string)
  default = []
}
