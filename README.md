# 2-Tier AWS Infrastructure Automation

Automated deployment of a secure 2-tier application (VotingApp) on AWS using Terraform, Ansible, and Jenkins.

## Prerequisites
- AWS CLI configured with appropriate credentials.
- Terraform v1.x+
- Ansible v2.x+
- Jenkins server (optional, for CI/CD).
- Pre-commit installed.

## Project Structure
- `terraform/`: Infrastructure as Code modules.
- `ansible/`: Configuration management roles and playbooks.
- `VotingApp/`: Spring Boot application source code.
- `Jenkinsfile`: CI/CD pipeline definition.
- `.pre-commit-config.yaml`: Security scanning configuration.

## Setup Instructions

### 1. Infrastructure Provisioning
```bash
cd terraform
terraform init
terraform apply -auto-approve
```

### 2. Configuration Management
Ensure the `aws_ec2.yml` inventory is configured correctly, then run:
```bash
cd ansible
ansible-playbook -i aws_ec2.yml playbook.yml
```

### 3. CI/CD Pipeline
Commit the code to a GitHub repository and point Jenkins to the `Jenkinsfile`. Ensure Jenkins has the necessary AWS credentials and SSH keys.

## Security Features
- **Network Isolation**: Databases and application servers are in private subnets.
- **Secret Management**: RDS credentials are stored in AWS Secrets Manager.
- **SSM Management**: No SSH keys required; instances are managed via AWS Systems Manager.
- **Static Analysis**: Pre-commit hooks for secret detection and Terraform linting.
```
