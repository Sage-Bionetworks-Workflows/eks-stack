# Purpose
The purpose of this module is to deploy the `Cloudnative PG` helm chart <https://github.com/cloudnative-pg/charts/tree/main>.
This will deploy both the operator and a database cluster.


Future work:

- Since each microservice/application is meant to recieve it's own database the deployment model within this module should be changed slightly to install the operator at a cluster level, with each application having its own database.



# How many databases??

From their documentation:

"Our recommendation is to dedicate a single PostgreSQL cluster (intended as primary and multiple standby servers) to a single database, entirely managed by a single microservice application."