variable "hostname" {
  description = "Hostname of the managed website."
  type        = string
  validation {
    condition     = can(regex("^[.0-9a-z-]+$", var.hostname))
    error_message = "The hostname must be a valid DNS name."
  }
}

variable "auth_provider" {
  description = "Authentication provider.  Currently only 'OKTA' is supported."
  type        = string
  default     = "OKTA"
  validation {
    condition     = contains(["OKTA"], var.auth_provider)
    error_message = "This is not a supported authentication provider."
  }
}

variable "client_id" {
  description = "The client_id from authentication provider."
  type        = string
}

variable "client_secret" {
  description = "The client_secret from authentication provider."
  type        = string
  sensitive   = true
}

variable "redirect_uri" {
  description = "The URI to redirect users to after successful login.  Defaults to /_callback on hostname."
  type        = string
  default     = null
  validation {
    condition     = can(regex("^https?://", var.redirect_uri))
    error_message = "URI must begin with 'http://' or 'https://'."
  }
}

variable "base_url" {
  description = "The base_url or Org URL of the authentication provider."
  type        = string
  validation {
    condition     = can(regex("^https?://", var.base_url))
    error_message = "URL must begin with 'http://' or 'https://'."
  }
}

variable "session_duration" {
  description = "Length of time session will be valid."
  type        = number
  default     = 24
}

variable "acm_cert_arn" {
  description = "ARN of AWS Certificate Manager certificate for website."
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of website S3 bucket.  Must be globally unique.  Defaults to hostname."
  type        = string
  default     = null
}

variable "deploy_arn" {
  description = "(Optional) IAM user to give permissions to update site (via s3 bucket)."
  type        = string
  default     = null
}

variable "aliases" {
  description = "List of any aliases (CNAMEs) for the website."
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for alias in var.aliases : can(regex("^[.0-9a-z-]+$", alias))
    ])
    error_message = "Aliases must be a valid DNS name."
  }
}

variable "always_rebuild" {
  description = "Always create new lambda zip source directory.  Useful for environments, such as Terraform Cloud, where the terraform runner does not preserve local disk contents."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags for created resources"
  type        = map(any)
  default     = {}
}
