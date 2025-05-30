# After infra is imported it can be commented out or removed. Keeping it here for reference.

# import {
#   # The initial administrative stack is created manually in the Spacelift UI, and imported
#   # See https://docs.spacelift.io/vendors/terraform/terraform-provider.html#proposed-workflow
#   # "We suggest to first manually create a single administrative stack, and then use it 
#   # to programmatically define other stacks as necessary."
#   to = spacelift_stack.root_administrative_stack
#   id = "root-spacelift-administrative-stack"
# }

locals {
  git_branch = "main"
}

resource "spacelift_stack" "root_administrative_stack" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  administrative          = true
  autodeploy              = false
  branch                  = local.git_branch
  description             = "Manages other spacelift resources"
  name                    = "Root Spacelift Administrative Stack"
  project_root            = ""
  terraform_version       = "1.8.6"
  terraform_workflow_tool = "OPEN_TOFU"
  repository              = "eks-stack"
  space_id                = "root"
  additional_project_globs = [
    "modules/*",
    "modules/**/*",
  ]
}

resource "spacelift_space" "environment" {
  name             = "environment"
  parent_space_id  = "root"
  description      = "Contains all the resources to deploy out to each enviornment."
  inherit_entities = true
}

module "terraform-registry" {
  source     = "./modules"
  depends_on = [spacelift_stack.root_administrative_stack]
  git_branch = local.git_branch
}

module "common" {
  source     = "./common-resources"
  depends_on = [spacelift_stack.root_administrative_stack]
}

module "deployments" {
  source = "./deployments"
  depends_on = [
    spacelift_stack.root_administrative_stack,
    module.common,
    module.terraform-registry,
  ]
  parent_space_id                          = spacelift_space.environment.id
  admin_stack_id                           = spacelift_stack.root_administrative_stack.id
  org_sagebase_dnt_dev_aws_integration_id  = module.common.org_sagebase_dnt_dev_aws_integration_id
  org_sagebase_dpe_prod_aws_integration_id = module.common.org_sagebase_dpe_prod_aws_integration_id
  git_branch                               = local.git_branch
}
