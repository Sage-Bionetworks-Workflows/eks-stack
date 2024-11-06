
locals {
  git_branch = "schematic-138-cold-storage-and-backups"
}

import {
  # The initial administrative stack is created manually in the Spacelift UI, and imported
  # See https://docs.spacelift.io/vendors/terraform/terraform-provider.html#proposed-workflow
  # "We suggest to first manually create a single administrative stack, and then use it 
  # to programmatically define other stacks as necessary."
  to = spacelift_stack.brad-sandbox
  id = "brad-sandbox-administrative-stack"
}

resource "spacelift_stack" "brad-sandbox" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  administrative          = true
  autodeploy              = false
  branch                  = local.git_branch
  description             = "Manages other spacelift resources"
  name                    = "Brad Sandbox Administrative Stack"
  project_root            = "deployments/brad-sandbox"
  terraform_version       = "1.8.5"
  terraform_workflow_tool = "OPEN_TOFU"
  repository              = "eks-stack"
  space_id                = "root"
  additional_project_globs = [
    "modules/*",
    "modules/**/*",
  ]
}

module "brad-sandbox-spacelift" {
  source           = "../spacelift/dpe-k8s"
  parent_space_id  = "development-01J49XEN88DQ8K9MCPPTTEXSKE"
  admin_stack_id   = spacelift_stack.brad-sandbox.id
  spotinst_account = "act-45de6f47"

  aws_integration_id = "01J3R9GX6DC09QV7NV872DDYR3"
  auto_deploy        = false
  auto_prune         = true
  git_branch         = "schematic-138-cold-storage-and-backups"

  space_name = "brad-sandbox"

  k8s_stack_name         = "Brad sandbox Kubernetes Infrastructure"
  k8s_stack_project_root = "deployments/stacks/dpe-k8s"

  k8s_stack_deployments_name         = "Brad sandbox Kubernetes Deployments"
  k8s_stack_deployments_project_root = "deployments/stacks/dpe-k8s-deployments"

  auth0_stack_name         = ""
  auth0_stack_project_root = ""
  auth0_domain             = ""
  auth0_clients            = []

  aws_account_id = "631692904429"
  region         = "us-east-1"

  cluster_name = "brad-k8-sandbox"
  vpc_name     = "brad-sandbox"

  vpc_cidr_block = "10.52.32.0/20"
  # A public subnet is required for each AZ in which the worker nodes are deployed
  public_subnet_cidrs                    = ["10.52.32.0/24", "10.52.33.0/24", "10.52.35.0/24"]
  private_subnet_cidrs_eks_control_plane = ["10.52.34.0/28", "10.52.34.16/28"]
  azs_eks_control_plane                  = ["us-east-1a", "us-east-1b"]

  private_subnet_cidrs_eks_worker_nodes = ["10.52.44.0/22", "10.52.40.0/22", "10.52.36.0/22"]
  azs_eks_worker_nodes                  = ["us-east-1c", "us-east-1b", "us-east-1a"]

  enable_cluster_ingress = false
  enable_otel_ingress    = false
  ssl_hostname           = ""
  auth0_jwks_uri         = ""
  ses_email_identities   = []
  # Defines the email address that will be used as the sender of the email alerts
  smtp_from = ""
}
