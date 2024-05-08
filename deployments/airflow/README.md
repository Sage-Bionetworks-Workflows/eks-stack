
### Airflow

Current deplopyment of Airflow: persistent t3a.xlarge.

To deploy Airflow on K8, lets use helm.

1. Create a web server secret

```
kubectl create secret generic airflow-webserver-secret --from-literal="webserver-secret-key=$(python3 -c 'import secrets; print(secrets.token_hex(16))')" -n airflow
```

2. Install Airflow (make sure you pull down the airflow repo first from helm).  The `Dockerfile` is pulled from [orca-recipes](https://github.com/Sage-Bionetworks-Workflows/orca-recipes) with a one line addition before all the pip installs `USER airflow` 

```
helm upgrade --install airflow apache-airflow/airflow \
  --set config.webserver.expose_config=true \
  --set config.secrets.backend=airflow.providers.amazon.aws.secrets.secrets_manager.SecretsManagerBackend \
  --set webserver.service.type=LoadBalancer \
  --set webserverSecretKeySecretName=airflow-webserver-secret \
  --set airflowVersion=2.7.2 \
  --set defaultAirflowRepository=thomasvyu/airflow \
  --set defaultAirflowTag=2.7.2-python-3.10  \
  --set dags.persistence.enabled=false \
  --set dags.gitSync.enabled=true \
  --set dags.gitSync.repo=https://github.com/Sage-Bionetworks-Workflows/orca-recipes \
  --set dags.gitSync.subPath=dags \
  --set dags.gitSync.branch=main \
  -f values.yaml \
  --namespace airflow

  
  # --set service.annotations."alb\.ingress\.kubernetes\.io/scheme"="internal"
```

```
kubectl annotate svc airflow-webserver alb.ingress.kubernetes.io/scheme=internal --namespace airflow --overwrite
```

3. Port forward
```
kubectl port-forward svc/airflow-webserver 8080:8080 --namespace airflow
```

4. Spin down airflow
```
helm delete airflow --namespace airflow
```

5. When upgrading or downgrading airflow, you need to remove all the PVC
```
kubectl get pvc -n airflow
```
