module "sage-aws-eks-autoscaler" {
  source  = "spacelift.io/sagebionetworks/sage-aws-eks-autoscaler/aws"
  version = "0.1.0"

  cluster_name           = "dpe-k8-sandbox"
  private_vpc_subnet_ids = var.private_subnet_ids
  vpc_id                 = var.vpc_id
  vpc_security_group_id  = var.security_group_id
}
