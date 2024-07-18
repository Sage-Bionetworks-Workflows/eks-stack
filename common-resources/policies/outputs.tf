output "enforce_tags_on_resources_id" {
  value       = spacelift_policy.enforce-tags-on-resources.id
  description = "The ID for this spacelift_policy. Checks that a cost center tag is added."
}

output "check_estimated_cloud_spend_id" {
  value       = spacelift_policy.cloud-spend-estimation.id
  description = "The ID for this spacelift_policy"
}

output "drift_detection_warning_id" {
  value       = spacelift_policy.drift-detection-warning.id
  description = "The ID for this spacelift_policy"
}
