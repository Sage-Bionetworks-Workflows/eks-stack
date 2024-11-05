variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "pod_security_group_enforcing_mode" {
  description = "Pod security group enforcing mode"
  type        = string
  default     = "standard"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
}

variable "private_subnet_cidrs_eks_control_plane" {
  type        = list(string)
  description = "Private Subnet CIDR values for the EKS control plane"
}

variable "private_subnet_cidrs_eks_worker_nodes" {
  type        = list(string)
  description = "Private Subnet CIDR values for the EKS worker nodes"
}

variable "azs_eks_control_plane" {
  type        = list(string)
  description = "Availability Zones for the EKS control plane"
}

variable "azs_eks_worker_nodes" {
  type        = list(string)
  description = "Availability Zones for the EKS worker nodes"
}

variable "ses_email_identities" {
  type        = list(string)
  description = "List of email identities to be added to SES"
}
