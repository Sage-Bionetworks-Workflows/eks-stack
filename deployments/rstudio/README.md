# rstudio

```
kubectl apply -f rstudio-deployment.yaml
kubectl apply -f rstudio-service.yaml


kubectl --namespace=rstudio port-forward service/rstudio-service 8080:http
```
