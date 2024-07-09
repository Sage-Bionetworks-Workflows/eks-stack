module "sage-aws-vpc" {
  source   = "spacelift.io/sagebionetworks/sage-aws-vpc/aws"
  version  = "0.2.0"
  vpc_name = "dpe-sandbox"
}

module "sage-aws-eks" {
  source  = "spacelift.io/sagebionetworks/sage-aws-eks/aws"
  version = "0.2.0"

  cluster_name           = "dpe-k8-sandbox"
  private_vpc_subnet_ids = module.sage-aws-vpc.private_subnet_ids
  vpc_id                 = module.sage-aws-vpc.vpc_id
  vpc_security_group_id  = module.sage-aws-vpc.security_group_id

}
