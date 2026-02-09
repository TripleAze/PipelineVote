variable "environments" {
  type    = list(string)
  default = ["dev", "staging", "prod"]
}

locals {
  configs = {
    dev = {
      project_name = "voting-app-dev"
      environment  = "dev"
      domain_name  = "limanalhassan.work"
      allowed_ips  = "0.0.0.0/0"
    }
    staging = {
      project_name = "voting-app-staging"
      environment  = "staging"
      domain_name  = "limanalhassan.work"
      allowed_ips  = "98.97.76.83"
    }
    prod = {
      project_name = "voting-app-prod"
      environment  = "prod"
      domain_name  = "limanalhassan.work"
      allowed_ips  = "98.97.76.83"
    }
  }
}

resource "aws_ssm_parameter" "config" {
  for_each = {
    for pair in flatten([
      for env in var.environments : [
        for key, value in local.configs[env] : {
          env   = env
          key   = key
          value = value
        }
      ]
    ]) : "${pair.env}_${pair.key}" => pair
  }

  name        = "/config/${each.value.env}/${each.value.key}"
  description = "Config for ${each.value.env} - ${each.value.key}"
  type        = "String"
  value       = each.value.value
  overwrite   = true

  tags = {
    Environment = each.value.env
    Project     = "voting-app"
  }
}
