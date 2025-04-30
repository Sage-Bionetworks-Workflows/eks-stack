variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "name" {
  description = "The name prefix for resources created by this module"
  type        = string
}

variable "queue_name" {
  description = "The name of the SQS queue"
  type        = string
}

variable "namespace" {
  description = "The Kubernetes namespace to deploy to"
  type        = string
  default     = "default"
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

variable "ack_controller_role_arn" {
  description = "The ARN of the IAM role for the ACK controller"
  type        = string
}

variable "visibility_timeout" {
  description = "The visibility timeout for the queue in seconds"
  type        = string
  default     = "30"
}

variable "message_retention_period" {
  description = "The message retention period in seconds"
  type        = string
  default     = "345600"  # 4 days
}

variable "delay_seconds" {
  description = "The delay in seconds before a message becomes available for processing"
  type        = string
  default     = "0"
}

variable "maximum_message_size" {
  description = "The maximum message size in bytes"
  type        = string
  default     = "262144"  # 256 KiB
}

variable "tags" {
  description = "A map of tags to assign to the queue"
  type        = map(string)
  default     = {}
} 
