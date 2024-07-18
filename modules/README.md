# Modules

This contains templatized collections of terraform resources that are used in a stack.
Anything that should be reusable according to DRY (Don't repeat yourself) should be
contained within a module and referenced within a specific stack.

### Adding a new module

When a new module is made you'll need to do a few tasks:

1) Create a new directory named after your module
2) Fill that new directory with the required terraform resources
3) Create a [spacelift_module](https://registry.terraform.io/providers/spacelift-io/spacelift/latest/docs/resources/module) and [spacelift_version](https://registry.terraform.io/providers/spacelift-io/spacelift/latest/docs/resources/version) resource in this `modules` `main.tf` script.
4) Commit the changes to a branch, get them reviewed, and merged into main. Once merged they will show up in the `Terraform Registry` within spacelift, ready to be used.

### Creating a new version of a module
Versions of modules are controlled with a terraform resource `spacelift_version` as
defined in this documentation:
https://registry.terraform.io/providers/spacelift-io/spacelift/latest/docs/resources/version

As changes are made you'll want to increment the version of the module following
typical sematic `Major.Minor.Patch` versioning.

### Guidelines for creating new modules

1) Each module should have a well defined and specific focus for what it's creating. For example a database module shouldn't be creating it's own VPC, it should instead expect that you are passing in the required variables to deploy it to a specific VPC.
2) Provide variables for anything that should be customizable, such as names.
3) Use `outputs.tf` to export any values that are useful to know about your module. For example the `id` of a resource.
