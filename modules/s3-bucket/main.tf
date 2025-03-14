resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
    }
  )
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  count = var.public_access ? 1 : 0
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "access_block" {
  count = var.public_access ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  count = var.public_access ? 1 : 0
  depends_on = [
    aws_s3_bucket_ownership_controls.ownership,
    aws_s3_bucket_public_access_block.access_block,
  ]

  bucket = aws_s3_bucket.bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}


resource "aws_iam_policy" "s3-access-policy" {
  name        = "access-policy-${var.aws_account_id}-${var.cluster_name}-${var.bucket_name}"
  description = "Policy to access the s3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          aws_s3_bucket.bucket.arn,
          "${aws_s3_bucket.bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "s3-access-iam-role" {
  name        = "s3-${var.cluster_name}-${var.bucket_name}"
  description = "Assumed role to access the s3 bucket with the given permissions."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "${var.cluster_oidc_provider_arn}",
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3-access-policy-attachment" {
  role       = aws_iam_role.s3-access-iam-role.name
  policy_arn = aws_iam_policy.s3-access-policy.arn
}
