# Spacelift Pipeline Configs

Each subdirectory here defines Spacelift CI/CD pipeline resources for a group of related stacks. These configs control _how_ stacks get deployed — not _what_ gets deployed (that's in `../stacks/`).

## What Each Config Typically Contains

- `spacelift_space` — A logical grouping within Spacelift
- `spacelift_stack` — One or more stacks, each with a `project_root` pointing to a directory in `../stacks/`
- `spacelift_environment_variable` — Passes `TF_VAR_*` variables to the stack
- `spacelift_aws_integration_attachment` — Binds AWS credentials for the target account
- `spacelift_stack_dependency` (optional) — Defines execution order between stacks

## Activation

Configs here must be referenced via a `module` block in `../main.tf` to be active. Simply creating a subdirectory here does not automatically create Spacelift stacks.
