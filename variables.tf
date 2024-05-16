variable "cluster_name" {
  description = "Name of K8 cluster"
  type        = string
  default     = "dpe-k8"
}

variable "cluster_version" {
  description = "Version of K8 cluster"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  description = "AWS VPC ID"
  type        = string
  default     = "vpc-0451035edd61bca1f"
  # default     = "vpc-05171ae8175d69c55"
}

variable "cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.51.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.51.1.0/24", "10.51.2.0/24", "10.51.3.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.51.4.0/24", "10.51.5.0/24", "10.51.6.0/24"]

}

variable "azs" {

  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]

}

variable "subnet_ids" {
  description = "List of private subnet ids"
  type        = list(string)
  default = [
    "subnet-041a1e077243cdb07",
    "subnet-0826300f0c95283bd",
    "subnet-0b6798133e603e122",
    "subnet-04dfa7fb6a9e476d7"
    # "subnet-0201b7533f1e4557e",
    # "subnet-01d60989e0bb57681",
    # "subnet-029617557f40d6408"
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
  default = {
    "CostCenter" = "No Program / 000000"
    # "kubernetes.io/cluster/tyu-spot-ocean" = "owned",
    # "key"   = "kubernetes.io/cluster/tyu-spot-ocean",
    # "value" = "owned"
  }
}
