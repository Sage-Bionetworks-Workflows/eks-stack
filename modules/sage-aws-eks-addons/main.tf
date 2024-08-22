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

resource "aws_eks_addon" "efs-csi-driver" {
  cluster_name = var.cluster_name
  addon_name   = "aws-efs-csi-driver"
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

resource "aws_security_group" "inbound efs" {
  name        = "${var.cluster_name}-inbound-efs"
  description = "Security group for EFS traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "TCP"
    cidr_blocks = [var.vpc_cidr_block]
    description = "Allow inbound NFS traffic from CIDR to cluster VPC"
  }

}

# resource "kubernetes_storage_class" "efs" {
#   depends_on = [aws_eks_addon.efs-csi-driver]

#   metadata {
#     name = "efs"
#     annotations = {
#       "storageclass.kubernetes.io/is-default-class" = "false"
#     }
#   }

#   storage_provisioner = "efs.csi.aws.com"
#   reclaim_policy      = "Delete"
#   parameters = {
#     "fsType" = "ext4"
#     "type"   = "gp3"
#   }
#   volume_binding_mode    = "WaitForFirstConsumer"
#   allow_volume_expansion = true
# }

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

data "aws_iam_policy_document" "restrict-vpc-endpoint-usage" {
  statement {
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:Principal"
      values   = [var.aws_account_id]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}


resource "aws_eks_addon" "aws-guardduty" {
  cluster_name = var.cluster_name
  addon_name   = "aws-guardduty-agent"
  tags         = var.tags
}
