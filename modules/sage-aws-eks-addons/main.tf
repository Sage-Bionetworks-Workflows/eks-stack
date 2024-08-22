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

resource "aws_security_group" "inbound_efs" {
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

# TODO: Later on we should swap this to conditional creation, and only create if needed
# for the cluster the addon is being installed to.

# TODO: There is an issue with Apache airflow mounting this file system that will need
# to be resolved if moving forward with this:
# │ Events:                                                                                                                                                                                                                  
#    Type     Reason            Age                    From                                Message                                                                                                                          
#    ----     ------            ----                   ----                                -------                                                                                                                          
#    Warning  FailedScheduling  8m40s (x6 over 21m)    default-scheduler                   0/2 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/2 nodes are available: 2 Preemption is  
#  not helpful for scheduling.                                                                                                                                                                                              
#    Normal   Scheduled         8m30s                  default-scheduler                   Successfully assigned airflow/airflow-scheduler-69dfcd54f7-h9xrq to ip-10-51-5-6.ec2.internal                                    
#    Warning  FailedMount       2m2s (x11 over 8m28s)  kubelet, ip-10-51-5-6.ec2.internal  MountVolume.SetUp failed for volume "pvc-5ef89367-b727-4cbc-8cf3-ffe20c1b04c4" : rpc error: code = Internal desc = Could not mou 
#  nt "fs-0c874dbad71dead7a:/" at "/var/lib/kubelet/pods/56cef2f9-c960-4714-bf72-afbed60dc8e5/volumes/kubernetes.io~csi/pvc-5ef89367-b727-4cbc-8cf3-ffe20c1b04c4/mount": mount failed: exit status 1                        
#  Mounting command: mount                                                                                                                                                                                                  
#  Mounting arguments: -t efs -o accesspoint=fsap-0c837778140713548,tls fs-0c874dbad71dead7a:/ /var/lib/kubelet/pods/56cef2f9-c960-4714-bf72-afbed60dc8e5/volumes/kubernetes.io~csi/pvc-5ef89367-b727-4cbc-8cf3-ffe20c1b04c 
#  4/mount                                                                                                                                                                                                                  
#  Output: Failed to resolve "fs-0c874dbad71dead7a.efs.us-east-1.amazonaws.com". The file system mount target ip address cannot be found, please pass mount target ip address via mount options.                            
#  Cannot find mount target for the file system fs-0c874dbad71dead7a, please create a mount target in us-east-1b.                                                                                                           
#  Warning: config file does not have fips_mode_enabled item in section mount.. You should be able to find a new config file in the same folder as current config file /etc/amazon/efs/efs-utils.conf. Consider update the  
#  new config file to latest config file. Use the default value [fips_mode_enabled = False].Warning: config file does not have fips_mode_enabled item in section mount.. You should be able to find a new config file in th 
#  e same folder as current config file /etc/amazon/efs/efs-utils.conf. Consider update the new config file to latest config file. Use the default value [fips_mode_enabled = False].                                       
#    Warning  FailedMount  2m2s (x11 over 8m28s)  kubelet, ip-10-51-5-6.ec2.internal  MountVolume.SetUp failed for volume "pvc-34c5a694-5940-490d-9f6f-b0869e11dd8a" : rpc error: code = Internal desc = Could not mount "f 
#  s-0c874dbad71dead7a:/" at "/var/lib/kubelet/pods/56cef2f9-c960-4714-bf72-afbed60dc8e5/volumes/kubernetes.io~csi/pvc-34c5a694-5940-490d-9f6f-b0869e11dd8a/mount": mount failed: exit status 1                             
#  Mounting command: mount                                                                                                                                                                                                  
#  Mounting arguments: -t efs -o accesspoint=fsap-0650f383a69f702f6,tls fs-0c874dbad71dead7a:/ /var/lib/kubelet/pods/56cef2f9-c960-4714-bf72-afbed60dc8e5/volumes/kubernetes.io~csi/pvc-34c5a694-5940-490d-9f6f-b0869e11dd8 
#  a/mount                                                                                                                                                                                                                  
#  Output: Failed to resolve "fs-0c874dbad71dead7a.efs.us-east-1.amazonaws.com". The file system mount target ip address cannot be found, please pass mount target ip address via mount options.                            
#  Cannot find mount target for the file system fs-0c874dbad71dead7a, please create a mount target in us-east-1b.                                                                                                           
#  Warning: config file does not have fips_mode_enabled item in section mount.. You should be able to find a new config file in the same folder as current config file /etc/amazon/efs/efs-utils.conf. Consider update the  
#  new config file to latest config file. Use the default value [fips_mode_enabled = False].Warning: config file does not have fips_mode_enabled item in section mount.. You should be able to find a new config file in th 
#  e same folder as current config file /etc/amazon/efs/efs-utils.conf. Consider update the new config file to latest config file. Use the default value [fips_mode_enabled = False].    
resource "aws_efs_file_system" "efs-file-system" {
  creation_token  = "${var.cluster_name}-efs"
  encrypted       = true
  throughput_mode = "elastic"

  tags = var.tags
}

resource "kubernetes_storage_class" "efs" {
  depends_on = [aws_eks_addon.efs-csi-driver]

  metadata {
    name = "efs-sc"
  }

  storage_provisioner    = "efs.csi.aws.com"
  reclaim_policy         = "Delete"
  allow_volume_expansion = true

  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = aws_efs_file_system.efs-file-system.id
    directoryPerms   = "700"
  }
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
