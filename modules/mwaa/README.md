# Contents

- [Purpose](#purpose)
- [Usage](#usage)
- [Accessing the Airflow UI](#accessing-the-airflow-ui)
- [Airflow connections and variables](#airflow-connections-and-variables)
- [Troubleshooting](#troubleshooting)
  - [DAG uploaded to S3 does not appear in the Airflow UI](#dag-uploaded-to-s3-does-not-appear-in-the-airflow-ui)
  - [`ModuleNotFoundError` in a task for a package listed in requirements.txt](#modulenotfounderror-in-a-task-for-a-package-listed-in-requirementstxt)
  - [MWAA stack run fails reading requirements.txt](#mwaa-stack-run-fails-reading-requirementstxt)
  - [A new requirements.txt was uploaded but not installed](#a-new-requirementstxt-was-uploaded-but-not-installed)
  - [Changing `airflow_version` fails](#changing-airflow_version-fails)
  - [Root stack changes for MWAA are not deployed from a feature branch](#root-stack-changes-for-mwaa-are-not-deployed-from-a-feature-branch)

# Purpose

Deploys an Amazon Managed Workflows for Apache Airflow (MWAA) environment. It is a thin
wrapper around [cloudposse/mwaa/aws](https://search.opentofu.org/module/cloudposse/mwaa/aws/latest),
which also creates the S3 bucket for DAGs, the execution IAM role, and the security group.

# Usage

```terraform
module "mwaa" {
  source     = "../../../modules/mwaa"
  enabled    = true
  name       = "mwaa-dev"
  region     = var.region
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
}
```

`enabled` defaults to `false` so the module can be wired up before any AWS resources exist.
While it is `false` nothing is created and `vpc_id`/`subnet_ids` may be left unset.

MWAA requires exactly two private subnets in different availability zones. DAGs are read from
the `dags/` prefix of the bucket created by this module. New or changed DAG files take a few
minutes to appear in the Airflow UI.

# Accessing the Airflow UI

The web server uses `PUBLIC_ONLY` access: the URL is reachable from the internet.

1. Log into the AWS Console for the account the environment is deployed to (dev uses the
   `org_sagebase_dnt_dev` account and that is the only one currently available) via JumpCloud.
2. Open **Amazon MWAA** → **Environments** in `us-east-1`, select the environment `synapse-mwaa-dev` for dev and click **Open Airflow UI**.

# Airflow connections and variables

Airflow reads connections and variables from AWS Secrets Manager in the same account and region
as the environment:

| Airflow lookup | Secret name |
| --- | --- |
| Connection `<conn_id>` | `airflow/connections/<conn_id>` |
| `Variable.get("<name>")` | `airflow/variables/<name>` |

Anything not found in Secrets Manager falls back to the values added in the Airflow UI under
**Admin** → **Connections** / **Variables**. See [Secrets](https://github.com/Sage-Bionetworks-Workflows/orca-recipes/blob/main/CONTRIBUTING.md#secrets) for details on adding / modifying our current secrets in the AWS accounts.

# Troubleshooting

See AWS's MWAA troubleshooting page first for [common troubleshooting issues](https://docs.aws.amazon.com/mwaa/latest/userguide/t-apache-airflow-202.html#access-secrets-manager)

Start by checking the environment's state:

```bash
aws mwaa get-environment --region us-east-1 --name synapse-mwaa-dev \
  --query 'Environment.{status:Status,mode:WebserverAccessMode,url:WebserverUrl,airflow:AirflowVersion,reqPath:RequirementsS3Path,reqVersion:RequirementsS3ObjectVersion,lastUpdate:LastUpdate}'
```

Logs are in CloudWatch under the `airflow-<name>-Scheduler`, `-Worker` and `-Task` log groups.

## DAG uploaded to S3 does not appear in the Airflow UI

MWAA syncs the `dags/` prefix and re-scans it periodically, so new or changed files take a few
minutes to show up. If a DAG is still missing after that:

- Check the red **DAG Import Errors** banner at the top of the DAGs page. A DAG whose imports fail
  is not listed, and the banner shows the traceback.
- `No module named 'src'` (or another folder of shared helpers): the folder is missing from the
  bucket. The `dags/` folder is on `sys.path`, so `from src.x import y` needs
  `s3://<bucket>/dags/src/x.py`, including for DAGs in subfolders of `dags/`.
- `No module named '<package>'`: the package is not installed. See
  [`ModuleNotFoundError`](#modulenotfounderror-in-a-task-for-a-package-listed-in-requirementstxt).


## `ModuleNotFoundError` in a task for a package listed in requirements.txt

MWAA has not installed the file. Check `reqPath`:

- **`null`**: MWAA was never told about the file. The value reaches the MWAA stack as
  `TF_VAR_requirements_s3_path`, which is written by the root admin stack. If the change to
  `deployments/main.tf` is only on a feature branch, the root stack (which tracks `main`) has not
  applied it. Check the MWAA stack's **Environment** tab in Spacelift for the variable, then
  re-run the MWAA stack. Its plan should show `requirements_s3_path` changing from `null`.
- **Set**: the install failed. MWAA keeps running with the previous requirements. The pip error
  is in the `requirements_install_*` stream of the Scheduler log group.

## MWAA stack run fails reading requirements.txt

The `aws_s3_object` lookup fails if `requirements_s3_path` is set before the file exists. Upload
the file to the bucket first, then re-run the stack.

## A new requirements.txt was uploaded but not installed

The latest version of the file is only picked up when the MWAA stack runs. Trigger it after
uploading. The environment update takes 20–30 minutes.

## Root stack changes for MWAA are not deployed from a feature branch

The root admin stack tracks `main`. If run promotion is not available, the root stack's branch
can be pointed at the feature branch temporarily to be deployed with changes from the feature branch.
