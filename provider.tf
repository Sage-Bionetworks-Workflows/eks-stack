provider "aws" {
  region = local.region
}

provider "spotinst" {
  account = local.spotinst_account
  token   = data.aws_secretsmanager_secret_version.secret_credentials.secret_string
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
