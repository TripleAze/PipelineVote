# Deployment Guide

Follow these steps to deploy the PipelineVote infrastructure and application.

## Prerequisites
- AWS Account with appropriate permissions.
- Terraform CLI installed.
- Jenkins server (managed by this project or existing).
- Registered Domain Name (configured in Route 53).

## Phase 1: Local Setup
1. Clone the repository.
2. Navigate to `infrastructure/terraform/`.
3. Copy `terraform.tfvars.example` to `dev.tfvars` (or your chosen env) and fill in the values.

## Phase 2: Remote State Provisioning
Before the main deployment, provision the S3 bucket and DynamoDB table for state locking:
```bash
terraform apply -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_locks
```

## Phase 3: Enable Remote Backend
1. Edit `providers.tf` and uncomment the `backend "s3"` block.
2. Initialize and migrate state:
   ```bash
   terraform init -migrate-state
   ```

## Phase 4: Full Deployment
Now you can deploy the entire stack:
```bash
terraform apply -var-file=envs/dev.tfvars
```

## Phase 5: Jenkins Pipeline
1. Create a "Pipeline" job in Jenkins.
2. Point it to the `cicd/Jenkinsfile`.
3. Run with Parameters:
   - **ENVIRONMENT**: dev/staging/prod
   - **ACTION**: plan/apply
