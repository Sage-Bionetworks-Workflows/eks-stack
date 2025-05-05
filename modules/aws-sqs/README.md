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
  enable_api_gateway_integration = true
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
  
  # Do not enable API Gateway integration
  enable_api_gateway_integration = false
  
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
  enable_api_gateway_integration = true
  api_gateway_id = module.api_gateway.api_id
  route_path = "/notifications"
  aws_account_id = "123456789012"
  aws_region = "us-east-1"
  cluster_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/..."
}

module "alerts_queue" {
  source      = "path/to/modules/aws-sqs"
  environment = "dev"
  name        = "alerts-queue"
  enable_api_gateway_integration = true
  api_gateway_id = module.api_gateway.api_id
  route_path = "/alerts"
  aws_account_id = "123456789012"
  aws_region = "us-east-1"
  cluster_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/..."
}
```

## Requirements

* **terraform**: >= 0.14
* **aws**: >= 3.0

## Inputs

* **environment**: The environment name (e.g., dev, staging, prod)
  * Type: `string`
  * Default: n/a
  * Required: yes
* **name**: The name prefix for resources created by this module
  * Type: `string`
  * Default: n/a
  * Required: yes
* **aws_region**: The AWS region to deploy to
  * Type: `string`
  * Default: `"us-east-1"`
  * Required: no
* **aws_account_id**: The AWS account ID
  * Type: `string`
  * Default: n/a
  * Required: yes
* **cluster_oidc_provider_arn**: The ARN of the OIDC provider for the EKS cluster
  * Type: `string`
  * Default: n/a
  * Required: yes
* **visibility_timeout**: The visibility timeout for the queue in seconds
  * Type: `number`
  * Default: `30`
  * Required: no
* **message_retention_period**: The message retention period in seconds
  * Type: `number`
  * Default: `345600`
  * Required: no
* **delay_seconds**: The delay in seconds before a message becomes available for processing
  * Type: `number`
  * Default: `0`
  * Required: no
* **maximum_message_size**: The maximum message size in bytes
  * Type: `number`
  * Default: `262144`
  * Required: no
* **tags**: A map of tags to assign to the queue
  * Type: `map(string)`
  * Default: `{}`
  * Required: no
* **enable_api_gateway_integration**: Whether to enable the API Gateway integration
  * Type: `bool`
  * Default: `false`
  * Required: no
* **api_gateway_id**: The ID of the API Gateway to integrate with. Required if enable_api_gateway_integration is true.
  * Type: `string`
  * Default: `""`
  * Required: no
* **route_path**: The path for the API Gateway route (e.g., /events, /messages)
  * Type: `string`
  * Default: `/events`
  * Required: no

## Outputs

* **queue_name**: The name of the SQS queue
* **queue_url**: The URL of the SQS queue
* **queue_arn**: The ARN of the SQS queue
* **api_integration_id**: The ID of the API Gateway integration
* **api_route_key**: The route key for the API Gateway route
* **access_role_arn**: ARN of the role to access the SQS queue
