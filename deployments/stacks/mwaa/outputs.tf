output "webserver_url" {
  description = "Airflow webserver URL of the MWAA environment"
  value       = module.mwaa.webserver_url
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket holding DAGs, requirements and plugins"
  value       = module.mwaa.s3_bucket_arn
}
