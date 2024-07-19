module "sage-aws-vpc" {
  source             = "spacelift.io/sagebionetworks/sage-aws-vpc/aws"
  version            = "0.3.1"
  vpc_name           = "dpe-sandbox"
  capture_flow_logs  = true
  flow_log_retention = 1
}

module "sage-aws-eks" {
  source  = "spacelift.io/sagebionetworks/sage-aws-eks/aws"
  version = "0.3.1"

  cluster_name             = "dpe-k8-sandbox"
  private_vpc_subnet_ids   = module.sage-aws-vpc.private_subnet_ids
  vpc_id                   = module.sage-aws-vpc.vpc_id
  vpc_security_group_id    = module.sage-aws-vpc.vpc_security_group_id
  enable_policy_event_logs = true
  capture_cloudwatch_logs  = true
  cloudwatch_retention     = 1
}
