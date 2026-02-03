resource "random_password" "db_password" {
  length           = 16
  special          = false
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name_prefix             = "${var.secret_name}-" # used name prefix instead of name to avoid name scheduled for deletion conflict 
  description             = "Database credentials for the voting app"
  recovery_window_in_days = 0 # Added recovery window to allow for immediate reuse of secret

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
