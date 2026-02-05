variable "aws_account_id" {
  description = "AWS account ID where S3 resources will be created"
  type        = string
}

variable "region" {
  description = "AWS region for S3 bucket"
  type        = string
  default     = "us-east-1"
}

variable "source_account_id" {
  description = "AWS account ID that will replicate TO this bucket (for cross-account replication)"
  type        = string
}

variable "source_bucket_arn" {
  description = "ARN of the source bucket that will replicate to this bucket"
  type        = string
}