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

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["spacelift-created-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = ["private"]
  }
}

data "aws_security_group" "eks_node_security_group" {
  tags = {
    Name = "${var.cluster_name}-node"
  }
}

data "kubernetes_storage_class" "existing" {
  metadata {
    name = "gp3"
  }
}