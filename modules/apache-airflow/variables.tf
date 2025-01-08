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

variable "namespace" {
  description = "The namespace to deploy into"
  type        = string
}

variable "docker_server" {
  description = "The docker registry URL"
  default     = "https://index.docker.io/v1/"
  type        = string
}

variable "docker_username" {
  description = "Username to log into docker for authenticated pulls"
  default     = "dpesagebionetworks"
  type        = string
}

variable "docker_access_token" {
  description = "The access token to use for docker authenticated pulls. Created via by setting 'TF_VAR_docker_access_token' within spacelift as an environment variable"
  type        = string
}

variable "docker_email" {
  description = "The email for the docker account"
  default     = "dpe@sagebase.org"
  type        = string
}
