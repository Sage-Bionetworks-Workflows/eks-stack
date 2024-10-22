provider "aws" {
  region = var.region
}

provider "kubernetes" {
  config_path            = var.kube_config_path
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    config_path = var.kube_config_path
  }
}

provider "spotinst" {
  account = var.spotinst_account
  token   = data.aws_secretsmanager_secret_version.secret_credentials.secret_string
}

provider "kubectl" {
  config_path            = var.kube_config_path
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Requires manually setting id and secret in the stack environment variables in the Spacelift UI
# TF_VAR_auth0_client_id
# TF_VAR_auth0_client_secret
# TF_VAR_auth0_domain
provider "auth0" {
  domain        = var.auth0_domain
  client_id     = var.auth0_client_id
  client_secret = var.auth0_client_secret
}