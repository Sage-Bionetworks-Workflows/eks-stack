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

  inline_policy {
    name = "allow-eks-logs"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:DescribeLogGroups",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }

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

resource "aws_iam_role_policy_attachment" "a6" {
  role       = aws_iam_role.work_profile_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
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

resource "helm_release" "ocean-kubernetes-controller" {
  name             = "ocean-kubernetes-controller"
  repository       = "https://charts.spot.io"
  chart            = "ocean-kubernetes-controller"
  namespace        = "spot-system"
  version          = "0.1.52"
  create_namespace = true

  values = [templatefile("${path.module}/templates/values.yaml", {})]

  set {
    name  = "spotinst.token"
    value = data.aws_secretsmanager_secret_version.secret_credentials.secret_string
  }

  set {
    name  = "spotinst.account"
    value = var.spotinst_account
  }

  set {
    name  = "spotinst.clusterIdentifier"
    value = var.cluster_name
  }
}


module "ocean-aws-k8s" {
  source  = "spotinst/ocean-aws-k8s/spotinst"
  version = "1.4.0"

  # Configuration
  cluster_name                     = var.cluster_name
  region                           = var.region
  subnet_ids                       = var.private_vpc_subnet_ids
  worker_instance_profile_arn      = aws_iam_instance_profile.profile.arn
  security_groups                  = [var.node_security_group_id]
  is_aggressive_scale_down_enabled = true
  max_scale_down_percentage        = 33
  tags                             = var.tags
  # TODO: Fix this it does not seem to work
  # `desired_capacity` does not seem to force the number of nodes to increase. Look
  # through the documentation to determine how we might manually scale up the number
  # of nodes if we wanted to.
  desired_capacity = var.desired_capacity


  filters = {
    exclude_metal = true
    hypervisor    = ["nitro"]

    architectures           = null
    categories              = null
    disk_types              = null
    exclude_families        = null
    include_families        = null
    is_ena_supported        = null
    max_gpu                 = null
    max_memory_gib          = null
    max_network_performance = null
    max_vcpu                = null
    min_enis                = null
    min_gpu                 = null
    min_memory_gib          = 8
    min_network_performance = null
    min_vcpu                = 2
    root_device_types       = null
    virtualization_types    = null
  }
}
