# EKS-stack

Leveraging spot.io, we spin up an EKS stack behind an existing private VPC that has scale-to-zero capabilities. To deploy this stack

1. log into dpe-prod via jumpcloud and export the credentials (you must have admin)
2. run `terraform apply`
3. This will deploy the terraform stack.  The terraform backend state is stored in an S3 bucket.  The terraform state is stored in the S3 bucket `s3://dpe-terraform-bucket`
4. The spot.io account token is stored in AWS secrets manager: `spotinst_token`
5. Add `AmazonEBSCSIDriverPolicy` and `SecretsManagerReadWrite` to the IAM policy

```
aws eks update-kubeconfig --name tyu-spot-ocean
```

## Future work

1. Create a separate VPC dedicated to the K8 cluster
2. Create CI/CD to deploy this stack
3. Push this entire stack behind a module
4. Create a module for the node groups so we can attach node groups to EKS cluster


## Adding a node group (WIP)

1. Add an EKS node group

```
two = {
    name         = "seqera"
    desired_size = 1
    min_size     = 0
    max_size     = 10

    instance_types = ["t3.large"]
    capacity_type  = "SPOT"
}
```

2. Add an AWS IAM instance profile

```
data "aws_iam_instance_profiles" "profile2" {
  depends_on = [module.eks]
  role_name = module.eks.eks_managed_node_groups["two"].iam_role_name
}
```

3. Add an ocean virtual node group

```
module "ocean-aws-k8s-vng_gpu" {
    source = "spotinst/ocean-aws-k8s-vng/spotinst"

    name = "seqera"  # Name of VNG in Ocean
    ocean_id = module.ocean-aws-k8s.ocean_id
    subnet_ids = var.subnet_ids

    iam_instance_profile = tolist(data.aws_iam_instance_profiles.profile2.arns)[0]
    # instance_types = ["g4dn.xlarge","g4dn.2xlarge"] # Limit VNG to specific instance types
    # spot_percentage = 50 # Change the spot %
    tags = var.tags
}
```