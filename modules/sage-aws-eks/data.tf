data "aws_eks_cluster" "cluster" {
  depends_on = [module.eks.cluster_id]
  name       = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  depends_on = [module.eks.cluster_id]
  name       = module.eks.cluster_name
}
