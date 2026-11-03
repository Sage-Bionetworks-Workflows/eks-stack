# S3 buckets that the orca-recipes DAGs write to, listed in deployments/config. Kept out of
# the EKS and MWAA stacks so the buckets and their data outlive the Airflow deployment.
# Managed by deployments/spacelift/dag-buckets. The MWAA execution role is granted access to
# them in modules/mwaa (dag_s3_buckets)

# Public buckets: anyone can read the objects, and browsers can fetch them (CORS). Other
# buckets keep the S3 defaults, which block public access
module "bucket" {
  for_each = local.buckets
  source   = "../../../modules/s3-bucket"

  bucket_name   = each.key
  public_access = each.value.public
  enable_cors   = each.value.public
}
