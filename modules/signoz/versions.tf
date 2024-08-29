terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
  # TODO: Move to this provider
  # required_providers {
  #   argocd = {
  #     source = "oboukili/argocd"
  #     version = "6.1.1"
  #   }
  # }
}

