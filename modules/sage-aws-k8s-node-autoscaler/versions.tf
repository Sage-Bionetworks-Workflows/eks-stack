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
    spotinst = {
      source  = "spotinst/spotinst"
      version = "1.172.0" # Specify the version you wish to use
    }
  }
}
