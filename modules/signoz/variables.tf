variable "auto_deploy" {
  description = "Auto deploy through ArgoCD"
  type        = bool
  default     = false
}

variable "auto_prune" {
  description = "Auto prune through ArgoCD"
  type        = bool
  default     = false
}

variable "git_revision" {
  description = "The git revision to deploy"
  type        = string
  default     = "main"
}

variable "argo_deployment_name" {
  description = "The name of the ArgoCD deployment, must be globally unique"
  type        = string
}

variable "namespace" {
  description = "The namespace to deploy into"
  type        = string
}


variable "enable_otel_ingress" {
  description = "Enable OpenTelemetry ingress"
  type        = bool
  default     = false
}


variable "gateway_namespace" {
  description = "The namespace of the gateway"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "auth0_jwks_uri" {
  description = "The JWKS URI for Auth0"
  type        = string
}
