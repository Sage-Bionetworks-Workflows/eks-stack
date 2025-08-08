data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

data "aws_secretsmanager_secret" "spotinst_token" {
  name = "spotinst_token"
}

data "aws_secretsmanager_secret_version" "secret_credentials" {
  secret_id = data.aws_secretsmanager_secret.spotinst_token.id
}

# patch
# Discover the cluster version (or let a var override it)
data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

locals {
  k8s_version = coalesce(var.cluster_version, data.aws_eks_cluster.this.version) # e.g., "1.29"
}

# Amazon Linux 2 EKS-optimized AMI via SSM (non-GPU)
data "aws_ssm_parameter" "eks_worker_ami" {
  name = "/aws/service/eks/optimized-ami/${local.k8s_version}/amazon-linux-2/recommended/image_id"
}