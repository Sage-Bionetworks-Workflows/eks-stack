# Purpose
This module is used to set up SES (Simple email service) in AWS.

By setting a few variables we are able to create a number of Email addresses
to AWS SES. The variables to be set are:

- `email_identities`, example: `["example@sagebase.org"]`

# Manual steps required
After running this module a number of manual steps are required as they are external
processes that need to happen:

## Verify Email address
1) Navigate to Amazon SES in the web console
2) Navigate to `identities`
3) Choose the Identity to verify
4) Send a test email and click the link received to verify the email

Optional: Send a test email after verifying to confirm you may receive emails

# Request production access
After creating AWS SES settings the first time you will be in "Sandbox" mode. In order
to request production access follow the following document: <https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html>
under the section "To request that your account be removed from the Amazon SES sandbox using the AWS CLI".

The command will look something like:

```
aws sesv2 put-account-details \
--production-access-enabled \
--mail-type TRANSACTIONAL \
--website-url https://www.synapse.org/ \
--additional-contact-email-addresses dpe@sagebase.org \
--contact-language EN
```
