variable "cluster_name" {
  description = "Name of K8 cluster"
  type        = string
  default     = "dpe-k8-dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "kube_config_path" {
  description = "Kube config path"
  type        = string
  default     = "~/.kube/config"
}

variable "spotinst_account" {
  description = "Spot.io account"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to deploy the cluster to"
  type        = string
}

variable "private_vpc_subnet_ids" {
  description = "List of private subnets to deploy the cluster to"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Security group ID to attach to the EKS cluster"
  type        = string
}

variable "tags" {
  description = "AWS Resource Tags"
  type        = map(string)
  default = {
    "CostCenter" = "No Program / 000000"
  }
}

variable "desired_capacity" {
  description = "Desired capacity of the node group"
  type        = number
  default     = 1
}

variable "single_az" {
  description = "Single AZ"
  type        = bool
}