variable "cluster_name" {
    description = "Name of K8 cluster"
    type        = string
    default     = "tyu-spot-ocean"
}

variable "cluster_version" {
    description = "Version of K8 cluster"
    type        = string
    default     = "1.29"
}

variable "vpc_id" {
    description = "AWS VPC ID"
    type        = string
    default     = "vpc-05171ae8175d69c55"
}

variable "subnet_ids" {
    description = "List of private subnet ids"
    type        = list(string)
    default     = [
        "subnet-0201b7533f1e4557e",
        "subnet-01d60989e0bb57681",
        "subnet-029617557f40d6408"
    ]
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

variable "eks_nodeGroup" {
    description = "EKS node group name"
    type        = string
    default     = "airflow-node-group"
}

variable "tags" {
    description = "AWS Resource Tags"
    type        = map(string)
    default     = {
        "CostCenter" = "No Program / 000000"
    }
}
