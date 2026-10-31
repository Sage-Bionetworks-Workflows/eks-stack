# Every value this stack deploys, by deployment_environment. A change here shows up in the
# proposed run of the stack it changes
locals {
  # orca-recipes commit whose requirements-airflow.txt and mwaa/constraints.txt are installed
  # on MWAA. Shared by dev and prod so they cannot diverge. To bump it, follow
  # https://github.com/Sage-Bionetworks-Workflows/orca-recipes/blob/main/mwaa/README.md#changing-dependencies
  # https://github.com/Sage-Bionetworks-Workflows/orca-recipes/commit/0d6af01fa58ebd396b0d47c1234a75d2384bf47c
  orca_recipes_sha = "0d6af01fa58ebd396b0d47c1234a75d2384bf47c"

  environments = {
    # DNT dev account
    dev = {
      aws_account_id = "631692904429"
      region         = "us-east-1"

      # Prefix of the VPC's CloudFormation exports, which organizations-infra 710-tgw looks up by name
      vpc_name = "mwaa-dev"
      # Must be unique across the Sage AWS organization so the Transit Gateway can route to it.
      # Picked with IPAM as described in https://sagebionetworks.jira.com/wiki/spaces/IT/pages/2850586648/Setup+AWS+VPC
      # Changing it replaces the VPC and the MWAA environment
      vpc_cidr_block = "10.52.48.0/22"
      azs            = ["us-east-1a", "us-east-1b"]
      # MWAA requires exactly two private subnets, one per AZ. The public subnets carry the NAT gateway
      private_subnet_cidrs = ["10.52.48.0/24", "10.52.49.0/24"]
      public_subnet_cidrs  = ["10.52.50.0/24", "10.52.51.0/24"]

      # No AWS resources are created until this is true
      enabled = true
      # The globally unique S3 bucket name is derived from this: <name>-s3
      name = "synapse-mwaa-dev"
      # AWS MWAA-supported Airflow version (Python 3.12).
      airflow_version = "3.3.1"
    }

    # DPE prod account
    prod = {
      aws_account_id = "766808016710"
      region         = "us-east-1"

      vpc_name = "mwaa-prod"
      # Must be unique across the Sage AWS organization so the Transit Gateway can route to it.
      # Picked with IPAM as described in https://sagebionetworks.jira.com/wiki/spaces/IT/pages/2850586648/Setup+AWS+VPC
      # Changing it replaces the VPC and the MWAA environment
      vpc_cidr_block = "10.52.52.0/22"
      azs            = ["us-east-1a", "us-east-1b"]
      # MWAA requires exactly two private subnets, one per AZ. The public subnets carry the NAT gateway
      private_subnet_cidrs = ["10.52.52.0/24", "10.52.53.0/24"]
      public_subnet_cidrs  = ["10.52.54.0/24", "10.52.55.0/24"]

      # No AWS resources are created until this is true. Prod stays disabled until the
      # organizations-infra PR that adds this VPC to the Transit Gateway is merged and applied,
      # and prod is ready to go live; see DPE-1836 rollout notes.
      enabled = false
      # The globally unique S3 bucket name is derived from this: <name>-s3
      name = "synapse-mwaa-prod"
      # AWS MWAA-supported Airflow version (Python 3.12).
      airflow_version = "3.3.1"
    }
  }

  env = local.environments[var.deployment_environment]
}

module "config" {
  source = "../../config"
}

# The admin stack sets deployment_environment and the AWS account separately. Fail the plan
# if they disagree
data "aws_caller_identity" "current" {
  lifecycle {
    postcondition {
      condition     = self.account_id == local.env.aws_account_id
      error_message = "deployment_environment ${var.deployment_environment} deploys to account ${local.env.aws_account_id}, but the stack's AWS integration is for account ${self.account_id}"
    }
  }
}
