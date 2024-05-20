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

# TODO: This should search for the VPC using some other value as ID would change
# on first startup and teardown/restart
data "aws_subnets" "node_subnets" {
  filter {
    name   = "vpc-id"
    values = ["vpc-0f30cfca319ebc521"]
  }
}

data "aws_eks_node_group" "profile" {
  cluster_name    = var.cluster_name
  node_group_name = "airflow-node-group"
}

data "aws_security_group" "eks_cluster_security_group" {
  tags = {
    Name = "${var.cluster_name}-node"
  }
}
