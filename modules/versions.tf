terraform {
  required_version = "<= 1.5.7"

  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "1.13.0"
    }
  }
}
