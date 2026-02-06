output "parent_space_id" {
  description = "ID of the parent spacelift space"
  value       = var.parent_space_id
}

output "space_name" {
  description = "Name of the spacelift space to create all of the resources under"
  value       = var.space_name
}

output "snowflake_bucket_name" {
  description = "Name of the S3 bucket for Snowflake data storage"
  value       = var.snowflake_bucket_name
}

output "git_branch" {
  description = "Git branch to track for deployments"
  value       = var.git_branch
}

output "snowflake_stack_name" {
  description = "Name of the Snowflake S3 stack in Spacelift"
  value       = var.snowflake_stack_name
}

output "opentofu_version" {
  description = "Version of OpenTofu to use for deployments"
  value       = var.opentofu_version
}
