terraform {
  required_version = "<= 1.5.7"
  required_providers {
    spotinst = {
      source  = "spotinst/spotinst"
      version = "1.172.0" # Specify the version you wish to use
    }
  }
}
