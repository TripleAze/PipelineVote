module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
}


# --- S3 Bucket ---

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
    cidr_blocks      = var.allowed_ips
    ipv6_cidr_blocks = []
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

resource "aws_ssm_parameter" "db_secret_id" {
  name        = "/${var.project_name}/db_secret_id"
  description = "RDS database secrets ID"
  type        = "String"
  value       = module.secrets.secret_id
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
  depends_on         = [module.secrets]
}

module "alb" {
  source               = "./modules/alb"
  project_name         = var.project_name
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  security_group_ids   = [aws_security_group.alb_sg.id]
  certificate_arn      = module.acm.certificate_arn
  cloudflare_zone_id   = var.cloudflare_zone_id
  cloudflare_api_token = var.cloudflare_api_token
}

module "acm" {
  source               = "./modules/acm"
  project_name         = var.project_name
  domain_name          = var.domain_name
  cloudflare_zone_id   = var.cloudflare_zone_id
  cloudflare_api_token = var.cloudflare_api_token
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
      instance_type          = "t3.large"
      name                   = "jenkins-server"
      role                   = "jenkins"
      security_group_ids     = [aws_security_group.jenkins_sg.id]
      ami_id                 = "ami-0d2164f0ac41dc4a0"
      root_block_device_size = 40
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
