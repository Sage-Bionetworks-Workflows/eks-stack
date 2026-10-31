# Every value this stack deploys, by deployment_environment. The bucket list is in
# deployments/config, because the MWAA stack grants access to the same buckets
locals {
  environments = {
    # DNT dev account
    dev = {
      aws_account_id = "631692904429"
      region         = "us-east-1"
      import_buckets = []
    }

    # DPE prod account
    prod = {
      aws_account_id = "766808016710"
      region         = "us-east-1"
      # Created by the dpe-k8s production stack, which forgets them (removed blocks in
      # deployments/stacks/dpe-k8s/main.tf). Empty this list and remove those blocks once both
      # stacks have applied
      import_buckets = ["synapse-croissant-metadata", "synapse-croissant-metadata-minimal"]
    }
  }

  env     = local.environments[var.deployment_environment]
  buckets = module.config.dag_buckets[var.deployment_environment]
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
