module "kubernetes-controller" {
  source  = "spotinst/kubernetes-controller/ocean"
  version = "0.0.2"

  # Credentials
  spotinst_token   = data.aws_secretsmanager_secret_version.secret_credentials.secret_string
  spotinst_account = var.spotinst_account

  # Configuration
  cluster_identifier = var.cluster_name
}

