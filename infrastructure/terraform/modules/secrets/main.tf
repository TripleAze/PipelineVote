resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "_%@!"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = var.secret_name
  description = "Database credentials for the voting app"

  tags = {
    Project = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_password.result
    engine   = "mysql"
    db_name  = "votingdb"
  })
}
