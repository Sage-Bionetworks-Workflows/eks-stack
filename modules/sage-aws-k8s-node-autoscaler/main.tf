resource "aws_iam_role" "work_profile_iam_role" {
  name = "work_profile_iam_role_${var.cluster_name}"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "EKSNodeAssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}


resource "aws_iam_role_policy_attachment" "a1" {
  role       = aws_iam_role.work_profile_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role_policy_attachment" "a2" {
  role       = aws_iam_role.work_profile_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "a3" {
  role       = aws_iam_role.work_profile_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "a4" {
  role       = aws_iam_role.work_profile_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "a5" {
  role       = aws_iam_role.work_profile_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_instance_profile" "profile" {
  name = "eks_profile_${var.cluster_name}"
  role = aws_iam_role.work_profile_iam_role.name
  tags = var.tags
}

resource "aws_eks_access_entry" "example" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.work_profile_iam_role.arn
  type          = "EC2_LINUX"
  tags          = var.tags
}

module "ocean-controller" {
  source  = "spotinst/ocean-controller/spotinst"
  version = "0.54.0"

  # Credentials.
  spotinst_token   = data.aws_secretsmanager_secret_version.secret_credentials.secret_string
  spotinst_account = var.spotinst_account

  # Configuration.
  cluster_identifier = var.cluster_name
}

module "ocean-aws-k8s" {
  source  = "spotinst/ocean-aws-k8s/spotinst"
  version = "1.2.0"

  # Configuration
  cluster_name                     = var.cluster_name
  region                           = var.region
  subnet_ids                       = var.private_vpc_subnet_ids
  worker_instance_profile_arn      = aws_iam_instance_profile.profile.arn
  security_groups                  = [var.node_security_group_id]
  is_aggressive_scale_down_enabled = true
  max_scale_down_percentage        = 33
  tags                             = var.tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name = var.cluster_name
  addon_name   = "coredns"
  tags         = var.tags

  depends_on = [
    module.ocean-controller,
    module.ocean-aws-k8s,
  ]
}

resource "aws_eks_addon" "ebs-csi-driver" {
  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"
  tags         = var.tags

  depends_on = [
    module.ocean-controller,
    module.ocean-aws-k8s,
  ]
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
