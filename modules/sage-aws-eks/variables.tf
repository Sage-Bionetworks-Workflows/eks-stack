variable "cluster_name" {
  description = "Name of K8 cluster"
  type        = string
  default     = "dpe-k8-dev"
}

variable "cluster_version" {
  description = "Version of K8 cluster"
  type        = string
  default     = "1.30"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "AWS Resource Tags"
  type        = map(string)
  default = {
    "CostCenter" = "No Program / 000000"
  }
}

variable "vpc_id" {
  description = "ID of the VPC to deploy the cluster to"
  type        = string
}

variable "private_vpc_subnet_ids" {
  description = "List of private subnets to deploy the cluster to"
  type        = list(string)
}

variable "vpc_security_group_id" {
  description = "Security group ID to attach to the EKS cluster"
  type        = string
}
