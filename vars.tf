variable "auth_provider" {
  type    = string
  default = "OKTA"
  validation {
    condition     = contains(["OKTA"], var.auth_provider)
    error_message = "Not a supported authentication provider."
  }
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

variable "deploy_arn" {
  description = "IAM user to give permissions to update site (via s3 bucket)."
  type        = string
}

variable "aliases" {
  type    = list(string)
  default = []
}

variable "always_rebuild" {
  type    = bool
  default = true
}

variable "tags" {
  description = "Common tags for created resources"
  type        = map(any)
  default     = {}
}
