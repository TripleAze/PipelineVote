variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in the format 'username/repo-name'"
}

variable "openid_connect_provider_arn" {
  type        = string
  description = "ARN of the GitHub OpenID Connect provider"
}

variable "region" {
  type = string
}

variable "account_id" {
  type = string
}
