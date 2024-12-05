terraform {
  required_providers {
    spotinst = {
      source = "spotinst/spotinst"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.17.0"
    }
  }
}
