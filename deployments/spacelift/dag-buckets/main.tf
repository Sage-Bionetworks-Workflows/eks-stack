locals {
  # Inputs for deployments/stacks/dag-buckets. Each is set on the stack as TF_VAR_<key>
  stack_variables = {
    region         = var.region
    buckets        = var.buckets
    import_buckets = var.import_buckets
  }
}

# Runs the Terraform code in project_root, from the tracked branch of this repo
resource "spacelift_stack" "dag-buckets-stack" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  administrative          = false
  autodeploy              = var.auto_deploy
  branch                  = var.git_branch
  description             = "Creates the S3 buckets that the orca-recipes DAGs write to"
  name                    = var.stack_name
  project_root            = var.stack_project_root
  repository              = "eks-stack"
  terraform_version       = var.opentofu_version
  terraform_workflow_tool = "OPEN_TOFU"
  space_id                = var.space_id
}

# Passes stack_variables to the stack. Maps and lists are JSON encoded, which Terraform
# parses back
resource "spacelift_environment_variable" "dag-buckets-stack-environment-variables" {
  for_each = local.stack_variables

  stack_id   = spacelift_stack.dag-buckets-stack.id
  name       = "TF_VAR_${each.key}"
  value      = try(tostring(each.value), jsonencode(each.value))
  write_only = false
}

# Gives the stack read and write credentials for the AWS account it deploys to
resource "spacelift_aws_integration_attachment" "dag-buckets-aws-integration-attachment" {
  integration_id = var.aws_integration_id
  stack_id       = spacelift_stack.dag-buckets-stack.id
  read           = true
  write          = true
}
