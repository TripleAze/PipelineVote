data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = var.secret_id
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "main" {
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = var.db_instance_class
  db_name                = local.db_creds.db_name
  username               = local.db_creds.username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  skip_final_snapshot    = true
  final_snapshot_identifier = "${var.project_name}-final-snapshot"
  publicly_accessible    = false
  storage_encrypted      = true
  backup_retention_period = 4

  tags = {
    Name = "${var.project_name}-db"
  }
}
