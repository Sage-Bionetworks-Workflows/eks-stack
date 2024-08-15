variable "git_branch" {
  description = "Branch to deploy"
  type        = string
  # TODO: Migrate to using "main" here
  default = "ibcdpe-1007-monitoring"
}
