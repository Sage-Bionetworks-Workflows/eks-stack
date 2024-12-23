# Purpose
The purpose of this module is to deploy the `Signoz` helm chart <https://github.com/SigNoz/charts/tree/main/charts/signoz>.

SigNoz is an open-source APM. It helps developers monitor their applications 
& troubleshoot problems, an open-source alternative to DataDog, NewRelic, etc. Open 
source Application Performance Monitoring (APM) & Observability tool.

## Initial setup

- Accounts in SigNoz need to be manually set up (SSO is only available in the enterprise version)
- 120 months for "Total Retention Period" and 1 month for "Move to S3" settings should be set
- Any dashboards need to be copied or set up
- Alert channels (Email/Slack) need to be set

## Setting up SMTP for alertmanager
Alertmanager is an additional tool that is deployed to the kubernetes cluster that
handles forwarding an alert out to 1 or more streams that will receive the alert.
Alert manager is set to to send emails through AWS SES (Simple Email Service) set up
by the `modules/sage-aws-ses` terraform scripts. See that module for more information
about the setup of AWS SES.

## Accessing signoz (Internet)

#### Sending data into signoz (From internet)
When SigNoz is deployed with the terraform variables `enable_otel_ingress` and `gateway_namespace`
set, an HTTP route to the openTelemetry collector will be exposed out to the internet.
Using the defined URL a user may send telemetry data via HTTPS and a Bearer auth token
into the cluster. To accomplish this the sender of the data will need to configure
the sending application with the appropriate HTTPS url and authentication (Different 
depending on the sender). The paths to send data to will be as follows:

- `/telemetry/v1/traces`
- `/telemetry/v1/metrics`
- `/telemetry/v1/logs`


Un-authenticated requests will be rejected with an HTTP 401.

#### Authentication
Authentication for data being sent into the cluster will occur via a JWT Bearer token.
As the sender, you will be required to ensure that every request sent has an unexpired
and valid token. The exact mechanism for attaching this authentication will change
depending on how data is forwarded into the cluster. For example if using an
open-telemetry collector you may use this oauth2 extension:
<https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/extension/oauth2clientauthextension>.

##### Authentication from Python application directly
If you are sending data directly from an application into the cluster you may specify
an environment variable with headers to attach to the requests by setting:
`OTEL_EXPORTER_OTLP_HEADERS=Authorization=Bearer ...`

> [!NOTE]
> This method is only a temporary solution as Bearer tokens will expire and need to be rotated.

Future work would be to determine if we may be able to implement the usage of 
<https://pypi.org/project/requests-oauth2client/> to handle automatic token fetching
using a client ID/Client secret using Auth0 (Or related IDP).


## Accessing signoz (Port-forwarding)
This guide is for those that have access to the kubernetes cluster and are using 
port-fowarding to access the data in the cluster.

### Pre-req
This assumes that you have accessed the k8s cluster before using `k9s` or another tool.
If you have not, read over this documentation:

- <https://sagebionetworks.jira.com/wiki/spaces/DPE/pages/3389325317/Connecting+to+AWS+EKS+Kubernetes+K8s+cluster>
- Description of port-forwarding via `k9s`: <https://github.com/Sage-Bionetworks-Workflows/eks-stack/blob/main/docs/workshop-hello-world.md#verifying-your-deployed-resources-on-the-kubernetes-cluster>

### Connecting to signoz
After signoz has been deployed to the k8s cluster you will need to port-forward to 2
pods/services:

- `signoz-frontend`
- `signoz-otel-collector`

The frontend is how you'll access all of the data contained within signoz. Once you
port forward and access it via your web-browser you'll need to signup and login. 
TODO: The steps on this are not fleshed out, this is going to be a manual step that the
admin of the server will need to help you with.


#### Sending data into signoz
Once you find the `signoz-otel-collector` you'll need to start a port-forward session in
order to pass data along to it from your local machine. Here are the settings you'll use
for the port-forward:

Windows/Linux:
```
Container Port: collector/otlp:4317,collector/otlp-http:4318
Local Port:     4317,4318
```

Mac:
```
Container Port: collector::4317,collector::4318
Local Port:     4317,4318
```

Some data will be present in those fields by default, delete what is there and copy the
above data into it.

### Application side
Once you're connected via a port-forward session the next item is to make sure that the
application you're sending data from is instrumented with open-telemetry. This is going
to be application specific so instructions will need to live within the application
you are using.

### Clickhouse Backups and Restores
This module uses the `clickhouse-backup` tool to automatically back up the clickhouse database and store the data in an S3 bucket to ensure continuity of the data regardless of the state of the cluster.`clickhouse-backup` is deployed as a sidecar container to the `signoz` helm release. It will perform incremental backups of the database every 8 hours and full backups every 24 hours.

To restore the database from an S3 backup, you can use the following steps:
1. Scale the replica cluster (`chi-signoz-clickhouse-cluster-0-1`) `StatefulSet` to 0 replicas.
1. Identify the backup that you would like to restore from. You can get the full list of backups by shelling into the `clickhouse-backup-sidecar` container within the `chi-signoz-clickhouse-cluster-0-0-0` pod and running `clickhouse-backup list`.
1. Restore the database from your backup by running `clickhouse-backup restore_remote --rm --schema <backup-name>` (assuming the backup from remote storage).
1. Scale the replica cluster `StatefulSet` back to 1 replica. Once the `chi-signoz-clickhouse-cluster-0-1-0` has fully come back up, you should see the restored data showing in the `signoz` UI.
