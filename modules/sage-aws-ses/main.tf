resource "aws_ses_email_identity" "identities" {
  for_each = { for identity in var.email_identities : identity => identity }
  email = each.value
}

resource "aws_ses_domain_identity" "identities" {
  for_each = { for identity in var.email_domains : identity => identity }
  domain = each.value
}