module "ocean-controller" {
  source = "spotinst/ocean-controller/spotinst"
  version = "0.54.0"

  # Credentials.
  spotinst_token   = data.aws_secretsmanager_secret_version.secret_credentials.secret_string
  spotinst_account = var.spotinst_account

  # Configuration.
  cluster_identifier = var.cluster_name
}

resource "aws_iam_role" "work_profile_iam_role" {
  name = "work_profile_iam_role_${var.cluster_name}"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EKSNodeAssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  })

  tags = var.tags
}


# resource "aws_iam_role_policy_attachment" "a1" {
#   role       = aws_iam_role.work_profile_iam_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicy"
# }

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
  name = "aws_eks_profile_${var.cluster_name}"
  role = aws_iam_role.work_profile_iam_role.name
}

resource "aws_eks_access_entry" "example" {
  cluster_name      = var.cluster_name
  principal_arn     = aws_iam_instance_profile.profile.arn
  kubernetes_groups = ["system:nodes"]
  type              = "EC2_LINUX"
}

module "ocean-aws-k8s" {
  source  = "spotinst/ocean-aws-k8s/spotinst"
  version = "1.2.0"
  # worker_instance_profile_arn      = "arn:aws:iam::766808016710:role/airflow-node-group-eks-node-group-20240517054613935800000001"

  # Configuration
  cluster_name                     = var.cluster_name
  region                           = var.region
  subnet_ids                       = data.aws_subnets.private.ids
  worker_instance_profile_arn      = aws_iam_instance_profile.profile.arn
  security_groups                  = [data.aws_security_group.eks_node_security_group.id]
  is_aggressive_scale_down_enabled = true
  max_scale_down_percentage        = 33
  tags                             = var.tags
}
