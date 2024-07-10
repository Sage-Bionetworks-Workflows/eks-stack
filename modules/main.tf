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

resource "spacelift_version" "sage-aws-vpc-version" {
  module_id      = spacelift_module.sage-aws-vpc.id
  version_number = "0.2.1"
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

resource "spacelift_version" "sage-aws-eks-version" {
  module_id      = spacelift_module.sage-aws-eks.id
  version_number = "0.2.2"
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

resource "spacelift_version" "sage-aws-eks-autoscaler-version" {
  module_id      = spacelift_module.sage-aws-eks-autoscaler.id
  version_number = "0.2.2"
}
