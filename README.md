# k8s-env-setting-up
k8s-env-setting-up is a shell script to initialize the kubernetes's machine environment.
This script is suitable for centos7.
## Usage
### 1 初始化系统环境
```
git clone https://github.com/cheferrari/k8s-env-setting-up.git
cd k8s-env-setting-up
# 默认安装 docker-ce 版本: 18.06.2.ce
# 默认安装 k8s 版本: v1.14.1
# 若要安装指定版本的docker或k8s，则
# export DOCKER_VERSION=18.06.1.ce
# export K8S_VERSION=1.13.2
bash k8s-env-setting-up.sh
```
执行完此脚本会重启操作系统
### 2 下载镜像
#### [可选]下载镜像前运行 kubeadm config images list 获取所需镜像及版本信息，如下
```
[root@localhost ~]# kubeadm config images list
k8s.gcr.io/kube-apiserver:v1.14.1
k8s.gcr.io/kube-controller-manager:v1.14.1
k8s.gcr.io/kube-scheduler:v1.14.1
k8s.gcr.io/kube-proxy:v1.14.1
k8s.gcr.io/pause:3.1
k8s.gcr.io/etcd:3.3.10
k8s.gcr.io/coredns:1.3.1
```
#### [替换脚本中镜像tag]下载镜像（所有节点均执行）
```
bash pull-k8s-images.sh
```
### 3 kubeadm 初始化 k8s 集群
master节点执行如下命令，替换成自己的k8s版本  
参考：https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#instructions
```
kubeadm init --kubernetes-version=v1.14.1 --pod-network-cidr=10.244.0.0/16
```
### 4 安装网络附件 Flannel
master节点执行如下命令，安装网络附件addon  
```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
```
### 5 worker node加入集群
```
kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>
```
