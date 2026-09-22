locals {
  mwaa_stack_variables = {
    enabled              = var.enabled
    name                 = var.mwaa_name
    region               = var.region
    vpc_name             = var.vpc_name
    vpc_cidr_block       = var.vpc_cidr_block
    azs                  = var.azs
    private_subnet_cidrs = var.private_subnet_cidrs
    public_subnet_cidrs  = var.public_subnet_cidrs
  }
}

resource "spacelift_space" "mwaa-space" {
  name             = var.space_name
  parent_space_id  = var.parent_space_id
  description      = "Contains the managed Airflow resources for the DPE team."
  inherit_entities = true
}

resource "spacelift_stack" "mwaa-stack" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  depends_on = [
    spacelift_space.mwaa-space
  ]

  administrative          = false
  autodeploy              = var.auto_deploy
  branch                  = var.git_branch
  description             = "Creates an Amazon MWAA (Managed Airflow) environment"
  name                    = var.mwaa_stack_name
  project_root            = var.mwaa_stack_project_root
  repository              = "eks-stack"
  terraform_version       = var.opentofu_version
  terraform_workflow_tool = "OPEN_TOFU"
  space_id                = spacelift_space.mwaa-space.id
}

resource "spacelift_environment_variable" "mwaa-stack-environment-variables" {
  for_each = local.mwaa_stack_variables

  stack_id   = spacelift_stack.mwaa-stack.id
  name       = "TF_VAR_${each.key}"
  value      = try(tostring(each.value), jsonencode(each.value))
  write_only = false
}

resource "spacelift_aws_integration_attachment" "mwaa-aws-integration-attachment" {
  integration_id = var.aws_integration_id
  stack_id       = spacelift_stack.mwaa-stack.id
  read           = true
  write          = true
}
