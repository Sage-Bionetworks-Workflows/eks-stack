# Purpose
This is a simple module that can be used within applications to deploy an S3 bucket.

## WARNING
If you are tearing down a stack with a deployed S3 Bucket, you will likely encounter an error similar to the following:
```
deleting S3 Bucket (my-beautiful-bucket): operation error S3: DeleteBucket, https response error StatusCode: 409, RequestID: 123, HostID: 123456789+g=, api error BucketNotEmpty: The bucket you tried to delete is not empty. You must delete all versions in the bucket.
```
We have intentionally not handled this behavior as a safeguard against accidental deletion of a bucket that contains important data.

# Usage
Using this module is as simple as calling it in your terraform code:
```
module "my_beautiful_bucket" {
  source      = "../../../modules/s3-bucket"
  bucket_name = "my-beautiful-bucket"
}
```

You will need to configure access to the bucket. This will involve the definition of  `aws_iam_policy`, `aws_iam_role`, and `aws_iam_role_policy_attachment` resources with the necessary permissions for your use case. For example (from the `dpe-k8s-deployments` stack):
```
resource "aws_iam_policy" "my_beautiful_bucket_policy" {
  name        = "my-beautiful-bucket-access-policy"
  description = "Policy to access the my beautiful bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          module.my_beautiful_bucket.bucket_arn,
          "${module.my_beautiful_bucket.bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "my_beautiful_bucket_access" {
  name        = "my-beautiful-bucket-access-role"
  description = "Assumed role to access the my beautiful bucket"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "${var.cluster_oidc_provider_arn}",
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "my_beautiful_bucket_policy_attachment" {
  role       = aws_iam_role.my_beautiful_bucket_access.name
  policy_arn = aws_iam_policy.my_beautiful_bucket_policy.arn
}
```

After confirming that the policy and role are configured correctly, you will then need to configure a kubernetes service account bound to the IAM role. This can be done in your application/module code like so:
```
resource "kubernetes_service_account" "my_beautiful_bucket_service_account" {
  metadata {
    name      = "my-beautiful-bucket-service-account"
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::${var.aws_account_id}:role/my-beautiful-bucket-access-role"
    }
  }
}
```

Finally, you can leverage the newly created service account in your application code by setting `serviceAccountName` to the name of the service account you just created.
