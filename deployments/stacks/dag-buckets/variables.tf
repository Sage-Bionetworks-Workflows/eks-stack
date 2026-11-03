variable "deployment_environment" {
  description = "dev or prod. Selects the values in environments.tf and the buckets in deployments/config. Set as TF_VAR_deployment_environment by the root admin stack"
  type        = string
}
