module "create_bucket_snowflake_rds_landing" {
  source      = "../../../modules/s3-bucket"
  bucket_name = "snowflake_rds_landing"
  enable_versioning = true
  aws_account_id = var.aws_account_id
}