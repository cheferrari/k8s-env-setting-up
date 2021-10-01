# Overview
![language](https://img.shields.io/badge/language-shell-orange.svg) ![Shellcheck](https://github.com/cheferrari/k8s-env-setting-up/workflows/Shellcheck/badge.svg)  
k8s-env-setting-up is a shell script to initialize the kubernetes's machine environment.
This script is suitable for centos7.6-7.8. 
- OS: `CentOS7.8`
- kubernetes: `v1.22.2`
- containerd: `1.4.9`
- network add-on: `flannel v0.14.0`(可选)
- kube-proxy mode: `ipvs` (可选)
- coredns: `v1.8.4`
- etcd: `3.5.0-0`
- ingress: `traefik`

# Table of Contents
- [Overview](#overview)
- [Table of Contents](#table-of-contents)
- [Usage](#usage)
  - [环境准备](#环境准备)
  - [1 初始化系统环境](#1-初始化系统环境)
  - [2 下载镜像](#2-下载镜像)
    - [【可选】下载镜像前运行 kubeadm config images list 获取所需镜像及版本信息，如下](#可选下载镜像前运行-kubeadm-config-images-list-获取所需镜像及版本信息如下)
  - [3 kubeadm 初始化 k8s 集群](#3-kubeadm-初始化-k8s-集群)
  - [4 安装网络附件flannel/calico](#4-安装网络附件flannelcalico)
  - [5 master节点可调度pod【可选】](#5-master节点可调度pod可选)
  - [6 worker node加入集群](#6-worker-node加入集群)
  - [7 Install helm](#7-install-helm)
  - [8 Install Traefik](#8-install-traefik)
  - [9 Install metrics-server](#9-install-metrics-server)
    - [修改components.yaml](#修改componentsyaml)
    - [metrics-server参数介绍](#metrics-server参数介绍)
    - [拉镜像](#拉镜像)
    - [部署metrics-server](#部署metrics-server)
  - [10 使用小建议](#10-使用小建议)
    - [10.1 kubectl/kubeadm/helm命令自动补全](#101-kubectlkubeadmhelm命令自动补全)
    - [10.2 安装kubens命令](#102-安装kubens命令)
    - [10.3 kubectl效率提升](#103-kubectl效率提升)
    - [10.4 kubeadm-ha](#104-kubeadm-ha)

# Usage
## 环境准备
两台centos7.6或7.8主机，最小化安装  
设置主机名，重新登录即可
```
hostnamectl set-hostname k8s-node1
hostnamectl set-hostname k8s-node2
```
设置的主机名保存在 /etc/hostname 文件中  
【可选】如果 DNS 不支持解析主机名称，则修改每台机器的 /etc/hosts 文件，添加主机名和 IP 的对应关系：
```
cat >> /etc/hosts <<EOF
192.168.75.165 k8s-node1
192.168.75.166 k8s-node2
EOF
```
## 1 初始化系统环境
```
git clone https://github.com/cheferrari/k8s-env-setting-up.git
cd k8s-env-setting-up
# 安装指定版本的k8s，则修改脚本中 K8S_VERSION，或
# export K8S_VERSION=1.22.2
bash k8s-env-setting-up.sh
```
## 2 下载镜像
### 【可选】下载镜像前运行 kubeadm config images list 获取所需镜像及版本信息，如下
```
[root@localhost ~]# kubeadm config images list
k8s.gcr.io/kube-apiserver:v1.22.2
k8s.gcr.io/kube-controller-manager:v1.22.2
k8s.gcr.io/kube-scheduler:v1.22.2
k8s.gcr.io/kube-proxy:v1.22.2
k8s.gcr.io/pause:3.5
k8s.gcr.io/etcd:3.5.0-0
k8s.gcr.io/coredns/coredns:v1.8.4
#下载镜像方法一:
kubeadm config images pull --config kubeadm.yaml
#kubeadm config images pull --image-repository=registry.aliyuncs.com/google_containers

# 查看下载的镜像：
ctr -n k8s.io i ls

# 上面在拉取 coredns 镜像的时候出错了，没有找到这个镜像，我们可以手动 pull 该镜像，然后重新 tag 下镜像地址即可：
ctr -n k8s.io i pull docker.io/coredns/coredns:1.8.4
ctr -n k8s.io i tag docker.io/coredns/coredns:1.8.4 registry.aliyuncs.com/google_containers/coredns:v1.8.4

#下载镜像方法二：替换脚本中镜像tag，下载镜像（所有节点均执行）
bash pull-k8s-images.sh
```
## 3 kubeadm 初始化 k8s 集群
**Master节点初始化**  
通过下面的命令在 master 节点上输出集群初始化默认使用的配置，然后根据我们自己的需求修改配置，比如修改 imageRepository 指定集群初始化时拉取 Kubernetes 所需镜像的地址，kube-proxy 的模式为 ipvs，另外需要注意的是我们这里是准备安装 flannel 网络插件的，需要将 networking.podSubnet 设置为10.244.0.0/16  
```
kubeadm config print init-defaults --component-configs KubeletConfiguration > kubeadm.yaml
```
master节点执行如下初始化命令
参考：https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#instructions
```
kubeadm init --config kubeadm.yaml

cat kubeadm.yaml
# kubeadm config print init-defaults --component-configs KubeletConfiguration > kubeadm.yaml
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 192.168.75.142
  bindPort: 6443
nodeRegistration:
  criSocket: /run/containerd/containerd.sock
  #criSocket: /var/run/dockershim.sock
  imagePullPolicy: IfNotPresent
  name: master
  taints: null
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.aliyuncs.com/google_containers
kind: ClusterConfiguration
kubernetesVersion: 1.22.2
networking:
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/12
  podSubnet: 10.244.0.0/16
scheduler: {}
---
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 0s
    cacheUnauthorizedTTL: 0s
cgroupDriver: systemd
clusterDNS:
- 10.96.0.10
clusterDomain: cluster.local
cpuManagerReconcilePeriod: 0s
evictionPressureTransitionPeriod: 0s
fileCheckFrequency: 0s
healthzBindAddress: 127.0.0.1
healthzPort: 10248
httpCheckFrequency: 0s
imageMinimumGCAge: 0s
kind: KubeletConfiguration
logging: {}
memorySwap: {}
nodeStatusReportFrequency: 0s
nodeStatusUpdateFrequency: 0s
rotateCertificates: true
runtimeRequestTimeout: 0s
shutdownGracePeriod: 0s
shutdownGracePeriodCriticalPods: 0s
staticPodPath: /etc/kubernetes/manifests
streamingConnectionIdleTimeout: 0s
syncFrequency: 0s
volumeStatsAggPeriod: 0s


# kubeadm init --kubernetes-version=v1.20.6 --pod-network-cidr=10.244.0.0/16 --image-repository=registry.aliyuncs.com/google_containers
# 如果kube-proxy要启用ipvs模式，则执行如下命令
# kubeadm init --config=kubeadm-config.yaml
```
`kubeadm init`命令参考: [kubeadm init](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/)   

根据提示拷贝kubeconfig文件到指定目录
```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
记录加入集群的命令(替换成自己的命令)
```
Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.75.165:6443 --token e0bj9u.x0083tvpogchq5bt \
    --discovery-token-ca-cert-hash sha256:5f744ed3b7e63cbcffa4a71bfacd90143fd7f371ee5d82aba77205514b33721c
```
## 4 安装网络附件flannel/calico
[The network must be deployed before any applications. Also, CoreDNS will not start up before a network is installed. kubeadm only supports Container Network Interface (CNI) based networks (and does not support kubenet)](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#pod-network)  
master节点执行如下命令，安装网络附件addon(必须先安装网络附件，不然coredns会一直处于Pending状态)  
**安装Flannel**  
```
kubectl apply -f kube-flannel-v0.14.yml
# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```
**安装Calico**  
```
kubectl apply -f calico.yaml
```
## 5 master节点可调度pod【可选】
```
kubectl taint nodes --all node-role.kubernetes.io/master-
```
This will remove the node-role.kubernetes.io/master taint from any nodes that have it, including the master node, meaning that the scheduler will then be able to schedule pods everywhere
## 6 worker node加入集群
**如果忘记了上面的 join 命令可以使用命令 kubeadm token create --print-join-command 重新获取**
```
kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>
```

在 k8s 1.8 之后，默认生成的 token 有效期只有 24 小时，之后就无效了。if you require a non-expiring token use --token-ttl 0  
在初始化集群之后如果 token 过期一般分一下几部重新加入集群。
- 重新生成新的 token
```
[root@k8s-node1 ~]# kubeadm token create 
2oqkba.vuwvab1o92vd2k1u
[root@k8s-node1 ~]# 
[root@k8s-node1 ~]# kubeadm token list 
TOKEN                     TTL       EXPIRES                     USAGES                   DESCRIPTION   EXTRA GROUPS
2oqkba.vuwvab1o92vd2k1u   23h       2019-07-28T15:53:24+08:00   authentication,signing   <none>        system:bootstrappers:kubeadm:default-node-token
```
- 获取 CA 证书 sha256 编码 hash 值
```
$ openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
ded14fed2cf501a5ded219af9d6c62287327bcbbbaa5c96aa17dc0d1583a9ea9
```
- 新节点加入集群
```
$ kubeadm join ip:port --token 2oqkba.vuwvab1o92vd2k1u --discovery-token-ca-cert-hash sha256:ded14fed2cf501a5ded219af9d6c62287327bcbbbaa5c96aa17dc0d1583a9ea9
```
- 查看所有节点
```
[root@master ~]# kubectl get no -owide
NAME     STATUS   ROLES                  AGE     VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION           CONTAINER-RUNTIME
master   Ready    control-plane,master   2d21h   v1.22.2   192.168.75.142   <none>        CentOS Linux 7 (Core)   3.10.0-1127.el7.x86_64   containerd://1.4.9
node1    Ready    <none>                 31m     v1.22.2   192.168.75.143   <none>        CentOS Linux 7 (Core)   3.10.0-1127.el7.x86_64   containerd://1.4.9
```

## 7 Install helm
See the [Installing Helm](https://helm.sh/docs/intro/install/) for more information.
```
From the Binary Releases
Every release of Helm provides binary releases for a variety of OSes. These binary versions can be manually downloaded and installed.

Download your [desired version](https://github.com/helm/helm/releases)
Unpack it (tar -zxvf helm-v3.0.0-linux-amd64.tar.gz)
Find the helm binary in the unpacked directory, and move it to its desired destination (mv linux-amd64/helm /usr/local/bin/helm)
```
## 8 Install Traefik
See the [Install Traefik](https://doc.traefik.io/traefik/getting-started/install-traefik/) for more information.
```
Use the Helm Chart
Warning

The Traefik Chart from Helm's default charts repository is still using Traefik v1.7.

Traefik can be installed in Kubernetes using the Helm chart from https://github.com/traefik/traefik-helm-chart.

Ensure that the following requirements are met:

Kubernetes 1.14+
Helm version 3.x is installed
Add Traefik's chart repository to Helm:


helm repo add traefik https://helm.traefik.io/traefik
You can update the chart repository by running:


helm repo update
And install it with the helm command line:


helm install traefik traefik/traefik
Helm Features

All Helm features are supported. For instance, installing the chart in a dedicated namespace:


Install in a Dedicated Namespace

kubectl create ns traefik-v2
# Install in the namespace "traefik-v2"
helm install --namespace=traefik-v2 \
    traefik traefik/traefik
```

## 9 Install metrics-server
Reference: [Installation metrics-server](https://github.com/kubernetes-sigs/metrics-server#installation)
### 修改components.yaml 
- imagePullPolicy: IfNotPresent
- 增加命令参数: --kubelet-insecure-tls
```
# cat components.yaml
...
      - name: metrics-server
        image: docker.io/bitnami/metrics-server:0.5.0
        imagePullPolicy: IfNotPresent
        args:
        - --kubelet-insecure-tls
        - --kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS,ExternalDNS,ExternalIP
...
```
### metrics-server参数介绍
- --kubelet-insecure-tls: skip verifying Kubelet CA certificates. Not recommended for production usage, but can be useful in test clusters with self-signed Kubelet serving certificates
- --kubelet-preferred-address-types: the order in which to consider different Kubelet node address types when connecting to Kubelet. Functions similarly to the flag of the same name on the API server.
- --kubelet-insecure-tls: Do not verify CA of serving certificates presented by Kubelets.  For testing purposes only.
- --kubelet-preferred-address-types strings: The priority of node address types to use when determining which address to use to connect to a particular node (default [Hostname,InternalDNS,InternalIP,ExternalDNS,ExternalIP])

metrics-server默认使用coredns作为解析，但是coredns不提供node的解析，因此需要设置--kubelet-preferred-address-types参数  
或者在cordns的配置文件中加上主机名的解析，如下：
```
[root@k8s-node1 metrics-server]# kubectl edit cm coredns 

# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
data:
  Corefile: |
    .:53 {
        errors
        health
        hosts {
           192.168.75.163 k8s-node1
           192.168.75.164 k8s-node2
           fallthrough
        }
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           upstream
           fallthrough in-addr.arpa ip6.arpa
        }
```

### 拉镜像
```
ctr -n k8s.io i pull docker.io/bitnami/metrics-server:0.5.0
```
### 部署metrics-server
```
kubectl apply -f components.yaml
```
部署完成后检查, API版本中出现 metrics.k8s.io/v1beta1, kubectl top命令可以正确输出即表明部署成功
```
# kubectl api-versions
metrics.k8s.io/v1beta1

# kubectl top node
NAME        CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
k8s-node1   238m         5%     806Mi           21%
```

## 10 使用小建议
### 10.1 kubectl/kubeadm/helm命令自动补全
[Kubectl Autocomplete](https://kubernetes.io/docs/reference/kubectl/cheatsheet/ "Kubectl Autocomplete")
```
# kubectl 命令自动补全
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc

# kubeadm 自动补全
echo "source <(kubeadm completion bash)" >> ~/.bashrc
source ~/.bashrc

# helm 命令自动补全
echo "source <(helm completion bash)" >> ~/.bashrc
source ~/.bashrc
```
### 10.2 安装kubens命令
[kubens and kubectx](https://github.com/ahmetb/kubectx)
kubens 可以方便的切换 Namespace 
```
# Example installation steps:
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens
# 配置自动补全
COMPDIR=$(pkg-config --variable=completionsdir bash-completion)
ln -sf /opt/kubectx/completion/kubens.bash $COMPDIR/kubens
ln -sf /opt/kubectx/completion/kubectx.bash $COMPDIR/kubectx
```
### 10.3 kubectl效率提升
[Kubectl效率提升指北](https://aleiwu.com/post/kubectl-guru/)
### 10.4 kubeadm-ha
[kubeadm-ha](https://github.com/lentil1016/kubeadm-ha "kubeadm-ha")
