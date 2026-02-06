variable "parent_space_id" {
  description = "ID of the parent spacelift space"
  type        = string
}

variable "space_name" {
  description = "Name of the spacelift space to create all of the resources under"
  type        = string
}

variable "snowflake_bucket_name" {
  description = "Name of the S3 bucket for Snowflake data storage"
  type        = string
}

variable "git_branch" {
  description = "Git branch to track for deployments"
  type        = string
}

output "snowflake_stack_name" {
  description = "Name of the Snowflake S3 stack in Spacelift"
  value       = var.snowflake_stack_name
}

output "opentofu_version" {
  description = "Version of OpenTofu to use for deployments"
  value       = var.opentofu_version
}
