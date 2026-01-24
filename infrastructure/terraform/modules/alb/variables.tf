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
  default     = "voting-portal.chickenkiller.com"
}

variable "zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
  default     = null
}
