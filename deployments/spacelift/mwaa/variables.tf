variable "parent_space_id" {
  description = "ID of the parent spacelift space"
  type        = string
}

variable "space_name" {
  description = "Name of the spacelift space to create all of the resources under"
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

variable "mwaa_stack_name" {
  description = "Name of the MWAA stack in Spacelift"
  type        = string
}

variable "mwaa_stack_project_root" {
  description = "Project root directory containing the MWAA Terraform code"
  type        = string
}

variable "deployment_environment" {
  description = "dev or prod. Selects the stack's values in deployments/stacks/mwaa/environments.tf. Prod stacks do not allow run promotion"
  type        = string
}
