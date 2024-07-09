resource "spacelift_space" "dpe-sandbox" {
  name            = "dpe-sandbox"
  parent_space_id = var.parent_space_id
  description     = "Contains resources for the DPE team for sandbox testing."
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
  project_root            = "environments/dev/dpe-sandbox-k8s"
  repository              = "eks-stack"
  terraform_version       = "1.7.3"
  terraform_workflow_tool = "OPEN_TOFU"
  space_id                = spacelift_space.dpe-sandbox.id
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
  project_root            = "environments/dev/dpe-sandbox-k8s-deployments"
  repository              = "eks-stack"
  terraform_version       = "1.7.3"
  terraform_workflow_tool = "OPEN_TOFU"
  space_id                = spacelift_space.dpe-sandbox.id
}


resource "spacelift_policy_attachment" "policy-attachment" {
  policy_id = each.value.policy_id
  stack_id  = spacelift_stack.k8s_stack.id
}

resource "spacelift_stack_destructor" "k8s-stack-deployments-destructor" {
  depends_on = [
    spacelift_stack.k8s-stack,
  ]

  stack_id = spacelift_stack.k8s-stack-deployments.id
}

resource "spacelift_stack_destructor" "k8s-stack-destructor" {
  stack_id = spacelift_stack.k8s-stack.id
}
