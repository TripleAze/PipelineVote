module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
}

data "github_ip_ranges" "hooks" {}
data "aws_caller_identity" "current" {}

# --- IAM / OIDC ---

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

resource "aws_s3_bucket" "ansible_ssm" {
  bucket        = "${var.project_name}-ansible-ssm-transport"
  force_destroy = true

  tags = {
    Name        = "Ansible SSM Transport"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "ansible_ssm" {
  bucket                  = aws_s3_bucket.ansible_ssm.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "iam" {
  source                      = "./modules/iam"
  project_name                = var.project_name
  environment                 = var.environment
  github_repo                 = var.github_repo
  openid_connect_provider_arn = aws_iam_openid_connect_provider.github.arn
  region                      = var.region
  account_id                  = data.aws_caller_identity.current.account_id
  ssm_transport_bucket_arn    = aws_s3_bucket.ansible_ssm.arn
}

# --- Security Groups ---

resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = concat(var.allowed_ips, [for ip in data.github_ip_ranges.hooks.hooks : ip if !strcontains(ip, ":")])
    ipv6_cidr_blocks = [for ip in data.github_ip_ranges.hooks.hooks : ip if strcontains(ip, ":")]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jenkins_sg" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Security group for Jenkins server"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-app-sg"
  description = "Security group for App servers"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ACM and Route 53 validation removed for path-based routing.

# --- SSM Parameters ---

resource "aws_ssm_parameter" "db_host" {
  name        = "/${var.project_name}/db_host"
  description = "RDS database endpoint"
  type        = "String"
  value       = module.rds.db_address
}

resource "aws_ssm_parameter" "db_port" {
  name        = "/${var.project_name}/db_port"
  description = "RDS database port"
  type        = "String"
  value       = "3306"
}

# --- Module Calls ---

module "secrets" {
  source       = "./modules/secrets"
  secret_name  = "${var.project_name}-db-secrets-v2"
  project_name = var.project_name
}


module "rds" {
  source             = "./modules/rds"
  project_name       = var.project_name
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.db_sg.id]
  secret_id          = module.secrets.secret_id
  db_password        = module.secrets.db_password
}

module "alb" {
  source             = "./modules/alb"
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_ids = [aws_security_group.alb_sg.id]
}

module "ec2" {
  source                   = "./modules/ec2"
  project_name             = var.project_name
  environment              = var.environment
  ami_id                   = var.ami_id
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnet_ids
  secret_arns              = [module.secrets.secret_arn]
  app_target_group_arns    = [module.alb.app_target_group_arn]
  ssm_transport_bucket_arn = aws_s3_bucket.ansible_ssm.arn
  instances = {
    "jenkins-server" = {
      instance_type      = "t3.medium"
      name               = "jenkins-server"
      role               = "jenkins"
      security_group_ids = [aws_security_group.jenkins_sg.id]
      ami_id             = "ami-0d2164f0ac41dc4a0"
    }
    "app-server" = {
      instance_type      = "t3.micro"
      name               = "app-server"
      role               = "app"
      security_group_ids = [aws_security_group.app_sg.id]
    }
  }
}

resource "aws_lb_target_group_attachment" "jenkins" {
  target_group_arn = module.alb.jenkins_target_group_arn
  target_id        = module.ec2.instance_ids_map["jenkins-server"]
  port             = 8080
}

output "github_actions_role_arn" {
  value = module.iam.github_actions_role_arn
}
