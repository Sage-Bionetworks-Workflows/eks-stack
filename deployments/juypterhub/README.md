
### Juypter hub

```
helm upgrade --install jupyterhub jupyterhub/jupyterhub \
  --namespace juypterhub \
  --version=1.0.0 \
```

```
kubectl --namespace=juypterhub port-forward service/proxy-public 8080:http
```
