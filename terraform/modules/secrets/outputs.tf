output "secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "secret_id" {
  value = aws_secretsmanager_secret.db_credentials.id
}
