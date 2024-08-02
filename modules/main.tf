locals {
  spacelift_modules = {

    eks = {
      github_enterprise = {
        namespace = "Sage-Bionetworks-Workflows"
        id        = "sage-bionetworks-workflows-gh"
      }
      repository = "eks-stack"

      name               = "sage-aws-eks"
      terraform_provider = "aws"
      administrative     = false
      branch             = var.git_branch
      description        = "Terraform module for creating an EKS cluster in AWS"
      project_root       = "modules/sage-aws-eks"
      space_id           = "root"
      version_number     = "0.5.0"
    }

    vpc = {
      github_enterprise = {
        namespace = "Sage-Bionetworks-Workflows"
        id        = "sage-bionetworks-workflows-gh"
      }
      repository = "eks-stack"

      name               = "sage-aws-vpc"
      terraform_provider = "aws"
      administrative     = false
      branch             = var.git_branch
      description        = "Terraform module for creating a VPC in AWS"
      project_root       = "modules/sage-aws-vpc"
      space_id           = "root"
      version_number     = "0.4.2"
    }

    eks-autoscaler = {
      github_enterprise = {
        namespace = "Sage-Bionetworks-Workflows"
        id        = "sage-bionetworks-workflows-gh"
      }
      repository = "eks-stack"

      name               = "sage-aws-eks-autoscaler"
      terraform_provider = "aws"
      administrative     = false
      branch             = var.git_branch
      description        = "Terraform module for creating an EKS cluster autoscaler in AWS"
      project_root       = "modules/sage-aws-k8s-node-autoscaler"
      space_id           = "root"
      version_number     = "0.5.0"
    }

    victoria-metrics = {
      github_enterprise = {
        namespace = "Sage-Bionetworks-Workflows"
        id        = "sage-bionetworks-workflows-gh"
      }
      repository = "eks-stack"

      name               = "victoria-metrics"
      terraform_provider = "aws"
      administrative     = false
      branch             = var.git_branch
      description        = "Helm chart deployment for a single node Victoria Metrics instance"
      project_root       = "modules/victoria-metrics"
      space_id           = "root"
      version_number     = "0.2.1"
    }

    trivy-operator = {
      github_enterprise = {
        namespace = "Sage-Bionetworks-Workflows"
        id        = "sage-bionetworks-workflows-gh"
      }
      repository = "eks-stack"

      name               = "trivy-operator"
      terraform_provider = "aws"
      administrative     = false
      branch             = var.git_branch
      description        = "Helm chart deployment for trivy-operator which handles security and vulnerability scanning."
      project_root       = "modules/trivy-operator"
      space_id           = "root"
      version_number     = "0.1.3"
    }

    airflow = {
      github_enterprise = {
        namespace = "Sage-Bionetworks-Workflows"
        id        = "sage-bionetworks-workflows-gh"
      }
      repository = "eks-stack"

      name               = "airflow"
      terraform_provider = "aws"
      administrative     = false
      branch             = var.git_branch
      description        = "Helm chart deployment for apache airflow."
      project_root       = "modules/apache-airflow"
      space_id           = "root"
      version_number     = "0.1.1"
    }

    private-workerpool = {
      github_enterprise = {
        namespace = "Sage-Bionetworks-Workflows"
        id        = "sage-bionetworks-workflows-gh"
      }
      repository = "eks-stack"

      name               = "spacelift-private-workerpool"
      terraform_provider = "aws"
      administrative     = false
      branch             = var.git_branch
      description        = "Module for the spacelift private workerpool helm chart which deploys the K8s operator"
      project_root       = "modules/spacelift-private-worker"
      space_id           = "root"
      version_number     = "0.3.0"
    }
  }
}

resource "spacelift_module" "spacelift_modules" {
  for_each = local.spacelift_modules

  github_enterprise {
    namespace = each.value.github_enterprise.namespace
    id        = each.value.github_enterprise.id
  }

  name               = each.value.name
  terraform_provider = each.value.terraform_provider
  administrative     = each.value.administrative
  branch             = each.value.branch
  description        = each.value.description
  repository         = each.value.repository
  project_root       = each.value.project_root
  space_id           = each.value.space_id
}

resource "spacelift_version" "spacelift_versions" {
  for_each       = local.spacelift_modules
  module_id      = spacelift_module.spacelift_modules[each.key].id
  version_number = each.value.version_number
  keepers = {
    "version" = each.value.version_number
  }
}
