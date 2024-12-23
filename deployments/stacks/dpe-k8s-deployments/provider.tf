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
