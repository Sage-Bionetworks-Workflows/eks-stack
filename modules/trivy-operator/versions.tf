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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
<<<<<<< HEAD
=======
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
>>>>>>> origin/ibcdpe-1007-split-into-vars
  }
}
