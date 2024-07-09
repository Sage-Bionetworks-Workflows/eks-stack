resource "spacelift_module" "sage-aws-vpc" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  name               = "sage-aws-vpc"
  terraform_provider = "aws"
  administrative     = false
  branch             = "ibcdpe-935-vpc-updates"
  description        = "Terraform module for creating a VPC in AWS"
  repository         = "eks-stack"
  project_root       = "modules/sage-aws-vpc"
  space_id           = "root"
}

resource "spacelift_module" "sage-aws-eks" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  name               = "sage-aws-eks"
  terraform_provider = "aws"
  administrative     = false
  branch             = "ibcdpe-935-vpc-updates"
  description        = "Terraform module for creating an EKS cluster in AWS"
  repository         = "eks-stack"
  project_root       = "modules/sage-aws-eks"
  space_id           = "root"
}

resource "spacelift_module" "sage-aws-eks-autoscaler" {
  github_enterprise {
    namespace = "Sage-Bionetworks-Workflows"
    id        = "sage-bionetworks-workflows-gh"
  }

  name               = "sage-aws-eks-autoscaler"
  terraform_provider = "aws"
  administrative     = false
  branch             = "ibcdpe-935-vpc-updates"
  description        = "Terraform module for creating an EKS cluster autoscaler in AWS"
  repository         = "eks-stack"
  project_root       = "modules/sage-aws-k8s-node-autoscaler"
  space_id           = "root"
}


resource "spacelift_context" "k8s-kubeconfig" {
  description = "Hooks used to set up the kubeconfig for connecting to the K8s cluster"
  name        = "Kubernetes Deployments Kubeconfig"

  before_init = [
    "aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME"
  ]
}

resource "spacelift_context_attachment" "attachment" {
  context_id = spacelift_context.k8s-kubeconfig.id
  module_id  = spacelift_module.sage-aws-eks.id
}
