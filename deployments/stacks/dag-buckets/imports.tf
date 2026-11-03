# Adopts buckets that another stack created, without recreating them. Each address is
# imported once; on later runs the import is a no-op. The buckets in import_buckets
# must be public, because their public access resources are imported too
locals {
  import_buckets = toset(local.env.import_buckets)
}

import {
  for_each = local.import_buckets
  to       = module.bucket[each.key].aws_s3_bucket.bucket
  id       = each.key
}

import {
  for_each = local.import_buckets
  to       = module.bucket[each.key].aws_s3_bucket_versioning.versioning
  id       = each.key
}

import {
  for_each = local.import_buckets
  to       = module.bucket[each.key].aws_s3_bucket_ownership_controls.ownership[0]
  id       = each.key
}

import {
  for_each = local.import_buckets
  to       = module.bucket[each.key].aws_s3_bucket_public_access_block.access_block[0]
  id       = each.key
}

import {
  for_each = local.import_buckets
  to       = module.bucket[each.key].aws_s3_bucket_acl.bucket_acl[0]
  id       = "${each.key},public-read"
}

import {
  for_each = local.import_buckets
  to       = module.bucket[each.key].aws_s3_bucket_policy.my_bucket_policy[0]
  id       = each.key
}

import {
  for_each = local.import_buckets
  to       = module.bucket[each.key].aws_s3_bucket_cors_configuration.cors[0]
  id       = each.key
}
