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
