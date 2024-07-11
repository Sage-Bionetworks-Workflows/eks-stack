import {
  # The initial administrative stack is created manually in the Spacelift UI, and imported
  to = spacelift_stack.root_administrative_stack
  id = "root-spacelift-administrative-stack"
}
resource "spacelift_stack" "root_administrative_stack" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  administrative          = true
  autodeploy              = true
  branch                  = "ibcdpe-935-vpc-updates"
  description             = "Manages other spacelift resources"
  name                    = "Root Spacelift Administrative Stack"
  project_root            = ""
  terraform_version       = "1.7.2"
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
}

module "common" {
  source     = "./common-resources"
  depends_on = [spacelift_stack.root_administrative_stack]
}

module "dev-resources" {
  source = "./dev"
  depends_on = [
    spacelift_stack.root_administrative_stack,
    module.common,
    module.terraform-registry,
  ]
  parent_space_id = spacelift_space.environment.id
}