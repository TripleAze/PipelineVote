# Troubleshooting Guide

A guide to resolving common issues in the PipelineVote project.

## 1. Terraform Issues

### Circular Dependency
**Symptoms**: Terraform fails to plan because RDS depends on Secrets and vice versa.
**Solution**: This is already resolved by moving `db_host` to **SSM Parameter Store**. Ensure you are not putting the RDS endpoint directly into the Secret Version resource.

### STS Forbidden (403)
**Symptoms**: `Error: Retrieving AWS account details: operation error STS: GetCallerIdentity... StatusCode: 403`
**Solution**: Your AWS credentials/token have expired. Re-authenticate using `aws configure` or export new `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

## 2. ALB & Access Issues

### Health Checks Failing
**Symptoms**: ASG instances are being terminated immediately after launch.
**Check**:
- Ensure the Security Group `app-sg` allows traffic on port 8080 from `alb-sg`.
- Ensure the application is actually running on port 8080 and responding to `/`.

### 403 Forbidden on ALB
**Symptoms**: You cannot access the application via the browser.
**Solution**: Check the `allowed_ips` variable. If it's set to something other than `0.0.0.0/0`, only those specific IPs can access the site.

## 3. Jenkins Issues

### Pipeline Fails at 'Terraform Init'
**Check**:
- Verify the Jenkins user has the correct AWS IAM permissions.
- Ensure the S3 bucket defined in the backend actually exists.

### SCP/SSH Failures
**Check**:
- Since instances are in a private subnet, verify **SSM Session Manager** is working. 
- Ensure the `AmazonSSMManagedInstanceCore` policy is attached to the EC2 role.
