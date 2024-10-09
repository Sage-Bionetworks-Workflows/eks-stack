data "aws_secretsmanager_secret" "smtp_password" {
  name = "${var.cluster_name}/alertmanager_smtp_password_temporary_testing"
}

data "aws_secretsmanager_secret_version" "smtp_password" {
  secret_id = data.aws_secretsmanager_secret.smtp_password.id
}
