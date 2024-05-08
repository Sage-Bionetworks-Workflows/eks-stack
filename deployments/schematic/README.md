# schematic

How to run schematic locally

1. follow instructions found [here](https://github.com/Sage-Bionetworks/schematic/tree/develop)

    ```
    export SCHEMATIC_CONFIG_CONTENT=$(cat config.yml)
    export SERVICE_ACCOUNT_CREDS=$(cat schematic_service_account_creds.json)
    ```

2. Execute docker compose

    ```
    docker compose up
    ```

3. Access here:

    ```
    http://localhost:3001/v1/ui/
    ```


## Deploy on k8

1. create naemespace
```
kubectl create namespace schematic
```

1. create secrets
```
cd local
kubectl create secret generic schematic-config --from-literal=config="$(cat config.yml)" -n schematic
kubectl create secret generic schematic-service-account --from-literal=schematic_service_account_creds="$(cat schematic_service_account_creds.json)" -n schematic
kubectl create secret generic dca-oauth-client --from-literal=dca_client_id="" -n schematic
kubectl create secret generic dca-oauth-secret --from-literal=dca_client_secret="" -n schematic
```

2. Deploy

```
# kubectl apply -f pv.yaml -n schematic
# kubectl apply -f pv_claim.yaml -n schematic
kubectl apply -f deployment.yaml -n schematic
kubectl apply -f svc.yaml -n schematic
```

4. load
```
kubectl --namespace=schematic port-forward service/schematic-aws-service 443:443

kubectl --namespace=schematic port-forward service/dca-service 3838:3838

```