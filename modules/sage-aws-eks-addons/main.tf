resource "aws_eks_addon" "coredns" {
  cluster_name = var.cluster_name
  addon_name   = "coredns"
  tags         = var.tags
}

resource "aws_eks_addon" "ebs-csi-driver" {
  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"
  tags         = var.tags
}

resource "kubernetes_storage_class" "default" {
  depends_on = [aws_eks_addon.ebs-csi-driver]

  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "kubernetes.io/aws-ebs"
  reclaim_policy      = "Delete"
  parameters = {
    "fsType" = "ext4"
    "type"   = "gp3"
  }
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
}

module "vpc-endpoints-guard-duty" {
  source                = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version               = "5.13.0"
  create_security_group = true
  security_group_name   = "vpc-endpoints-guard-duty-${var.cluster_name}"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
  vpc_id     = var.vpc_id

  endpoints = {
    guardduty-data = {
      service_name        = "com.amazonaws.us-east-1.guardduty-data"
      policy              = data.aws_iam_policy_document.restrict-vpc-endpoint-usage.json
      private_dns_enabled = true
      tags                = merge({ Name = "com.amazonaws.us-east-1.guardduty-data" }, var.tags)
    },
  }

}

resource "aws_iam_policy" "guardduty_agent_policy" {
  name        = "${var.cluster_name}-guardduty-agent-policy"
  description = "IAM policy for the GuardDuty EKS Runtime Monitoring agent."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:DescribeCluster"
        ],
        Resource = data.aws_eks_cluster.cluster.arn
      },
      {
        Effect = "Allow",
        Action = [
          "guardduty:SendSecurityTelemetry"
        ],
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role" "guardduty_agent_role" {
  name = "${var.cluster_name}-guardduty-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.eks.arn
        }
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:amazon-guardduty:aws-guardduty-agent"
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}


resource "aws_iam_role_policy_attachment" "guardduty_agent_attachment" {
  policy_arn = aws_iam_policy.guardduty_agent_policy.arn
  role       = aws_iam_role.guardduty_agent_role.name
}


resource "aws_eks_addon" "aws-guardduty" {
  cluster_name                = var.cluster_name
  addon_name                  = "aws-guardduty-agent"
  addon_version               = "v1.11.0-eksbuild.4"
  resolve_conflicts_on_update = "OVERWRITE"
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.guardduty_agent_role.arn
  tags                        = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.guardduty_agent_attachment
  ]
}