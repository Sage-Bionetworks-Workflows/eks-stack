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

variable "create_igw" {
  description = "Controls if an Internet Gateway is created for public subnets and the related routes that connect them"
  type        = string
  default     = "false"
}

variable "azs" {

  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]

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
