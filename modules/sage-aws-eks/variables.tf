variable "cluster_name" {
  description = "Name of K8 cluster"
  type        = string
  default     = "dpe-k8-dev"
}

variable "cluster_version" {
  description = "Version of K8 cluster"
  type        = string
  default     = "1.30"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "AWS Resource Tags"
  type        = map(string)
  default = {
    "CostCenter" = "No Program / 000000"
  }
}

variable "vpc_id" {
  description = "ID of the VPC to deploy the cluster to"
  type        = string
}

variable "private_vpc_subnet_ids" {
  description = "List of private subnets to deploy the cluster to"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of private subnets cidrs"
  type        = list(string)
}

variable "vpc_security_group_id" {
  description = "Security group ID to attach to the EKS cluster"
  type        = string
}

variable "enable_policy_event_logs" {
  description = "Enable logging of policy events"
  type        = bool
  default     = false
}

variable "capture_cloudwatch_logs" {
  description = "Determine if we should capture logs to cloudwatch."
  type        = bool
  default     = false
}

variable "cloudwatch_retention" {
  description = "Number of days to retain CloudWatch Logs"
  type        = number
  default     = 1
}

variable "pod_security_group_enforcing_mode" {
  description = "Valid values are 'standard' or 'strict'. More information: https://github.com/aws/amazon-vpc-cni-k8s/blob/master/README.md#pod_security_group_enforcing_mode-v1110"
  type        = string
  default     = "standard"
}

variable "aws_account_id" {
  description = "The AWS account ID to use for assuming any roles"
  type        = string
}
