terraform {
  required_providers {
    spotinst = {
      source = "spotinst/spotinst"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    auth0 = {
      source = "auth0/auth0"
      version = "1.7.1"
    }
  }
}
