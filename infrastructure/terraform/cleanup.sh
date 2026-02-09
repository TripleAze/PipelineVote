#!/bin/bash
# Terraform Cleanup Script for voting-app-dev
REGION="eu-west-2"
PROJECT="voting-app-dev"

echo "Cleaning up conflicting resources..."

# 1. Delete DynamoDB Lock Table
aws dynamodb delete-table --table-name "${PROJECT}-terraform-locks" --region $REGION || true

# 2. Delete Conflicting IAM Role and Policies
# First detach policies
aws iam detach-role-policy --role-name "${PROJECT}-ec2-role" --policy-arn "arn:aws:iam::454448876799:policy/${PROJECT}-secrets-policy" || true
aws iam detach-role-policy --role-name "${PROJECT}-ec2-role" --policy-arn "arn:aws:iam::454448876799:policy/${PROJECT}-ssm-config-policy" || true
aws iam detach-role-policy --role-name "${PROJECT}-ec2-role" --policy-arn "arn:aws:iam::454448876799:policy/${PROJECT}-ec2-mgmt-policy" || true

# Delete policies
aws iam delete-policy --policy-arn "arn:aws:iam::454448876799:policy/${PROJECT}-secrets-policy" || true
aws iam delete-policy --policy-arn "arn:aws:iam::454448876799:policy/${PROJECT}-ssm-config-policy" || true
aws iam delete-policy --policy-arn "arn:aws:iam::454448876799:policy/${PROJECT}-ec2-mgmt-policy" || true

# Delete role
aws iam delete-role --role-name "${PROJECT}-ec2-role" || true

# 3. Delete RDS DB Subnet Group
aws rds delete-db-subnet-group --db-subnet-group-name "${PROJECT}-db-subnet-group" --region $REGION || true

# 4. S3 Buckets (Must be empty or use force)
# Note: We won't delete the state bucket itself to avoid bootloop, but we delete transport/logs
aws s3 rb "s3://${PROJECT}-ansible-ssm-transport" --force --region $REGION || true
aws s3 rb "s3://${PROJECT}-alb-logs-${PROJECT}" --force --region $REGION || true

echo "Cleanup complete. Please run: terraform init -reconfigure"
