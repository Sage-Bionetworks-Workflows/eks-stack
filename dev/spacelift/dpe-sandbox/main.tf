resource "spacelift_space" "dpe-sandbox" {
  name             = "dpe-sandbox"
  parent_space_id  = var.parent_space_id
  description      = "Contains resources for the DPE team for sandbox testing."
  inherit_entities = true
}

resource "spacelift_stack" "k8s-stack" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  administrative          = false
  autodeploy              = true
  branch                  = "ibcdpe-935-vpc-updates"
  description             = "Infrastructure to support deploying to an EKS cluster"
  name                    = "DPE DEV Kubernetes Infrastructure"
  project_root            = "dev/stacks/dpe-sandbox-k8s"
  repository              = "eks-stack"
  terraform_version       = "1.7.2"
  terraform_workflow_tool = "OPEN_TOFU"
  space_id                = spacelift_space.dpe-sandbox.id
  worker_pool_id          = "01J33GHR11YSYAEN433PKXBGGK"
}

resource "spacelift_stack" "k8s-stack-deployments" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  administrative          = false
  autodeploy              = true
  branch                  = "ibcdpe-935-vpc-updates"
  description             = "Deployments internal to an EKS cluster"
  name                    = "DPE DEV Kubernetes Deployments"
  project_root            = "dev/stacks/dpe-sandbox-k8s-deployments"
  repository              = "eks-stack"
  terraform_version       = "1.7.2"
  terraform_workflow_tool = "OPEN_TOFU"
  space_id                = spacelift_space.dpe-sandbox.id
  worker_pool_id          = "01J33GHR11YSYAEN433PKXBGGK"
}

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
  integration_id = "01HXW154N60KJ8NCC93H1VYPNM"
  stack_id       = spacelift_stack.k8s-stack.id
  read           = true
  write          = true
}

resource "spacelift_aws_integration_attachment" "k8s-deployments-aws-integration-attachment" {
  integration_id = "01HXW154N60KJ8NCC93H1VYPNM"
  stack_id       = spacelift_stack.k8s-stack-deployments.id
  read           = true
  write          = true
}
