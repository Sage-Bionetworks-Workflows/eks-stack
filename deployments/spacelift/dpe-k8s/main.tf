locals {
  k8s_stack_environment_variables = {
    aws_account_id                    = var.aws_account_id
    region                            = var.region
    pod_security_group_enforcing_mode = var.pod_security_group_enforcing_mode
    cluster_name                      = var.cluster_name
    vpc_name                          = var.vpc_name
    vpc_cidr_block                    = var.vpc_cidr_block
    public_subnet_cidrs               = var.public_subnet_cidrs
    private_subnet_cidrs              = var.private_subnet_cidrs
  }
}

resource "spacelift_space" "dpe-space" {
  name             = var.space_name
  parent_space_id  = var.parent_space_id
  description      = "Contains resources for the DPE team."
  inherit_entities = true
}

resource "spacelift_stack" "k8s-stack" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  administrative          = false
  autodeploy              = var.auto_deploy
  branch                  = var.git_branch
  description             = "Infrastructure to support deploying to an EKS cluster"
  name                    = var.k8s_stack_name
  project_root            = var.k8s_stack_project_root
  repository              = "eks-stack"
  terraform_version       = var.opentofu_version
  terraform_workflow_tool = "OPEN_TOFU"
  space_id                = spacelift_space.dpe-space.id
}

resource "spacelift_environment_variable" "k8s-stack-environment-variables" {
  for_each = [k8s_stack_environment_variables]

  stack_id   = spacelift_stack.k8s-stack.id
  name       = each.key
  value      = "TF_VAR_${each.value}"
  write_only = false
}

resource "spacelift_stack" "k8s-stack-deployments" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  administrative          = false
  autodeploy              = var.auto_deploy
  branch                  = var.git_branch
  description             = "Deployments internal to an EKS cluster"
  name                    = var.k8s_stack_deployments_name
  project_root            = var.k8s_stack_deployments_project_root
  repository              = "eks-stack"
  terraform_version       = var.opentofu_version
  terraform_workflow_tool = "OPEN_TOFU"
  space_id                = spacelift_space.dpe-space.id
}

resource "spacelift_environment_variable" "k8s-stack-deployments-environment-variables" {
  for_each = [var.aws_account_id, var.region, var.pod_security_group_enforcing_mode, var.cluster_name, var.vpc_name]

  stack_id   = spacelift_stack.k8s-stack-deployments.id
  name       = each.key
  value      = "TF_VAR_${each.value}"
  write_only = false
}


# TODO: There is some work here that is needed:
# 1) When we increment a module the admin stack needs to run and create the new resources/modules in spacelift
# 2) We need any stacks that are using that new resource/module then need to run
# The problem:
# When this dependent stack is run it might be "Skipped" because the admin stack does not have different values in the `output.tf` that is used here
# That means the child stack is never run.

# resource "spacelift_stack_dependency" "dependency-on-admin-stack" {
#   for_each = {
#     k8s-stack             = spacelift_stack.k8s-stack,
#     k8s-stack-deployments = spacelift_stack.k8s-stack-deployments
#   }

#   stack_id            = each.value.id
#   depends_on_stack_id = var.admin_stack_id
# }

resource "spacelift_context_attachment" "k8s-kubeconfig-hooks" {
  context_id = "kubernetes-deployments-kubeconfig"
  stack_id   = spacelift_stack.k8s-stack-deployments.id
}

resource "spacelift_stack_dependency" "k8s-stack-to-deployments" {
  stack_id            = spacelift_stack.k8s-stack-deployments.id
  depends_on_stack_id = spacelift_stack.k8s-stack.id
}

resource "spacelift_stack_dependency_reference" "vpc-id-reference" {
  stack_dependency_id = spacelift_stack_dependency.k8s-stack-to-deployments.id
  output_name         = "vpc_id"
  input_name          = "TF_VAR_vpc_id"
}

resource "spacelift_stack_dependency_reference" "private-subnet-ids-reference" {
  stack_dependency_id = spacelift_stack_dependency.k8s-stack-to-deployments.id
  output_name         = "private_subnet_ids"
  input_name          = "TF_VAR_private_subnet_ids"
}

resource "spacelift_stack_dependency_reference" "security-group-id-reference" {
  stack_dependency_id = spacelift_stack_dependency.k8s-stack-to-deployments.id
  output_name         = "node_security_group_id"
  input_name          = "TF_VAR_node_security_group_id"
}

resource "spacelift_stack_dependency_reference" "pod-to-node-security-group-id-reference" {
  stack_dependency_id = spacelift_stack_dependency.k8s-stack-to-deployments.id
  output_name         = "pod_to_node_dns_sg_id"
  input_name          = "TF_VAR_pod_to_node_dns_sg_id"
}

resource "spacelift_stack_dependency_reference" "vpc-cidr-block-reference" {
  stack_dependency_id = spacelift_stack_dependency.k8s-stack-to-deployments.id
  output_name         = "vpc_cidr_block"
  input_name          = "TF_VAR_vpc_cidr_block"
}

resource "spacelift_stack_dependency_reference" "region-name" {
  stack_dependency_id = spacelift_stack_dependency.k8s-stack-to-deployments.id
  output_name         = "region"
  input_name          = "REGION"
}

resource "spacelift_stack_dependency_reference" "cluster-name" {
  stack_dependency_id = spacelift_stack_dependency.k8s-stack-to-deployments.id
  output_name         = "cluster_name"
  input_name          = "CLUSTER_NAME"
}

resource "spacelift_stack_dependency_reference" "cluster-name-tfvar" {
  stack_dependency_id = spacelift_stack_dependency.k8s-stack-to-deployments.id
  output_name         = "cluster_name"
  input_name          = "TF_VAR_cluster_name"
}

# resource "spacelift_policy_attachment" "policy-attachment" {
#   policy_id = each.value.policy_id
#   stack_id  = spacelift_stack.k8s-stack.id
# }

resource "spacelift_stack_destructor" "k8s-stack-deployments-destructor" {
  depends_on = [
    spacelift_stack.k8s-stack,
  ]

  stack_id = spacelift_stack.k8s-stack-deployments.id
}

resource "spacelift_stack_destructor" "k8s-stack-destructor" {
  stack_id = spacelift_stack.k8s-stack.id
}

resource "spacelift_aws_integration_attachment" "k8s-aws-integration-attachment" {
  integration_id = var.aws_integration_id
  stack_id       = spacelift_stack.k8s-stack.id
  read           = true
  write          = true
}

resource "spacelift_aws_integration_attachment" "k8s-deployments-aws-integration-attachment" {

  integration_id = var.aws_integration_id
  stack_id       = spacelift_stack.k8s-stack-deployments.id
  read           = true
  write          = true
}
