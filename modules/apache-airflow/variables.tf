variable "cluster_name" {
  description = "Name of K8 cluster"
  type        = string
  default     = "dpe-k8"
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

