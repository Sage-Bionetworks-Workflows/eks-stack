variable "cluster_name" {
  description = "Name of K8 cluster"
  type        = string
  default     = "dpe-k8"
}

variable "node_group_name" {
  description = "Node group name for the cluster"
  type        = string
  default     = "airflow-node-group"
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

variable "spotinst_account" {
  description = "Spot.io account"
  type        = string
  default     = "act-ac6522b4"
}

variable "tags" {
  description = "AWS Resource Tags"
  type        = map(string)
  default = {
    "CostCenter" = "No Program / 000000"
  }
}
