resource "spacelift_stack" "external_dpe_k8s_infra_stack" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }
  
  administrative    = false
  autodeploy        = false
  branch            = "main"
  description       = "Manages outside DPE cluster resources"
  name              = "Infrastructure (Outside EKS Cluster) - CLI"
  project_root      = ""
  repository        = "eks-stack"
  terraform_version = "1.5.7"
  space_id          = "dpe-01HY43JT0KWB83XMT89QF3TA72"
}

resource "spacelift_stack" "interal_dpe_k8s_infra_stack" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }
  
  administrative    = false
  autodeploy        = false
  branch            = "main"
  description       = "Manages inside DPE cluster resources"
  name              = "Infrastructure (Inside EKS Cluster) - CLI"
  project_root      = "modules/internal-k8-infra"
  repository        = "eks-stack"
  terraform_version = "1.5.7"
  space_id          = "dpe-01HY43JT0KWB83XMT89QF3TA72"
}