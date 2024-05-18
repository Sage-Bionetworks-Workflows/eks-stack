data "aws_eks_cluster" "cluster" {
  name = "dpe-k8"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "dpe-k8"
}

data "aws_secretsmanager_secret" "spotinst_token" {
  name = "spotinst_token"
}

data "aws_secretsmanager_secret_version" "secret_credentials" {
  secret_id = data.aws_secretsmanager_secret.spotinst_token.id
}
