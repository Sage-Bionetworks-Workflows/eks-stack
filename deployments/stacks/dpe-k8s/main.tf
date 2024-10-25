module "sage-aws-vpc" {
  # source   = "spacelift.io/sagebionetworks/sage-aws-vpc/aws"
  # version  = "0.4.2"
  source   = "../../../modules/sage-aws-vpc"
  vpc_name = var.vpc_name
  # TODO: Per https://sagebionetworks.jira.com/browse/IT-3824
  # We will soon not have to capture the VPC flow logs outself as every account with a VPC will have them enabled by default
  capture_flow_logs                      = true
  flow_log_retention                     = 90
  vpc_cidr_block                         = var.vpc_cidr_block
  public_subnet_cidrs                    = var.public_subnet_cidrs
  private_subnet_cidrs_eks_control_plane = var.private_subnet_cidrs_eks_control_plane
  private_subnet_cidrs_eks_worker_nodes  = var.private_subnet_cidrs_eks_worker_nodes
  azs_eks_control_plane                  = var.azs_eks_control_plane
  azs_eks_worker_nodes                   = var.azs_eks_worker_nodes
  region                                 = var.region
}

module "sage-aws-eks" {
  # source  = "spacelift.io/sagebionetworks/sage-aws-eks/aws"
  # version = "0.6.0"
  source = "../../../modules/sage-aws-eks"

  cluster_name                      = var.cluster_name
  vpc_id                            = module.sage-aws-vpc.vpc_id
  vpc_security_group_id             = module.sage-aws-vpc.vpc_security_group_id
  enable_policy_event_logs          = true
  capture_cloudwatch_logs           = true
  cloudwatch_retention              = 90
  pod_security_group_enforcing_mode = var.pod_security_group_enforcing_mode
  aws_account_id                    = var.aws_account_id
  private_subnet_cidrs = concat(
    var.private_subnet_cidrs_eks_control_plane,
    var.private_subnet_cidrs_eks_worker_nodes
  )
  private_subnet_ids_eks_control_plane = module.sage-aws-vpc.private_subnet_ids_eks_control_plane
  private_subnet_ids_eks_worker_nodes  = module.sage-aws-vpc.private_subnet_ids_eks_worker_nodes
}

import {
  to = module.sage-aws-ses.aws_ses_email_identity.identities[0]
  id = "aws-dpe-dev@sagebase.org"
}

import {
  to = module.sage-aws-ses.aws_ses_email_identity.identities[1]
  id = "bryan.fauble@sagebase.org"
}

import {
  to = module.sage-aws-ses.aws_ses_domain_identity.identities[0]
  id = "sagebase.org"
}

module "sage-aws-ses" {
  source = "../../../modules/sage-aws-ses"

  email_identities = var.ses_email_identities
  email_domains    = var.ses_email_domains
  tags             = var.tags
}