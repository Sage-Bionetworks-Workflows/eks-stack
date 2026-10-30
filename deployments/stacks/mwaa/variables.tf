variable "enabled" {
  description = "When false no AWS resources are created. Set to true to provision the VPC and MWAA environment"
  type        = bool
  default     = false
}

variable "name" {
  description = "Name of the MWAA environment"
  type        = string
}

variable "region" {
  description = "AWS region the MWAA environment is created in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name of the VPC the MWAA environment runs in"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones the subnets are spread across"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR values. MWAA requires exactly two, in different availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR values, used for the NAT gateway"
  type        = list(string)
}

variable "airflow_version" {
  description = "Airflow version of the MWAA environment. Empty uses the latest version MWAA supports. Raising the major version (for example 2.x to 3.x) replaces the environment"
  type        = string
  default     = ""
}

variable "orca_recipes_sha" {
  description = "Commit SHA of orca-recipes whose requirements-airflow.txt and mwaa/constraints.txt are installed on the environment"
  type        = string
}

variable "deployment_environment" {
  description = "dev or prod. Exposed to DAGs as AIRFLOW__ORCA__ENVIRONMENT, and selects the orca-recipes GitHub environment (mwaa-<value>) allowed to deploy DAGs"
  type        = string
}

variable "dag_s3_buckets" {
  description = "S3 buckets that DAGs read and write as the MWAA execution role (S3Hook(aws_conn_id=None)). Created by the dag-buckets stack"
  type        = list(string)
  default     = []
}
