module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
}

data "github_ip_ranges" "hooks" {}

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
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = concat(var.allowed_ips, [for ip in data.github_ip_ranges.hooks.hooks : ip if !strcontains(ip, ":")])
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
  secret_name  = "${var.project_name}-db-secrets"
  project_name = var.project_name
}


module "rds" {
  source             = "./modules/rds"
  project_name       = var.project_name
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.db_sg.id]
  secret_id          = module.secrets.secret_id
}

module "alb" {
  source             = "./modules/alb"
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  security_group_ids = [aws_security_group.alb_sg.id]
}

module "ec2" {
  source                = "./modules/ec2"
  project_name          = var.project_name
  environment           = var.environment
  ami_id                = var.ami_id
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  secret_arns           = [module.secrets.secret_arn]
  app_target_group_arns = [module.alb.app_target_group_arn]
  instances = {
    "jenkins-server" = {
      instance_type      = "t3.medium"
      name               = "jenkins-server"
      role               = "jenkins"
      security_group_ids = [aws_security_group.jenkins_sg.id]
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
