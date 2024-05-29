resource "spacelift_policy" "enforce-tags-on-resources" {
  name = "Enforce Tags On Resources - cli"
  body = file("${path.module}/enforce-tags-on-resources.rego")
  type = "PLAN"
  labels = ["compliance", "plan", "tagging", "terraform"]
  description = "This policy ensures that all Terraform-managed resources adhere to tagging conventions by requiring the presence of specific tags. It denies changes to resources that lack any of these required tags, emphasizing the importance of consistent tagging for resource identification, environment management, and ownership tracking. The policy aids in maintaining order, facilitating cost allocation, security, and governance across the infrastructure."
  space_id = "root"
}


resource "spacelift_policy" "cloud-spend-estimation" {
  name = "Cloud Spend Estimation - cli"
  body = file("${path.module}/check-estimated-cloud-spend.rego")
  type = "PLAN"
  space_id = "root"
}


