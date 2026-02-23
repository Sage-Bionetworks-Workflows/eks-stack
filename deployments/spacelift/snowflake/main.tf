locals {
  snowflake_stack_variables = {
    aws_account_id           = var.aws_account_id
    region                   = var.region
    bucket_name              = var.snowflake_bucket_name
    source_account_id        = var.source_account_id
    source_bucket_arn        = var.source_bucket_arn
    snowflake_principal_arn  = var.snowflake_principal_arn
    snowflake_external_id    = var.snowflake_external_id
  }
}

# TODO: This resource is being created for each Spacelift config. Abstraction warranted?
resource "spacelift_space" "dpe-space" {
  name             = var.space_name
  parent_space_id  = var.parent_space_id
  description      = "Contains resources for the DPE team."
  inherit_entities = true
}

resource "spacelift_stack" "snowflake-stack" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  depends_on = [
    spacelift_space.dpe-space
  ]

  administrative          = false
  autodeploy              = var.auto_deploy
  branch                  = var.git_branch
  description             = "Creates an S3 bucket for Synapse RDS data to be copied into"
  name                    = var.snowflake_stack_name
  project_root            = var.snowflake_stack_project_root
  repository              = "eks-stack"
  terraform_version       = var.opentofu_version
  terraform_workflow_tool = "OPEN_TOFU"
  space_id                = spacelift_space.dpe-space.id
}

resource "spacelift_environment_variable" "snowflake-stack-environment-variables" {
  for_each = local.snowflake_stack_variables

  stack_id   = spacelift_stack.snowflake-stack.id
  name       = "TF_VAR_${each.key}"
  value      = try(tostring(each.value), jsonencode(each.value))
  write_only = false
}

resource "spacelift_aws_integration_attachment" "snowflake-aws-integration-attachment" {
  integration_id = var.aws_integration_id
  stack_id       = spacelift_stack.snowflake-stack.id
  read           = true
  write          = true
}
