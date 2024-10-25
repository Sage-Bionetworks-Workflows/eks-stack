import {
  to = aws_ses_email_identity.identities[0]
  id = "aws-dpe-dev@sagebase.org"
}

import {
  to = aws_ses_email_identity.identities[1]
  id = "bryan.fauble@sagebase.org",
}

import {
  to = aws_ses_domain_identity.identities[0]
  id = "sagebase.org",
}

resource "aws_ses_email_identity" "identities" {
  for_each = { for identity in var.email_identities : identity => identity }
  email = each.value
}

resource "aws_ses_domain_identity" "identities" {
  for_each = { for identity in var.email_domains : identity => identity }
  domain = each.value
}