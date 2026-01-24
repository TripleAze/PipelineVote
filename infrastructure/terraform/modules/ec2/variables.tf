variable "instances" {
  description = "Map of instances to create"
  type = map(object({
    instance_type      = string
    name               = string
    role               = string
    security_group_ids = list(string)
  }))
}

variable "ami_id" {
  description = "AMI ID for the instances"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "secret_arns" {
  description = "List of Secrets Manager ARNs the EC2 instances can access"
  type        = list(string)
  default     = []
}

variable "app_target_group_arns" {
  description = "List of Target Group ARNs for the ASG"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = null
}

variable "ssm_transport_bucket_arn" {
  description = "ARN of the S3 bucket for Ansible SSM transport"
  type        = string
}
