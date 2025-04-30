# AWS SQS Module

This Terraform module creates:
1. An AWS SQS queue using ACK (AWS Controllers for Kubernetes)
2. A webhook testing SQS queue directly in AWS
3. An API Gateway endpoint for testing webhooks that forwards events to the test SQS queue

## Features

- Creates SQS queues using both Kubernetes (ACK) and direct AWS resources
- Configurable queue attributes like visibility timeout, message retention period, etc.
- API Gateway integration for webhook testing

## Usage

```hcl
module "sqs" {
  source = "modules/aws-sqs"

  environment            = "dev"
  name                   = "application"
  queue_name             = "my-queue"
  namespace              = "default"
  aws_region             = "us-east-1"
  aws_account_id         = "123456789012"
  ack_controller_role_arn = "arn:aws:iam::123456789012:role/ack-sqs-controller"
  
  # Optional queue configuration
  visibility_timeout      = "30"
  message_retention_period = "345600"
  delay_seconds           = "0"
  maximum_message_size    = "262144"
  
  tags = {
    Environment = "dev"
    Application = "my-app"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | ~> 5.0 |
| helm | ~> 2.0 |
| kubernetes | ~> 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | The environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| queue_name | The name of the SQS queue | `string` | n/a | yes |
| namespace | The Kubernetes namespace to deploy to | `string` | `"default"` | no |
| aws_region | The AWS region to deploy to | `string` | `"us-east-1"` | no |
| aws_account_id | The AWS account ID | `string` | n/a | yes |
| ack_controller_role_arn | The ARN of the IAM role for the ACK controller | `string` | n/a | yes |
| visibility_timeout | The visibility timeout for the queue in seconds | `string` | `"30"` | no |
| message_retention_period | The message retention period in seconds | `string` | `"345600"` | no |
| delay_seconds | The delay in seconds before a message becomes available for processing | `string` | `"0"` | no |
| maximum_message_size | The maximum message size in bytes | `string` | `"262144"` | no |
| tags | A map of tags to assign to the queue | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| queue_name | The name of the SQS queue |
| queue_url | The URL of the SQS queue |
| sqs_queue_url | The URL of the webhook test SQS queue |
| sqs_queue_arn | The ARN of the webhook test SQS queue |
| api_gateway_url | The URL of the API Gateway endpoint | 
