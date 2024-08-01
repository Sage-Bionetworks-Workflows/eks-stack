variable "vpc_name" {
  description = "Name of VPC"
  type        = string
}

variable "cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
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

variable "capture_flow_logs" {
  description = "Determine if we should capture VPC flow logs. When true this will forward flow logs to cloudwatch."
  type        = bool
  default     = false
}

variable "flow_log_retention" {
  description = "Number of days to retain flow logs in CloudWatch Logs"
  type        = number
  default     = 1
}
