# AWS SQS Module

This module creates an SQS queue with optional API Gateway integration.

## Usage

### SQS Queue with API Gateway integration

```hcl
# First, create the API Gateway
module "api_gateway" {
  source      = "path/to/modules/aws-api-gateway"
  environment = "dev"
  name        = "events-gateway"
  
  tags = {
    Environment = "dev"
    Application = "api-gateway"
    ManagedBy   = "terraform"
  }
}

# Then create an SQS queue integrated with the API Gateway
module "events_queue" {
  source      = "path/to/modules/aws-sqs"
  environment = "dev"
  name        = "events-queue"
  aws_account_id = "123456789012"
  aws_region = "us-east-1"
  cluster_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/..." 
  
  # API Gateway integration
  api_gateway_id = module.api_gateway.api_id
  route_path = "/events"
  
  tags = {
    Environment = "dev"
    Application = "events"
    ManagedBy   = "terraform"
  }
}
```

### Standalone SQS Queue (no API Gateway integration)

```hcl
module "standalone_queue" {
  source      = "path/to/modules/aws-sqs"
  environment = "dev"
  name        = "standalone-queue"
  aws_account_id = "123456789012"
  aws_region = "us-east-1"
  cluster_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/..."
  
  # Do not provide api_gateway_id to skip integration
  
  tags = {
    Environment = "dev"
    Application = "standalone"
    ManagedBy   = "terraform"
  }
}
```

## Multiple queues integrated with a single API Gateway

You can create multiple SQS queues that all connect to the same API Gateway, each with their own unique route:

```hcl
module "api_gateway" {
  source      = "path/to/modules/aws-api-gateway"
  environment = "dev"
  name        = "events-gateway"
}

module "notifications_queue" {
  source      = "path/to/modules/aws-sqs"
  environment = "dev"
  name        = "notifications-queue"
  api_gateway_id = module.api_gateway.api_id
  route_path = "/notifications"
  # ... other required variables
}

module "alerts_queue" {
  source      = "path/to/modules/aws-sqs"
  environment = "dev"
  name        = "alerts-queue"
  api_gateway_id = module.api_gateway.api_id
  route_path = "/alerts"
  # ... other required variables
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.14 |
| aws | >= 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | The environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| name | The name prefix for resources created by this module | `string` | n/a | yes |
| aws_region | The AWS region to deploy to | `string` | `"us-east-1"` | no |
| aws_account_id | The AWS account ID | `string` | n/a | yes |
| cluster_oidc_provider_arn | The ARN of the OIDC provider for the EKS cluster | `string` | n/a | yes |
| visibility_timeout | The visibility timeout for the queue in seconds | `number` | `30` | no |
| message_retention_period | The message retention period in seconds | `number` | `345600` | no |
| delay_seconds | The delay in seconds before a message becomes available for processing | `number` | `0` | no |
| maximum_message_size | The maximum message size in bytes | `number` | `262144` | no |
| tags | A map of tags to assign to the queue | `map(string)` | `{}` | no |
| api_gateway_id | The ID of the API Gateway to integrate with. If null, no API Gateway integration will be created | `string` | `null` | no |
| route_path | The path for the API Gateway route (e.g., /events, /messages) | `string` | `/events` | no |

## Outputs

| Name | Description |
|------|-------------|
| queue_name | The name of the SQS queue |
| queue_url | The URL of the SQS queue |
| queue_arn | The ARN of the SQS queue |
| api_integration_id | The ID of the API Gateway integration |
| api_route_key | The route key for the API Gateway route |
| access_role_arn | ARN of the role to access the SQS queue |
