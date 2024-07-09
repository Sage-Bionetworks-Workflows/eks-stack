resource "spacelift_module" "sage-aws-vpc" {
  name               = "sage-aws-vpc"
  terraform_provider = "aws"
  administrative     = false
  branch             = "ibcdpe-935-vpc-updates"
  description        = "Terraform module for creating a VPC in AWS"
  repository         = "eks-stack"
  project_root       = "modules/sage-aws-vpc"
}

resource "spacelift_module" "sage-aws-eks" {
  name               = "sage-aws-eks"
  terraform_provider = "aws"
  administrative     = false
  branch             = "ibcdpe-935-vpc-updates"
  description        = "Terraform module for creating an EKS cluster in AWS"
  repository         = "eks-stack"
  project_root       = "modules/sage-aws-eks"
}

resource "spacelift_module" "sage-aws-eks-autoscaler" {
  name               = "sage-aws-eks-autoscaler"
  terraform_provider = "aws"
  administrative     = false
  branch             = "ibcdpe-935-vpc-updates"
  description        = "Terraform module for creating an EKS cluster autoscaler in AWS"
  repository         = "eks-stack"
  project_root       = "modules/sage-aws-k8s-node-autoscaler"
}
