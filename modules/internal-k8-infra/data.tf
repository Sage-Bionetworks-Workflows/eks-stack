data "aws_eks_cluster" "cluster" {
  name = "dpe-k8"
}

data "aws_eks_cluster_auth" "cluster" {
  name = "dpe-k8"
}

data "aws_security_group" "node" {
  id = tolist(data.aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id)[0]
}

data "aws_iam_instance_profiles" "profile" {
  depends_on = [module.eks]
  role_name  = module.eks.eks_managed_node_groups["one"].iam_role_name
}

data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["spacelift-created-vpc"]
  }
}

data "aws_subnet" "private" {
  vpc_id = data.aws_vpc.selected.id

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

# data "aws_iam_instance_profiles" "profile2" {
#   depends_on = [module.eks]
#   role_name = module.eks.eks_managed_node_groups["two"].iam_role_name
# }

data "aws_secretsmanager_secret" "spotinst_token" {
  name = "spotinst_token"
}

data "aws_secretsmanager_secret_version" "secret_credentials" {
  secret_id = data.aws_secretsmanager_secret.spotinst_token.id
}


