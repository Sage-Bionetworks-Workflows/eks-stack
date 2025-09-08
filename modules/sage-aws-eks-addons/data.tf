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

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}
