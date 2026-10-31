# Deployment Stacks

Each subdirectory here is a deployable Terraform root module. When a Spacelift pipeline runs, it executes `tofu plan/apply` against one of these directories.

## Standard File Layout

Each stack should contain:

- `main.tf` — Sources modules from `../../modules/` and defines cloud resources
- `environments.tf` — Every value the stack deploys, keyed by `deployment_environment`, and a check that the stack runs in that environment's AWS account (`mwaa`, `dag-buckets`)
- `variables.tf` — `deployment_environment`, passed as `TF_VAR_deployment_environment` from Spacelift. The `dpe-k8s`, `dpe-k8s-deployments` and `snowflake` stacks still take all of their inputs as `TF_VAR_*`
- `outputs.tf` — Values to export (used by dependent stacks or for reference)
- `provider.tf` — AWS provider configuration
- `versions.tf` — Required providers and OpenTofu version

## Spacelift Pipeline Configs

Each stack here is managed by a corresponding config in `../spacelift/`. See the comment at the top of each stack's `main.tf` for which spacelift config manages it.

When a stack starts sourcing another module, or reading `../config`, add those files to the stack's `additional_project_globs` in its spacelift config. Otherwise a change to them does not plan the stack.
