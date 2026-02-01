variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Custom domain name"
  type        = string
  default     = "abu.work"
}

variable "cloudflare_api_token" {
  description = "Cloudflare auth key"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}

variable "cname_labels" {
  description = "Cloudflare Zone name"
  type        = list(string)
  default     = ["staging", "prod", "dev"]
}

variable "cloudflare_proxied" {
  type    = bool
  default = true
}
