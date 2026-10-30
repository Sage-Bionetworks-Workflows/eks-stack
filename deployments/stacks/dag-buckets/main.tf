# S3 buckets that the orca-recipes DAGs write to. Kept out of the EKS and MWAA stacks so
# the buckets and their data outlive the Airflow deployment. Managed by
# deployments/spacelift/dag-buckets. The MWAA execution role is granted access to them
# in modules/mwaa (dag_s3_buckets)
locals {
  # The tags the croissant buckets had in the dpe-k8s stack, so importing them changes nothing
  tags = {
    CostCenter = "No Program / 000000"
  }
  public_buckets = { for name, bucket in var.buckets : name => bucket if bucket.public }
}

resource "aws_s3_bucket" "bucket" {
  for_each = var.buckets

  bucket = each.key
  tags   = merge(local.tags, { Name = each.key })
}

resource "aws_s3_bucket_versioning" "versioning" {
  for_each = var.buckets

  bucket = aws_s3_bucket.bucket[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Public buckets: anyone can read the objects, and browsers can fetch them (CORS). New
# buckets otherwise keep the S3 defaults, which block public access
resource "aws_s3_bucket_ownership_controls" "ownership" {
  for_each = local.public_buckets

  bucket = aws_s3_bucket.bucket[each.key].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "access_block" {
  for_each = local.public_buckets

  bucket                  = aws_s3_bucket.bucket[each.key].id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "acl" {
  for_each = local.public_buckets

  depends_on = [
    aws_s3_bucket_ownership_controls.ownership,
    aws_s3_bucket_public_access_block.access_block,
  ]

  bucket = aws_s3_bucket.bucket[each.key].id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "public_read" {
  for_each = local.public_buckets

  depends_on = [aws_s3_bucket_acl.acl, aws_s3_bucket_public_access_block.access_block]

  bucket = aws_s3_bucket.bucket[each.key].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.bucket[each.key].arn}/*"
      },
    ]
  })
}

resource "aws_s3_bucket_cors_configuration" "cors" {
  for_each = local.public_buckets

  bucket = aws_s3_bucket.bucket[each.key].id
  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}
