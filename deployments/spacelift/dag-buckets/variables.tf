variable "space_id" {
  description = "ID of the spacelift space to create the stack in"
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

variable "stack_name" {
  description = "Name of the stack in Spacelift"
  type        = string
}

variable "stack_project_root" {
  description = "Project root directory containing the Terraform code"
  type        = string
  default     = "deployments/stacks/dag-buckets"
}

variable "region" {
  description = "AWS region the buckets are created in"
  type        = string
  default     = "us-east-1"
}

variable "buckets" {
  description = "Buckets to manage, keyed by bucket name. See deployments/stacks/dag-buckets"
  type = map(object({
    public = bool
  }))
}

variable "import_buckets" {
  description = "Names of existing public buckets in var.buckets to import into the stack"
  type        = list(string)
  default     = []
}
