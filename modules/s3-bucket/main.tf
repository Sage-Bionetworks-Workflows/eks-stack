locals {
  create_access_role = var.cluster_oidc_provider_arn != null
}

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
  count  = var.public_access ? 1 : 0
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "access_block" {
  count  = var.public_access ? 1 : 0
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

resource "aws_s3_bucket_policy" "my_bucket_policy" {
  count  = var.public_access ? 1 : 0
  bucket = aws_s3_bucket.bucket.bucket

  depends_on = [aws_s3_bucket_acl.bucket_acl, aws_s3_bucket_public_access_block.access_block]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.bucket.arn}/*", # Allow access to all objects within the bucket
      },
    ],
  })
}

resource "aws_s3_bucket_cors_configuration" "cors" {
  count  = var.enable_cors ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}


# EKS access role: only created when cluster_oidc_provider_arn is set
resource "aws_iam_policy" "s3-access-policy" {
  count = local.create_access_role ? 1 : 0

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
  count = local.create_access_role ? 1 : 0

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
  count = local.create_access_role ? 1 : 0

  role       = aws_iam_role.s3-access-iam-role[0].name
  policy_arn = aws_iam_policy.s3-access-policy[0].arn
}
