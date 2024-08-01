module "sage-aws-vpc" {
  source   = "spacelift.io/sagebionetworks/sage-aws-vpc/aws"
  version  = "0.3.4"
  vpc_name = var.vpc_name
  # TODO: Per https://sagebionetworks.jira.com/browse/IT-3824
  # We will soon not have to capture the VPC flow logs outself as every account with a VPC will have them enabled by default
  capture_flow_logs    = true
  flow_log_retention   = 90
  vpc_cidr_block       = var.vpc_cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
  region               = var.region
}

module "sage-aws-eks" {
  source  = "spacelift.io/sagebionetworks/sage-aws-eks/aws"
  version = "0.4.0"

  cluster_name                      = var.cluster_name
  private_vpc_subnet_ids            = module.sage-aws-vpc.private_subnet_ids
  vpc_id                            = module.sage-aws-vpc.vpc_id
  vpc_security_group_id             = module.sage-aws-vpc.vpc_security_group_id
  enable_policy_event_logs          = true
  capture_cloudwatch_logs           = true
  cloudwatch_retention              = 90
  pod_security_group_enforcing_mode = var.pod_security_group_enforcing_mode
  aws_account_id                    = var.aws_account_id
  private_subnet_cidrs              = module.sage-aws-vpc.vpc_private_subnet_cidrs
}
