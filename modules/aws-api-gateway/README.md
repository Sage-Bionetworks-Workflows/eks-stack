# AWS API Gateway Module

This module creates an API Gateway with a default stage that can be used for various integrations.

## Usage

```hcl
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
* **tags**: A map of tags to assign to the API Gateway
  * Type: `map(string)`
  * Default: `{}`
  * Required: no

## Outputs

* **api_id**: The ID of the API Gateway
* **api_endpoint**: The HTTP endpoint of the API Gateway
* **api_arn**: The ARN of the API Gateway
* **stage_id**: The ID of the API Gateway default stage
