# Spacelift Pipeline Configs

Each subdirectory here defines Spacelift CI/CD pipeline resources for a group of related stacks. These configs control _how_ stacks get deployed — not _what_ gets deployed (that's in `../stacks/`).

## Directory Structure

Each config subdirectory typically contains these Terraform files:

- `main.tf` — The primary Spacelift resource definitions (spaces, stacks, variables, AWS integrations)
- `variables.tf` — Input variables passed from the parent module (e.g., `parent_space_id`, `aws_integration_id`)
- `outputs.tf` — Stack IDs and other values for reference by dependent modules
- `versions.tf` — Required Spacelift provider version

For more on Terraform file organization, see [Spacelift's guide to Terraform files](https://spacelift.io/blog/terraform-files#project-structure-and-file-types-explained).

## What Each Config Typically Contains

The `main.tf` file defines these Spacelift resources:

- `spacelift_space` — A logical grouping within Spacelift
- `spacelift_stack` — One or more stacks, each with a `project_root` pointing to a directory in `../stacks/`
- `spacelift_environment_variable` — Passes `TF_VAR_*` variables to the stack
- `spacelift_aws_integration_attachment` — Binds AWS credentials for the target account
- `spacelift_stack_dependency` (optional) — Defines execution order between stacks

## Activation

Configs here must be referenced via a `module` block in `../main.tf` to be active. Simply creating a subdirectory here does not automatically create Spacelift stacks.
