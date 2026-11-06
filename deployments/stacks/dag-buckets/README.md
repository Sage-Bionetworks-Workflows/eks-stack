# DAG buckets

This stack makes the S3 buckets that the orca-recipes DAGs write their output to. An example is the croissant files from `synapse-dataset-to-croissant.py`. These buckets do not hold DAG code. The MWAA bucket (`<mwaa_name>-s3`) holds the DAG code.

The buckets are not in the MWAA stack. This keeps the buckets and their data when you remove Airflow.

`deployments/spacelift/dag-buckets` makes one stack for each account:

| Stack | Account | Bucket list |
|---|---|---|
| DPE DEV DAG Buckets | DNT dev | `dag_buckets.dev` in `deployments/config/outputs.tf` |
| DPE PROD DAG Buckets | DPE prod | `dag_buckets.prod` in `deployments/config/outputs.tf` |

The MWAA stack in the same account gives its execution role access to the same buckets. The role can list each bucket, and read, write and delete objects (`dag_s3_buckets` in `modules/mwaa`).

## Add a bucket for a new DAG

1. Add the bucket to `dev` and to `prod` in the `dag_buckets` output of `deployments/config/outputs.tf`.
2. Give the dev bucket the suffix `-dev`.
3. Set `public = true` only if people outside Sage must read the objects. Otherwise, set `public = false`.
4. Merge the pull request. The change to `deployments/config` starts a DAG Buckets run and a Managed Airflow run in each account.
5. In each account, confirm the DAG Buckets run first. Then confirm the Managed Airflow run.
6. In the DAG, write to S3 with `S3Hook(aws_conn_id=None)`. The hook then uses the MWAA execution role.
7. Choose the bucket name with `by_environment(dev=..., prod=...)` from `dags/src/environment.py` in orca-recipes.
