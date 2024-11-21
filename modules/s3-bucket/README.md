# Purpose
This is a simple module that can be used within applications to create an S3 bucket.

## WARNING
If you are tearing down a stack with a deployed S3 Bucket, you will likely encounter an error similar to the following:
```
deleting S3 Bucket (my-beautiful-bucket): operation error S3: DeleteBucket, https response error StatusCode: 409, RequestID: 123, HostID: 123456789+g=, api error BucketNotEmpty: The bucket you tried to delete is not empty. You must delete all versions in the bucket.
```
We have intentionally not handled this behavior as a safeguard against accidental deletion of a bucket that contains important data. If you need to delete the bucket, you will need to manually delete all objects within it. If versioning is enabled for the bucket, you will also need to delete all versions of the objects.

# Usage
Using this module only requires calling it in your terraform code:
```
module "my_beautiful_bucket" {
  source      = "../../../modules/s3-bucket"
  bucket_name = "my-beautiful-bucket"
  enable_versioning = false
  aws_account_id = var.aws_account_id
  cluster_name = var.cluster_name
  cluster_oidc_provider_arn = var.cluster_oidc_provider_arn
}
```

The module handles creating the necessary IAM policy, role, and role policy attachment for accessing the bucket and provides the role ARN as an output.

After confirming that the policy and role are configured correctly, you can either use the ARN directly in your application code or configure a kubernetes service account bound to the IAM role. The latter can be done like so:
```
resource "kubernetes_service_account" "my_beautiful_bucket_service_account" {
  metadata {
    name      = "my-beautiful-bucket-service-account"
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = "${module.my_beautiful_bucket.iam_role_arn}"
    }
  }
}
```
