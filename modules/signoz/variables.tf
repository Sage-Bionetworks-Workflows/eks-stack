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
