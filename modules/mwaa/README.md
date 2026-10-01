# Purpose
Deploys an Amazon Managed Workflows for Apache Airflow (MWAA) environment. It is a thin
wrapper around [cloudposse/mwaa/aws](https://search.opentofu.org/module/cloudposse/mwaa/aws/latest),
which also creates the S3 bucket for DAGs, the execution IAM role, and the security group.

# Usage
```
module "mwaa" {
  source     = "../../../modules/mwaa"
  enabled    = true
  name       = "mwaa-dev"
  region     = var.region
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
}
```

`enabled` defaults to `false` so the module can be wired up before any AWS resources exist.
While it is `false` nothing is created and `vpc_id`/`subnet_ids` may be left unset.

MWAA requires exactly two private subnets in different availability zones. DAGs are read from
the `dags/` prefix of the bucket created by this module.
