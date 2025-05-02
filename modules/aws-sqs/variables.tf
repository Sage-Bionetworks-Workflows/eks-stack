variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "name" {
  description = "The name prefix for resources created by this module"
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "The ARN of the OIDC provider for the EKS cluster"
  type        = string
}

variable "visibility_timeout" {
  description = "The visibility timeout for the queue in seconds"
  type        = number
  default     = 30
}

variable "message_retention_period" {
  description = "The message retention period in seconds"
  type        = number
  default     = 345600  # 4 days
}

variable "delay_seconds" {
  description = "The delay in seconds before a message becomes available for processing"
  type        = number
  default     = 0
}

variable "maximum_message_size" {
  description = "The maximum message size in bytes"
  type        = number
  default     = 262144  # 256 KiB
}

variable "tags" {
  description = "A map of tags to assign to the queue"
  type        = map(string)
  default     = {}
}

# API Gateway Integration Variables
variable "enable_api_gateway_integration" {
  description = "Whether to enable the API Gateway integration"
  type        = bool
  default     = false
}

variable "api_gateway_id" {
  description = "The ID of the API Gateway to integrate with. Required if enable_api_gateway_integration is true."
  type        = string
  default     = ""
}

variable "route_path" {
  description = "The path for the API Gateway route (e.g., /events, /messages)"
  type        = string
  default     = "/events"
} 
