output "bucket_arns" {
  description = "ARNs of the managed buckets, keyed by bucket name"
  value       = { for name, bucket in aws_s3_bucket.bucket : name => bucket.arn }
}
