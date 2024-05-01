# EKS-stack

Leveraging spot.io, we spin up an EKS stack behind an existing private VPC that has scale-to-zero capabilities. To deploy this stack

1. log into dpe-prod via jumpcloud and export the credentials (you must have admin)
2. run `terraform apply`
3. This will deploy the terraform stack.  The terraform backend state is stored in an S3 bucket.  The terraform state is stored in the S3 bucket `s3://dpe-terraform-bucket`
4. The spot.io account token is stored in AWS secrets manager: `spotinst_token`


## Future work

1. Create a separate VPC dedicated to the K8 cluster
2. Create CI/CD to deploy this stack
3. Push this entire stack behind a module
4. Create a module for the node groups so we can attach node groups to EKS cluster
