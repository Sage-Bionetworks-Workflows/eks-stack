variable "enabled" {
  description = "When false no AWS resources are created. Set to true to provision the VPC and MWAA environment"
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

variable "vpc_name" {
  description = "Name of the VPC the MWAA environment runs in"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones the subnets are spread across"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR values. MWAA requires exactly two, in different availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR values, used for the NAT gateway"
  type        = list(string)
}
