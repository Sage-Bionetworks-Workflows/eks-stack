variable "auto_deploy" {
  description = "Auto deploy through ArgoCD"
  type        = bool
  default     = false
}

variable "git_revision" {
  description = "The git revision to deploy"
  type        = string
  default     = "main"
}

variable "auto_prune" {
  description = "Auto prune through ArgoCD"
  type        = bool
  default     = false
}

variable "namespace" {
  description = "The namespace to deploy into"
  type        = string
}

variable "region" {
  description = "AWS region for External Secrets"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID for IRSA role"
  type        = string
}