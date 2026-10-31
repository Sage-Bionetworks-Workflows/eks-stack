# Values that more than one stack reads. A stack that sources this module lists
# deployments/config/*.tf in its additional_project_globs, so a change here plans every stack
# that reads it

# S3 buckets the orca-recipes DAGs write to, keyed by deployment_environment. Created by
# deployments/stacks/dag-buckets and granted to the MWAA execution role of the same
# environment by deployments/stacks/mwaa
output "dag_buckets" {
  description = "Buckets keyed by deployment_environment, then by bucket name. public = true makes the objects readable by anyone and allows browser GETs (CORS)"
  value = {
    # Dev buckets are private
    dev = {
      "synapse-croissant-metadata-dev"         = { public = false }
      "synapse-croissant-metadata-minimal-dev" = { public = false }
    }
    # Public: Google and the Synapse web client read the croissant files
    prod = {
      "synapse-croissant-metadata"         = { public = true }
      "synapse-croissant-metadata-minimal" = { public = true }
    }
  }
}
