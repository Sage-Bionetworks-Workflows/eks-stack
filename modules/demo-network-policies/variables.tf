variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "node_security_group_id" {
  description = "Node security group ID"
  type        = string
}

variable "pod_to_node_dns_sg_id" {
  description = "Pod to node DNS security group ID."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "dpe-k8-sandbox"
}

variable "load_balancer_source_ranges" {
  description = "List of CIDR blocks allowed to access the load balancer."
  type        = list(string)
  default     = ["52.44.61.21/32"]
}
