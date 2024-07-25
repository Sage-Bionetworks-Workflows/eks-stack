variable "vpc_name" {
  description = "Name of VPC"
  type        = string
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
