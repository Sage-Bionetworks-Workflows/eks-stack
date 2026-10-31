variable "space_id" {
  description = "ID of the spacelift space to create the stack in"
  type        = string
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

variable "stack_name" {
  description = "Name of the stack in Spacelift"
  type        = string
}

variable "stack_project_root" {
  description = "Project root directory containing the Terraform code"
  type        = string
  default     = "deployments/stacks/dag-buckets"
}

variable "deployment_environment" {
  description = "dev or prod. Selects the stack's values in deployments/stacks/dag-buckets/environments.tf. Prod stacks do not allow run promotion"
  type        = string
}
