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

| Name | Version |
|------|---------|
| terraform | >= 0.14 |
| aws | >= 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | The environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| name | The name prefix for resources created by this module | `string` | n/a | yes |
| tags | A map of tags to assign to the API Gateway | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| api_id | The ID of the API Gateway |
| api_endpoint | The HTTP endpoint of the API Gateway |
| api_arn | The ARN of the API Gateway |
| stage_id | The ID of the API Gateway default stage | 
