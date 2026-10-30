variable "region" {
  description = "AWS region the buckets are created in"
  type        = string
  default     = "us-east-1"
}

variable "buckets" {
  description = "Buckets to manage, keyed by bucket name. public = true makes the objects readable by anyone and allows browser GETs (CORS)"
  type = map(object({
    public = bool
  }))
}

variable "import_buckets" {
  description = "Names of existing public buckets in var.buckets to import into this stack, for example from the dpe-k8s stack"
  type        = list(string)
  default     = []
}
