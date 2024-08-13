variable "parent_space_id" {
  description = "ID of the parent spacelift space"
  type        = string
}

variable "tags" {
  description = "AWS Resource Tags"
  type        = map(string)
  default = {
    "CostCenter" = "No Program / 000000"
  }
}

variable "admin_stack_id" {
  description = "ID of the admin stack"
  type        = string
}

variable "aws_integration_id" {
  description = "ID of the AWS integration"
  type        = string
}

variable "space_name" {
  description = "Name of the spacelift space to create all of the resources under"
  type        = string
}

variable "git_branch" {
  description = "The branch to deploy"
  type        = string
}

variable "auto_deploy" {
  description = "Automatically deploy the stack"
  type        = bool
  default     = false
}

variable "auto_prune" {
  description = "Automatically prune kubernetes resources"
  type        = bool
  default     = false
}

variable "k8s_stack_name" {
  description = "Name of the k8s stack"
  type        = string
}

variable "k8s_stack_project_root" {
  description = "Project root of the k8s stack"
  type        = string
}

variable "k8s_stack_deployments_name" {
  description = "Name of the k8s stack deployments"
  type        = string
}

variable "k8s_stack_deployments_project_root" {
  description = "Project root of the k8s stack deployments"
  type        = string
}


variable "opentofu_version" {
  description = "Version of opentofu to use"
  type        = string
  default     = "1.7.2"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
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
  description = "VPC CIDR block"
  type        = string
}

variable "kube_config_path" {
  description = "Kube config path"
  type        = string
  default     = "~/.kube/config"
}

variable "spotinst_account" {
  description = "Spot.io account"
  type        = string
  default     = "act-45de6f47"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
}
