# Install helm and tiller
## 1. create a ServiceAccount tiller
Helm installs the tiller service on your cluster to manage charts. Since k8s enables RBAC by default we will need to use kubectl to create a serviceaccount and clusterrolebinding so tiller has permission to deploy to the cluster.
```
kubectl apply -f tiller-rbac.yaml
```
## 2. install helm and tiller
```
bash install-helm-and-tiller.sh
# 等待十几秒，确认安装成功
helm version
Client: &version.Version{SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.13.1", GitCommit:"618447cbf203d147601b4b9bd7f8c37a5d39fbb4", GitTreeState:"clean"}
```
## 3. add chart repository
```
helm repo add stable http://mirror.azure.cn/kubernetes/charts/
helm repo add incubator http://mirror.azure.cn/kubernetes/charts-incubator/
```
## 4. helm autocompletion
```
echo "source <(helm completion bash)" >> ~/.bashrc
source ~/.bashrc
```
