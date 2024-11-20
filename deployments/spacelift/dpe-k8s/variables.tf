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

variable "enable_cluster_ingress" {
  description = "Enable cluster ingress"
  type        = bool
}

variable "enable_otel_ingress" {
  description = "Enable OpenTelemetry ingress, used to send traces to SigNoz"
  type        = bool
}

variable "ssl_hostname" {
  description = "The hostname to use for the SSL certificate"
  type        = string
}

variable "deploy_auth0" {
  description = "Determines if a stack for Auth0 should be deployed"
  type        = bool
  default     = false
}

variable "auth0_jwks_uri" {
  description = "The JWKS URI for Auth0"
  type        = string
}

variable "auth0_stack_name" {
  description = "Name of the auth0 stack"
  type        = string
}

variable "auth0_stack_project_root" {
  description = "Project root of the auth0 stack"
  type        = string
}

variable "auth0_domain" {
  description = "Auth0 domain"
  type        = string
}

variable "auth0_clients" {
  description = "List of clients to create in Auth0."
  type = list(object({
    name        = string
    description = string
    app_type    = string
    scopes      = list(string)
  }))
}

variable "auth0_identifier" {
  description = "Auth0 identifier for the created API."
  type        = string
  default     = ""
}

variable "ses_email_identities" {
  type        = list(string)
  description = "List of email identities to be added to SES"
}

variable "smtp_user" {
  description = "The SMTP user. Required if smtp_user, smtp_password, and smtp_from are set"
  type        = string
  default     = ""
}

variable "smtp_password" {
  description = "The SMTP password. Required if smtp_user, smtp_password, and smtp_from are set"
  type        = string
  default     = ""
}

variable "smtp_from" {
  description = "The SMTP from address. Required if smtp_user, smtp_password, and smtp_from are set"
  type        = string
  default     = ""
}
