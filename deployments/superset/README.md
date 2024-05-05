# Superset 

https://superset.apache.org/docs/installation/kubernetes/

```
helm upgrade --install superset superset/superset -n superset --create-namespace
```

```
kubectl port-forward superset-7cd75988dc-t7fq6 8088:8088 -n superset
```