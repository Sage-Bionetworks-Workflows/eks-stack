module "clickhouse_backup_bucket" {
  source = "./modules/s3-bucket"

  bucket_name = "clickhouse-backup"
}
