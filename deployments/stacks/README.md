# Deployment Stacks

Each subdirectory here is a deployable Terraform root module. When a Spacelift pipeline runs, it executes `tofu plan/apply` against one of these directories.

## Standard File Layout

Each stack should contain:

- `main.tf` — Sources modules from `../../modules/` and defines cloud resources
- `variables.tf` — Environment-specific inputs (passed as `TF_VAR_*` from Spacelift)
- `outputs.tf` — Values to export (used by dependent stacks or for reference)
- `provider.tf` — AWS provider configuration
- `versions.tf` — Required providers and OpenTofu version

## Spacelift Pipeline Configs

Each stack here is managed by a corresponding config in `../spacelift/`. See the comment at the top of each stack's `main.tf` for which spacelift config manages it.
