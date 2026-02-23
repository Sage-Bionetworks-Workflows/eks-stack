variable "parent_space_id" {
  description = "ID of the parent spacelift space"
  type        = string
}

variable "space_name" {
  description = "Name of the spacelift space to create all of the resources under"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID where S3 resources will be created"
  type        = string
}

variable "region" {
  description = "AWS region for S3 bucket and related resources"
  type        = string
  default     = "us-east-1"
}

variable "snowflake_bucket_name" {
  description = "Name of the S3 bucket for Snowflake data storage"
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

variable "snowflake_stack_name" {
  description = "Name of the Snowflake S3 stack in Spacelift"
  type        = string
}

variable "snowflake_stack_project_root" {
  description = "Project root directory containing the S3 Terraform code"
  type        = string
}

variable "opentofu_version" {
  description = "Version of OpenTofu to use for deployments"
  type        = string
  default     = "1.8.6"
}

variable "aws_integration_id" {
  description = "ID of the AWS integration in Spacelift"
  type        = string
}

variable "source_account_id" {
  description = "AWS account ID of the Synapse platform source bucket for cross-account access"
  type        = string
}

variable "source_bucket_arn" {
  description = "ARN of the source S3 bucket containing Synapse platform RDS backups"
  type        = string
}

variable "snowflake_principal_arn" {
  description = "ARN of the Snowflake principal (user or role) that will assume the role"
  type        = string
}

variable "snowflake_external_id" {
  description = "External ID for Snowflake role assumption"
  type        = string
  sensitive   = true
}
