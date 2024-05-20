variable "cluster_name" {
  description = "Name of K8 cluster"
  type        = string
  default     = "dpe-k8"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "spotinst_account" {
  description = "Spot.io account"
  type        = string
  default     = "act-ac6522b4"
}

variable "tags" {
  description = "AWS Resource Tags"
  type        = map(string)
  default = {
    "CostCenter" = "No Program / 000000"
  }
}
