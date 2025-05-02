variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "name" {
  description = "The name prefix for resources created by this module"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the API Gateway"
  type        = map(string)
  default     = {}
} 
