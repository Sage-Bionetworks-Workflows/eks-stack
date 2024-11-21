output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.bucket.id
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.bucket.arn
}

output "access_role_arn" {
  description = "ARN of the role to access the S3 bucket"
  value       = aws_iam_role.s3-access-iam-role.arn
}