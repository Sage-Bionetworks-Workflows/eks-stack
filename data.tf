data "aws_eks_cluster" "cluster" {
  depends_on = [module.eks.cluster_id]
  name       = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  depends_on = [module.eks.cluster_id]
  name       = module.eks.cluster_name
}

data "aws_iam_instance_profiles" "profile" {
  depends_on = [module.eks]
  role_name = module.eks.eks_managed_node_groups["one"].iam_role_name
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
