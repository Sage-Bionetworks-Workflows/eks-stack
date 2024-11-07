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

  registry {
    url = "oci://ghcr.io"
    # TODO: Is there a service account we can use instead of my personal account?
    username = "BryanFauble"
    # Requires that a secret be created in spacelift TF_VAR_github_container_repository_token
    password = var.github_container_repository_token
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
