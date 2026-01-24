# Project Evolution & Retrospective

This document tracks the journey of the **PipelineVote** project, detailing the challenges faced, bugs resolved, and the continuous improvements made to transform the codebase into a production-ready infrastructure.

## Milestones & Improvements

### 1. From Static to Dynamic
- **Initial State**: The application was deployed on a single, static EC2 instance.
- **Problem**: No high availability; if the instance failed, the app went down.
- **Improvement**: Implemented **Auto Scaling Groups (ASG)** and **Launch Templates**. The system now automatically recovers and scales based on demand.

### 2. Transition to Remote State
- **Initial State**: Terraform state was stored locally.
- **Problem**: Risk of state corruption and lack of collaboration.
- **Improvement**: Configured **S3 for Remote State** and **DynamoDB for State Locking**, ensuring a safe and collaborative environment.

### 3. Multi-Environment Isolation
- **Initial State**: A single configuration for all environments.
- **Problem**: High risk of breaking production when testing changes.
- **Improvement**: Refactored to use **Environment-Specific Variable Files** (`dev.tfvars`, `staging.tfvars`, `prod.tfvars`) and a **Parameterized Jenkins Pipeline**.

---

## Notable Bugs & Solutions

### The "Circular Dependency" Deadlock
- **The Issue**: I tried to store the RDS Host in a Secrets Manager secret. However, the RDS instance needed the secret for its password, but the secret needed the RDS host (which isn't known until *after* RDS is created).
- **The Solution**: I decoupled the configuration.
    - **Secrets Manager**: Now only stores static credentials (username/password).
    - **SSM Parameter Store**: Stores dynamic metadata (host, port).
- **Result**: Fully automated, single-run deployments are now possible.

### Sensitive Data Exposure
- **The Issue**: Initial `terraform.tfvars` contained sensitive domain and zone IDs.
- **The Solution**: Created `terraform.tfvars.example` and a robust `.gitignore` file to ensure sensitive local configurations are never pushed to GitHub.

### Public Exposure Risk
- **The Issue**: Compute resources were initially accessible from the internet.
- **The Solution**: Moved all EC2 and RDS resources into **Private Subnets** and implemented a **NAT Gateway** for outbound-only traffic. Restricted the ALB to a configurable **IP Allow List**.

---

## Security & Observability Upgrades

- **Least Privilege**: Switched from broad IAM roles to custom policies (e.g., `secretsmanager:GetSecretValue` on specific ARNs).
- **ALB Access Logs**: Enabled logging to S3 for auditing.
- **Cost Optimization**: Added **S3 Lifecycle Rules** to automatically expire (delete) log files older than 90 days.
- **Standardized Structure**: Restructured the repo into `app/`, `infrastructure/`, `cicd/`, and `docs/` for professional maintainability.
