# Purpose
The purpose of this module is to deploy the `Signoz` helm chart <https://github.com/SigNoz/charts/tree/main/charts/signoz>.

SigNoz is an open-source APM. It helps developers monitor their applications 
& troubleshoot problems, an open-source alternative to DataDog, NewRelic, etc. Open 
source Application Performance Monitoring (APM) & Observability tool.


## This module is a work in progress
This was hastly thrown together to get a tool available to ingest telemetry data in.
A number of items are needed:

- Updating the clickhouse install to cluster mode, and potentially this operator: https://github.com/Altinity/clickhouse-operator
- Setting up backups and data retention
- Trim down the number of ports available in the service
- Double check the entire `values.yaml` file
- Set up accounts and access to the service decleratively

## Accessing signoz

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

Some data will be present in those fields by default, delete was is there and copy the
above data into it.

### Application side
Once you're connected via a port-forward session the next item is to make sure that the
application you're sending data from is instrumented with open-telemetry. This is going
to be application specific so instructions will need to live within the application
you are using.
