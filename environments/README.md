# Environments

This contains all the "Things" that are going to be deployed. In this top level
directory you'll find that the terraform files are bringing together everything
that should be deployed in spacelift declerativly. The items declared in this top
level directory are as follows:

1) A single root administrative stack that is responsible for taking each and every resource to deploy it to spacelift.
2) A spacelift space that everything is deployed under called `environment`.
3) Reference to the `terraform-registry` modules directory.
4) Reference to `common` or reusable resources that are not environment specific.
5) The environment specific resources such as `dev`, `staging`, or `prod`
