# Purpose
This module is used to set up SES (Simple email service) in AWS.

By setting a few variables we are able to create a number of Email addresses and Domains
to AWS SES. The variables to be set are:

- `email_identities`, example: `["example@sagebase.org"]`
- `email_domains`, example `["sagebase.org"]`

# Manual steps required
After running this module a number of manual steps are required as they are external
processes that need to happen:

## Verify Email address
1) Navigate to Amazon SES in the web console
2) Navigate to `identities`
3) Choose the Identity to verify
4) Send a test email and click the link recieved to verify the email

Optional: Send a test email after verifying to confirm you may recieve emails


## Verify Sending domain
This is required for each AWS account where AWS SES is going to be set up.

Reading: <https://docs.aws.amazon.com/ses/latest/dg/creating-identities.html#just-verify-domain-proc>

1) Navigate to Amazon SES in the web console
2) Navigate to `identities`
3) Choose the Domain to verify
4) Download the DKIM under `Publish DNS records` and create an IT ticket to add the records
5) Example IT ticket for reference: <https://sagebionetworks.jira.com/browse/IT-3965>
