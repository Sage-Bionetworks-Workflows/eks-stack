# DAG buckets

This stack makes the S3 buckets that the orca-recipes DAGs write their output to. An example is the croissant files from `synapse-dataset-to-croissant.py`. These buckets do not hold DAG code. The MWAA bucket (`<mwaa_name>-s3`) holds the DAG code.

The buckets are not in the EKS or MWAA stacks. This keeps the buckets and their data when you remove Airflow.

`deployments/spacelift/dag-buckets` makes one stack for each account:

| Stack | Account | Bucket list |
|---|---|---|
| DPE DEV DAG Buckets | DNT dev | `dag_buckets_development` in `deployments/main.tf` |
| DPE PROD DAG Buckets | DPE prod | `dag_buckets_production` in `deployments/main.tf` |

The MWAA stack in the same account gives its execution role access to the same buckets. The role can list each bucket, and read, write and delete objects (`dag_s3_buckets` in `modules/mwaa`).

## Add a bucket for a new DAG

1. Add the bucket to `dag_buckets_development` and to `dag_buckets_production` in `deployments/main.tf`.
2. Give the dev bucket the suffix `-dev`.
3. Set `public = true` only if people outside Sage must read the objects. Otherwise, set `public = false`.
4. Merge the pull request. The admin stack then changes the inputs of the DAG Buckets and Managed Airflow stacks.
5. In each account, confirm the DAG Buckets run first. Then confirm the Managed Airflow run.
6. In the DAG, write to S3 with `S3Hook(aws_conn_id=None)`. The hook then uses the MWAA execution role.
7. Choose the bucket name with `by_environment(dev=..., prod=...)` from `dags/src/environment.py` in orca-recipes.
