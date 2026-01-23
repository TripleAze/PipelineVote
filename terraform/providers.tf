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

  # Remember to run 'terraform apply' to create the S3 bucket and DynamoDB table,
  # Then uncomment this block and run 'terraform init' to migrate your state.
  # Note: Replace 'BUCKET_NAME_HERE' with the output 'state_bucket_name'.
  
  # backend "s3" {
  #   bucket         = "BUCKET_NAME_HERE"
  #   key            = "global/s3/terraform.tfstate"
  #   region         = "eu-west-2"
  #   dynamodb_table = "voting-app-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region
}
