data "aws_eks_cluster" "cluster" {
  depends_on = [module.eks.cluster_id]
  name       = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  depends_on = [module.eks.cluster_id]
  name       = module.eks.cluster_name
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

data "aws_security_group" "vpc" {
  vpc_id = data.aws_vpc.selected.id

  filter {
    name   = "tag:Name"
    values = ["spacelift-created-vpc-default"]
  }

}