data "aws_eks_cluster" "cluster" {
  depends_on = [module.eks.cluster_id]
  name       = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  depends_on = [module.eks.cluster_id]
  name       = module.eks.cluster_name
}

data "aws_iam_roles" "developer-roles" {
  name_regex  = "AWSReservedSSO_Developer_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "administrator-roles" {
  name_regex  = "AWSReservedSSO_Administrator_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
