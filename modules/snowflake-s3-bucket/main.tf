resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  tags = merge(
    var.tags,
    {
      Name        = var.bucket_name
      Purpose     = "Snowflake Data Storage"
      Replication = "Destination"
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

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# Bucket policy to allow cross-account replication
resource "aws_s3_bucket_policy" "replication_destination_policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountReplication"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.source_account_id}:root"
        }
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ]
        Resource = "${aws_s3_bucket.bucket.arn}/*"
      },
      {
        Sid    = "AllowCrossAccountReplicationList"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.source_account_id}:root"
        }
        Action = [
          "s3:List*",
          "s3:GetBucketVersioning"
        ]
        Resource = aws_s3_bucket.bucket.arn
      },
      {
        Sid    = "AllowCrossAccountKMSAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.source_account_id}:root"
        }
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.dpe_encryption_key.arn
          }
        }
      },
      {
        Sid    = "AllowCrossAccountObjectAcl"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.source_account_id}:root"
        }
        Action = [
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.bucket.arn}/*"
      }
    ]
  })
}

# Customer-managed KMS key for S3 encryption
resource "aws_kms_key" "dpe_encryption_key" {
  description = "KMS key for S3 encryption in ${var.bucket_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Statement 1: Destination (DPE) Account Admin permissions
      {
        Sid    = "AllowAdminInDestinationAccount"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },

      # Statement 2: Source (Platform) Account permissions
      {
        Sid    = "AllowCrossAccountReplicationRoleAccess"
        Effect = "Allow"
        # TODO: Tighten this up to just grant permissions to the
        #       source account's replication role
        Principal = {
          AWS = "arn:aws:iam::${var.source_account_id}:root"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },

      # Statement 3: S3 Service cryptographic permissions
      {
        Sid    = "AllowS3ServiceAccess"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${var.region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name    = "dpe_encryption_key"
      Purpose = "S3 encryption for DPE Snowflake bucket ${var.bucket_name}"
    }
  )
}

resource "aws_kms_alias" "dpe_encryption_key_alias" {
  name          = "alias/${var.bucket_name}-encryption"
  target_key_id = aws_kms_key.dpe_encryption_key.key_id
}

# Set up encryption using customer-managed KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.dpe_encryption_key.arn
    }
    bucket_key_enabled = true
  }
}