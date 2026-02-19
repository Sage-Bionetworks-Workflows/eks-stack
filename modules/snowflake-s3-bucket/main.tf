resource "aws_kms_key" "rds_export_key" {
  description = "KMS key to encrypt RDS snapshot export objects"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAccountAdministration"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowSourceExportRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.source_account_id}:role/rds-export-to-s3-role"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowRdsService"
        Effect = "Allow"
        Principal = {
          Service = "export.rds.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowSourceAccountDescribeKey"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.source_account_id}:root"
        }
        Action   = "kms:DescribeKey"
        Resource = "*"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name    = "rds-export-to-s3"
      Purpose = "KMS key to encrypt RDS snapshot export objects"
    }
  )
}

resource "aws_kms_alias" "rds_export_key" {
  name          = "alias/rds-export-to-s3"
  target_key_id = aws_kms_key.rds_export_key.key_id
}

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
  depends_on = [aws_s3_bucket_policy.replication_destination_policy]
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
        Sid    = "AllowSpaceliftAdminRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:role/spacelift-admin-role"
        }
        Action = [
          "s3:GetBucketVersioning",
          "s3:GetEncryptionConfiguration",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketPolicy"
        ]
        Resource = aws_s3_bucket.bucket.arn
      },
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
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.rds_export_key.arn
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

# Set up encryption using existing KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.bucket.id
  depends_on = [aws_s3_bucket_policy.replication_destination_policy]

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.rds_export_key.arn
    }
    bucket_key_enabled = true
  }
}
