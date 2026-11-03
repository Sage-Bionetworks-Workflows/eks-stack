variable "deployment_environment" {
  description = "dev or prod. Selects the values in environments.tf. Exposed to DAGs as AIRFLOW__ORCA__ENVIRONMENT, and selects the orca-recipes GitHub environment (mwaa-<value>) allowed to deploy DAGs. Set as TF_VAR_deployment_environment by the root admin stack"
  type        = string
}
