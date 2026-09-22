variable "parent_space_id" {
  description = "ID of the parent spacelift space"
  type        = string
}

variable "space_name" {
  description = "Name of the spacelift space to create all of the resources under"
  type        = string
}

variable "auto_deploy" {
  description = "Automatically deploy the stack when changes are detected"
  type        = bool
  default     = false
}

variable "git_branch" {
  description = "Git branch to track for deployments"
  type        = string
}

variable "aws_integration_id" {
  description = "ID of the AWS integration in Spacelift"
  type        = string
}

variable "opentofu_version" {
  description = "Version of OpenTofu to use for deployments"
  type        = string
  default     = "1.8.6"
}

variable "mwaa_stack_name" {
  description = "Name of the MWAA stack in Spacelift"
  type        = string
}

variable "mwaa_stack_project_root" {
  description = "Project root directory containing the MWAA Terraform code"
  type        = string
}

variable "enabled" {
  description = "When false the stack creates no AWS resources. Set to true to provision the VPC and MWAA environment"
  type        = bool
  default     = false
}

variable "mwaa_name" {
  description = "Name of the MWAA environment"
  type        = string
}

variable "region" {
  description = "AWS region the MWAA environment is created in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name of the VPC the MWAA environment runs in"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones the subnets are spread across"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR values. MWAA requires exactly two, in different availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR values, used for the NAT gateway"
  type        = list(string)
}
