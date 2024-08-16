variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Node security group ID"
  type        = string
}

variable "pod_to_node_dns_sg_id" {
  description = "Pod to node DNS security group ID."
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

variable "kube_config_path" {
  description = "Kube config path"
  type        = string
  default     = "~/.kube/config"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "spotinst_account" {
  description = "Spot.io account"
  type        = string
}

variable "auto_deploy" {
  description = "Automatically deploy the stack"
  type        = bool
}

variable "auto_prune" {
  description = "Automatically prune kubernetes resources"
  type        = bool
}

variable "git_revision" {
  description = "The git revision to deploy"
  type        = string
  default     = "main"
}
