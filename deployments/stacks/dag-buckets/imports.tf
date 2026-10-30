# Adopts buckets that another stack created, without recreating them. Each address is
# imported once; on later runs the import is a no-op. The buckets in var.import_buckets
# must be public, because their public access resources are imported too
locals {
  import_buckets = toset(var.import_buckets)
}

import {
  for_each = local.import_buckets
  to       = aws_s3_bucket.bucket[each.key]
  id       = each.key
}

import {
  for_each = local.import_buckets
  to       = aws_s3_bucket_versioning.versioning[each.key]
  id       = each.key
}

import {
  for_each = local.import_buckets
  to       = aws_s3_bucket_ownership_controls.ownership[each.key]
  id       = each.key
}

import {
  for_each = local.import_buckets
  to       = aws_s3_bucket_public_access_block.access_block[each.key]
  id       = each.key
}

import {
  for_each = local.import_buckets
  to       = aws_s3_bucket_acl.acl[each.key]
  id       = "${each.key},public-read"
}

import {
  for_each = local.import_buckets
  to       = aws_s3_bucket_policy.public_read[each.key]
  id       = each.key
}

import {
  for_each = local.import_buckets
  to       = aws_s3_bucket_cors_configuration.cors[each.key]
  id       = each.key
}
