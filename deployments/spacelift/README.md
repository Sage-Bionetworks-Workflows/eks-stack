# Spacelift Pipeline Configs

Each subdirectory here defines Spacelift CI/CD pipeline resources for a group of related stacks. These configs control _how_ stacks get deployed — not _what_ gets deployed (that's in `../stacks/`).

## Directory Structure

Each config subdirectory typically contains these Terraform files:

- `main.tf` — The primary Spacelift resource definitions (spaces, stacks, variables, AWS integrations)
- `variables.tf` — Input variables passed from the parent module (e.g., `parent_space_id`, `aws_integration_id`)
- `outputs.tf` — Stack IDs and other values for reference by dependent modules
- `versions.tf` — The Spacelift provider source. The `versions.tf` of the admin stack root pins the version

For more on Terraform file organization, see [Spacelift's guide to Terraform files](https://spacelift.io/blog/terraform-files#project-structure-and-file-types-explained).

## What Each Config Typically Contains

The `main.tf` file defines these Spacelift resources:

- `spacelift_space` — A logical grouping within Spacelift
- `spacelift_stack` — One or more stacks, each with a `project_root` pointing to a directory in `../stacks/`. Every stack sets:
  - `additional_project_globs` — every file outside `project_root` that its plan reads: the `*.tf` files of the modules it sources, the templates those modules read with `templatefile()`, and `deployments/config/*.tf` if it reads it. A push that changes none of these, and nothing under `project_root`, does not trigger the stack. Files that ArgoCD reads from git do not change a plan, so they are not listed
  - `autodeploy = false` — every run waits for someone to confirm it
  - `protect_from_deletion = true` — deleting a stack also deletes its Spacelift-managed state. To remove a stack, set this to `false` and apply before deleting its module call
- `spacelift_environment_variable` — The MWAA and DAG buckets stacks get only `TF_VAR_deployment_environment`, and keep every other value in `../stacks/<name>/environments.tf`. Their prod stacks also set `allow_run_promotion = false`, so only dev can be deployed from a pull request. The Snowflake config still passes all of its stack's inputs as `TF_VAR_*`
- `spacelift_aws_integration_attachment` — Binds AWS credentials for the target account
- `spacelift_stack_dependency` (optional) — Defines execution order between stacks

## How a stack gets its values

- The admin stack applies `../main.tf` and the configs in this directory. This run makes or changes the Spacelift stacks. It does not run them.
- Each Spacelift stack then runs its `project_root` in `../stacks/`. This is a separate run with a separate state.
- A stack cannot get module arguments from `../main.tf`. The admin stack can only give it `TF_VAR_*` environment variables.
- A `TF_VAR_*` value changes only when the admin stack applies. Until then, all runs of the stack use the old value. This includes the proposed runs of a pull request. For this reason, the MWAA and DAG buckets stacks keep their values in their own files.
- For the Snowflake config, the default in `variables.tf` is frequently not the value that the stack gets. Read the module call in `../main.tf`.

## Activation

Configs here must be referenced via a `module` block in `../main.tf` to be active. Simply creating a subdirectory here does not automatically create Spacelift stacks.
