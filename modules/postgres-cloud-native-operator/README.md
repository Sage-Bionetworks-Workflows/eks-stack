# Purpose
The purpose of this module is to deploy the `Cloudnative PG` helm chart <https://github.com/cloudnative-pg/charts/tree/main>.
This will deploy both the operator.

The `database` deployment is a part of another module. This allows us to add a single
operator to a cluster and deploy 1 or more databases to that cluster.


## Future work to expand the capabilities
- Setting up backups to S3: https://cloudnative-pg.io/documentation/current/backup/
- Moving to database only node groups: https://cloudnative-pg.io/documentation/current/architecture/#postgresql-architecture
- Assign database persistent volumes to an expandable storage class


Reading:
- https://www.cncf.io/blog/2023/09/29/recommended-architectures-for-postgresql-in-kubernetes/
  - "The next level is to separate the Kubernetes worker nodes for PostgreSQL workloads from the other workloads’, using Kubernetes’ native scheduling capabilities, such as affinity, anti-affinity, node selectors and taints. You’ll still insist on the same storage, but you can get more predictability in terms of CPU and memory usage."
- Assign database persistent volumes to an expandable storage class
  - https://kubernetes.io/blog/2018/07/12/resizing-persistent-volumes-using-kubernetes/


# How many databases should I use?

From their documentation:

"Our recommendation is to dedicate a single PostgreSQL cluster (intended as primary and multiple standby servers) to a single database, entirely managed by a single microservice application."