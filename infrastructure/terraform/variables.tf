variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "voting-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-01ec84b284795cbc7" # Ubuntu 22.04 LTS (eu-west-2)
}

variable "zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
  default     = "Z0123456789ABCDEF"
}

variable "cloudflare_zone_id" {
  type = string
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "abu.work"
}

variable "allowed_ips" {
  description = "List of CIDR blocks allowed to access the ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cname_labels" {
  description = "List of CNAME labels for Cloudflare"
  type        = list(string)
  default     = ["staging", "prod", "dev"]
}

variable "cloudflare_proxied" {
  description = "Whether Cloudflare records should be proxied"
  type        = bool
  default     = true
}