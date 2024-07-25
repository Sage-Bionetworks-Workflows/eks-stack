# Purpose
This module is used to create helm release for spacelift private workers. It follows
the instructions outlined at <https://docs.spacelift.io/concepts/worker-pools/kubernetes-workers>.


Spacelift private workers are required in order to use `Drift Detection`. Documentation
on this: https://docs.spacelift.io/concepts/stack/drift-detection

Also to note: In order to use private workers you must have the enterprise plan of
spacelift where there is a charge for each private worker being used.


## Examples

When deploying the private workerpool a 2-step process is required (Unless more time is
spent to figure out a 1-step process). The process is as follows:

1) Add the module and deploy it to your stack with `create-worker-pool = false`
2) Change the bool to `true` and deploy again

The reason for this is that the `helm chart` that deploy this to the K8s cluster needs
to first install CRDs (Custom resource definitions) into the cluster. Once those are
created then we can create the resource definition for the worker pool that specifies
how many instances and with what settings to run the worker pool under.

```
module "spacelift-private-workerpool" {
  source       = "spacelift.io/sagebionetworks/spacelift-private-workerpool/aws"
  version      = "0.1.3"
  cluster_name = var.cluster_name
  # Deployment steps:
  # Deploy with this as false in order to create the K8s CRD
  # Create the required secrets
  # Deploy with this as true in order to create the workerpool
  create-worker-pool = false
}
```

## What is left for production
If this is going to be used for a production use case the secret management will need
to be revisited. The helm chart assumes that a kubernetes secret exists. Here is how
to create it with the kubectl CLI:

```
SPACELIFT_WP_TOKEN=<enter-token>
SPACELIFT_WP_PRIVATE_KEY=<enter-base64-encoded-key>

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: test-workerpool
type: Opaque
stringData:
  token: ${SPACELIFT_WP_TOKEN}
  privateKey: ${SPACELIFT_WP_PRIVATE_KEY}
EOF
```

We would likely want the secret to be stored in AWS secret manager and access via:
<https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_csi_driver.html>

