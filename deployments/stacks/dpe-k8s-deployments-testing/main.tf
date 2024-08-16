module "postgres-cloud-native" {
  # source       = "spacelift.io/sagebionetworks/postgres-cloud-native/aws"
  source = "../../../modules/postgres-cloud-native/"
  # version      = "0.2.1"
  auto_deploy  = true
  auto_prune   = true
  git_revision = "ibcdpe-1004-airflow-ops"
}
