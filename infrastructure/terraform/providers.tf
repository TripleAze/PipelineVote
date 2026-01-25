terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  # backend "s3" {
  #   bucket       = "voting-app-dev-terraform-state-rivf4j"
  #   key          = "global/s3/terraform.tfstate"
  #   region       = "eu-west-2"
  #   use_lockfile = true
  #   encrypt      = true
  # }
}

provider "aws" {
  region = var.region
}
