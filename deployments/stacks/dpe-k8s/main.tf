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

module "sage-aws-ses" {
  count  = length(var.ses_email_identities) > 0 ? 1 : 0
  source = "../../../modules/sage-aws-ses"

  email_identities = var.ses_email_identities
}

module "synapse_dataset_to_crossiant_metadata" {
  # This points to the prod cluster - The only location where we want to create the bucket
  count  = var.cluster_name == "dpe-k8" ? 1 : 0
  source      = "../../../modules/s3-bucket"
  bucket_name = "synapse-croissant-metadata"
  enable_versioning = true
  aws_account_id = var.aws_account_id
  cluster_name = var.cluster_name
  cluster_oidc_provider_arn = module.sage-aws-eks.cluster_oidc_provider_arn
  public_access = true
  enable_cors = true
}

