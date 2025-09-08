variable "cluster_name" {
  description = "Name of K8 cluster"
  type        = string
  default     = "dpe-k8-dev"
}

variable "tags" {
  description = "AWS Resource Tags"
  type        = map(string)
  default = {
    "CostCenter" = "No Program / 000000"
  }
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "EKS cluster ARN for the OIDC provider"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}
