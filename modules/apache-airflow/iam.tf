locals {
  # Only provisioned on the prod cluster, matching the croissant S3 buckets.
  create_croissant_irsa = var.cluster_name == "dpe-k8"

  # The trust policy condition keys are the OIDC provider URL without the scheme.
  oidc_provider_url = replace(
    element(split("oidc-provider/", var.cluster_oidc_provider_arn), 1),
    "https://",
    ""
  )

  croissant_service_account_subjects = [
    "system:serviceaccount:${var.namespace}:airflow-worker",
    "system:serviceaccount:${var.namespace}:airflow-scheduler",
    "system:serviceaccount:${var.namespace}:airflow-triggerer",
    "system:serviceaccount:${var.namespace}:airflow-webserver",
  ]

  croissant_buckets = [
    "synapse-croissant-metadata",
    "synapse-croissant-metadata-minimal",
  ]

  croissant_role_arn = local.create_croissant_irsa ? aws_iam_role.airflow_croissant[0].arn : ""
}

resource "aws_iam_role" "airflow_croissant" {
  count = local.create_croissant_irsa ? 1 : 0

  name        = "airflow-croissant"
  description = "IRSA role assumed by Airflow pods to read airflow/* secrets and CRUD the croissant S3 buckets."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.cluster_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
            "${local.oidc_provider_url}:sub" = local.croissant_service_account_subjects
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "airflow_croissant" {
  count = local.create_croissant_irsa ? 1 : 0

  name        = "airflow-croissant"
  description = "Read airflow/* secrets and CRUD the croissant S3 buckets. Replaces the airflow-secrets-backend IAM user access keys."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CroissantBucketObjects"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Resource = [for bucket in local.croissant_buckets : "arn:aws:s3:::${bucket}/*"]
      },
      {
        Sid    = "CroissantBucketList"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
        ]
        Resource = [for bucket in local.croissant_buckets : "arn:aws:s3:::${bucket}"]
      },
      {
        Sid    = "AirflowSecretsRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Resource = [
          "arn:aws:secretsmanager:us-east-1:${var.aws_account_id}:secret:airflow/connections/*",
          "arn:aws:secretsmanager:us-east-1:${var.aws_account_id}:secret:airflow/variables/*",
        ]
      },
      {
        Sid    = "AirflowSecretsList"
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "airflow_croissant" {
  count = local.create_croissant_irsa ? 1 : 0

  role       = aws_iam_role.airflow_croissant[0].name
  policy_arn = aws_iam_policy.airflow_croissant[0].arn
}
