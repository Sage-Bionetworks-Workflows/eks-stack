variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids_eks_worker_nodes" {
  description = "Private subnet IDs for the EKS worker nodes"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Node security group ID"
  type        = string
}

variable "pod_to_node_dns_sg_id" {
  description = "Pod to node DNS security group ID."
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

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "EKS cluster ARN for the oidc provider"
  type        = string
}

variable "spotinst_account" {
  description = "Spot.io account"
  type        = string
}

variable "auto_deploy" {
  description = "Automatically deploy the stack"
  type        = bool
}

variable "auto_prune" {
  description = "Automatically prune kubernetes resources"
  type        = bool
}

variable "git_revision" {
  description = "The git revision to deploy"
  type        = string
  default     = "main"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
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

variable "auth0_jwks_uri" {
  description = "The JWKS URI for Auth0"
  type        = string
}

variable "auth0_identifier" {
  description = "Auth0 identifier for the API. Used to verify the audience in the JWT."
  type        = string
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

variable "docker_access_token" {
  description = "The access token to use for docker authenticated pulls. Created via by setting 'TF_VAR_docker_access_token' within spacelift as an environment variable"
  type        = string
  default     = ""
}
