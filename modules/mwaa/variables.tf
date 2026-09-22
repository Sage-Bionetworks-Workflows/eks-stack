variable "enabled" {
  description = "When false no AWS resources are created. Set to true to provision the MWAA environment"
  type        = bool
  default     = false
}

variable "name" {
  description = "Name of the MWAA environment"
  type        = string
}

variable "region" {
  description = "AWS region the MWAA environment is created in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the VPC the MWAA security group is created in. Required when enabled is true"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Private subnet IDs for the MWAA environment. MWAA requires exactly two, in different availability zones. Required when enabled is true"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the MWAA resources"
  type        = map(string)
  default     = {}
}
