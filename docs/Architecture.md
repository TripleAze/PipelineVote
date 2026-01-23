# System Architecture

This project implements a highly available, secure, and automated infrastructure for a Spring Boot Voting Application.

## Design Principles

### 1. Security by Design
- **Network Isolation**: All compute resources (EC2, RDS) are placed in private subnets. Only the ALB is public-facing.
- **Least Privilege IAM**: Managed instances use restricted IAM roles with specific permissions for SSM and Secrets Manager.
- **Credential Management**: Database passwords are automatically generated and stored in **AWS Secrets Manager**, rotated by infrastructure logic.

### 2. Scalability & Availability
- **Auto Scaling**: The application tier is managed by an **Auto Scaling Group (ASG)** that ensures a minimum number of healthy instances across multiple Availability Zones.
- **Elastic Load Balancing**: The ALB handles SSL termination and distributes traffic based on health checks.

### 3. Automation-First (CI/CD)
- **Terraform State**: Orchestrated with S3/DynamoDB for remote state locking, allowing team collaboration without state corruption.
- **Jenkins Pipelines**: Fully parameterized pipelines for multi-environment (Dev, Staging, Prod) deployments.

## Component Overview

| Component | Responsibility |
| :--- | :--- |
| **VPC** | Logical isolation of resources |
| **ALB** | Entry point, SSL termination, path-based routing |
| **ASG** | Application compute layer with auto-recovery |
| **RDS** | Persistent MySQL database storage |
| **Secrets Manager** | Secure storage of DB credentials |
| **SSM Parameter Store** | Decoupling DB connectivity from secrets (breaks circular dependencies) |

## Data Flow
1. User requests hit the **ALB** via **HTTPS**.
2. **ALB** forwards traffic to the **ASG** instances in the private subnet.
3. **App Instances** retrieve credentials from **Secrets Manager** and connection info from **SSM**.
4. **App Instances** connect to **RDS MySQL**.
5. **ALB** writes access logs to **S3** for monitoring.
