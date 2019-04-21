# Install helm and tiller
# 1. create a ServiceAccount tiller
Helm installs the tiller service on your cluster to manage charts. Since k8s enables RBAC by default we will need to use kubectl to create a serviceaccount and clusterrolebinding so tiller has permission to deploy to the cluster.
```
kubectl apply -f tiller-rbac.yaml
```
# 2. install helm and tiller
```
bash install-helm-and-tiller.sh
```
