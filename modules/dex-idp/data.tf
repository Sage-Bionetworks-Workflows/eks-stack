data "aws_secretsmanager_secret" "oauth-client-id" {
  name = "dev/dpe-sandbox/client-id"
}

data "aws_secretsmanager_secret_version" "client-id" {
  secret_id = data.aws_secretsmanager_secret.oauth-client-id.id
}

data "aws_secretsmanager_secret" "oauth-client-secret" {
  name = "dev/dpe-sandbox/client-secret"
}

data "aws_secretsmanager_secret_version" "client-secret" {
  secret_id = data.aws_secretsmanager_secret.oauth-client-secret.id
}