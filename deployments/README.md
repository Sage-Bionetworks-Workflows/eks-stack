# Deployments

This directory contains all deployment configurations. It has two subdirectories that work together:

- **`spacelift/`** — Defines the **CI pipelines** in Spacelift. Each subdirectory creates Spacelift stacks that control _which_ AWS account to deploy to, _what_ environment variables to pass, and _how_ stacks relate to each other.

- **`stacks/`** — Defines the **cloud resources** that get provisioned. Each subdirectory is a Terraform root module that Spacelift runs `tofu plan/apply` against.

The `main.tf` in this directory wires each spacelift config into the appropriate environment (development, staging, production) by creating `spacelift_space` resources and instantiating the spacelift modules with environment-specific variables.

## How They Relate

> For the full architectural overview with diagrams, see [How Deployment Works](../README.md#how-deployment-works) in the root README.

Each spacelift config points to one or more stack directories via the `project_root` attribute on its `spacelift_stack` resources:

| Spacelift Config | Stack(s) Targeted | Purpose |
|---|---|---|
| `spacelift/dpe-k8s/` | `stacks/dpe-k8s/`, `stacks/dpe-k8s-deployments/` | EKS cluster infrastructure and in-cluster deployments |

## Adding a New Deployment

See the [Adding a New Stack](../README.md#adding-a-new-stack) section in the root README for step-by-step instructions.
