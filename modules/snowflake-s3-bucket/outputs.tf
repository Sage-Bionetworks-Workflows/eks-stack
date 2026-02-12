output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.bucket.bucket
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.bucket.arn
}

output "bucket_id" {
  description = "ID of the created S3 bucket"
  value       = aws_s3_bucket.bucket.id
}

output "bucket_domain_name" {
  description = "Bucket domain name"
  value       = aws_s3_bucket.bucket.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Bucket regional domain name"
  value       = aws_s3_bucket.bucket.bucket_regional_domain_name
}

output "kms_key_id" {
  description = "ID of the KMS key used for S3 encryption"
  value       = aws_kms_key.dpe_encryption_key.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for S3 encryption"
  value       = aws_kms_key.dpe_encryption_key.arn
}

output "kms_key_alias" {
  description = "Alias of the KMS key used for S3 encryption"
  value       = aws_kms_alias.dpe_encryption_key_alias.name
}