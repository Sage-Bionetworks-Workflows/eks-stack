# Purpose
The purpose of this deployment stack is to manage all IDP (Identity Provider) settings.

## Initial setup per tenant
For each tenant in Auth0 a number of settings will be required to setup in order to
access the management API.

1. Access the newly created tenant in the Auth0 UI
2. Create a new "Machine to Machine" application named "Spacelift/OpenTofu access to management API"
3. Select the "Auth0 Management API" under "Authorized Machine to Machine Application"
4. Select all Permissions
5. From the newly created Application copy the "Client ID" and "Client Secret"
6. Create environment variables in the Spacelift UI for the stack that will be managing this tenant.
7. The following environment variables should be set:

* TF_VAR_auth0_client_id
* TF_VAR_auth0_client_secret - Set this as "SECRET"
* TF_VAR_auth0_domain

By setting the above environment variables and running the stack everything should be
setup according to the stack resources requested.

## Handing out credentials created by this process
This stack is creating a number of clients for various automated processes to 
authenticate themselves when sending data to the DPE kubernetes cluster. After the
stack has ran the handout of these credentials should occur over LastPass:

1) Create a new item in LastPass and set a useful name such as "Client/Secret to export telemetry data (DEV)"
2) Retrieve the "Client ID" and "Client Secret" from the "Application" in the Auth0 UI
3) Share the item in LastPass to the users requesting the credentials

Once the user has the requested credentials they will need to make sure that all
requests sent to the DPE kubernetes cluster contain a Bearer token in the 
"Authorization" header of the HTTP request. The following document describes the process
that an application would follow to exchange the "Client ID" and "Client Secret" for
the access token: <https://auth0.com/docs/get-started/authentication-and-authorization-flow/client-credentials-flow>.