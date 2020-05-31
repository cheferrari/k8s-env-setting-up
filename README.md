# Overview
![language](https://img.shields.io/badge/language-shell-orange.svg) [![shellcheck](https://github.com/cheferrari/k8s-env-setting-up/workflows/Shellcheck/badge.svg)](https://github.com/cheferrari/k8s-env-setting-up/actions)  
k8s-env-setting-up is a shell script to initialize the kubernetes's machine environment.
This script is suitable for centos7.6. 
- OS: `CentOS7.6`
- kubernetes: `v1.18.0`
- docker-ce: `19.03.8`
- network add-on: `flannel v0.11.0`(可选)
- kube-proxy mode: `ipvs` (可选)
- coredns: `1.6.7`
- etcd: `3.4.3-0`
- helm & tiller：[v2.14.2](https://github.com/cheferrari/k8s-env-setting-up/tree/master/helm)
- ingress: [traefik](https://github.com/cheferrari/k8s-env-setting-up/tree/master/traefik)

# Table of Contents
- [Overview](#overview)
- [Table of Contents](#table-of-contents)
- [Usage](#usage)
  - [环境准备](#环境准备)
  - [1 初始化系统环境](#1-初始化系统环境)
  - [2 下载镜像](#2-下载镜像)
    - [【可选】下载镜像前运行 kubeadm config images list 获取所需镜像及版本信息，如下](#可选下载镜像前运行-kubeadm-config-images-list-获取所需镜像及版本信息如下)
    - [【替换脚本中镜像tag】下载镜像（所有节点均执行）](#替换脚本中镜像tag下载镜像所有节点均执行)
  - [3 kubeadm 初始化 k8s 集群](#3-kubeadm-初始化-k8s-集群)
  - [4 安装网络附件flannel/calico](#4-安装网络附件flannelcalico)
  - [5 master节点可调度pod【可选】](#5-master节点可调度pod可选)
  - [6 worker node加入集群](#6-worker-node加入集群)
  - [7 Install helm and tiller](#7-install-helm-and-tiller)
  - [8 Install Traefik](#8-install-traefik)
  - [9 Install metrics-server](#9-install-metrics-server)
    - [修改metrics-server-deployment.yaml](#修改metrics-server-deploymentyaml)
    - [metrics-server参数介绍](#metrics-server参数介绍)
    - [拉镜像](#拉镜像)
    - [部署metrics-server](#部署metrics-server)
  - [10 使用小建议](#10-使用小建议)
    - [10.1 kubectl命令自动补全](#101-kubectl命令自动补全)
    - [10.2 安装kubens命令](#102-安装kubens命令)
    - [10.3 kubectl效率提升](#103-kubectl效率提升)
    - [10.4 kubeadm-ha](#104-kubeadm-ha)

# Usage
## 环境准备
两台centos7.6主机，最小化安装  
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
# 默认安装 docker-ce 版本: 19.03.4
# 默认安装 k8s 版本: v1.18.0
# 若要安装指定版本的docker或k8s，则
# export DOCKER_VERSION=18.06.1.ce
# export K8S_VERSION=1.14.2
bash k8s-env-setting-up.sh
```
## 2 下载镜像
### 【可选】下载镜像前运行 kubeadm config images list 获取所需镜像及版本信息，如下
```
[root@localhost ~]# kubeadm config images list
k8s.gcr.io/kube-apiserver:v1.18.0
k8s.gcr.io/kube-controller-manager:v1.18.0
k8s.gcr.io/kube-scheduler:v1.18.0
k8s.gcr.io/kube-proxy:v1.18.0
k8s.gcr.io/pause:3.1
k8s.gcr.io/etcd:3.4.3-0
k8s.gcr.io/coredns:1.6.5
```
下载镜像
```
kubeadm config images pull --image-repository=gcr.azk8s.cn/google_containers
```

### 【替换脚本中镜像tag】下载镜像（所有节点均执行）
```
bash pull-k8s-images.sh
```
## 3 kubeadm 初始化 k8s 集群
master节点执行如下命令，替换成自己的k8s版本  
参考：https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#instructions
```
kubeadm init --kubernetes-version=v1.18.0 --pod-network-cidr=10.244.0.0/16
# 如果kube-proxy要启用ipvs模式，则执行如下命令
# kubeadm init --config=kubeadm-config.yaml
```
`kubeadm init`命令参考: [kubeadm init](https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/)   
`kubeadm config print init-defaults`

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
```
kubectl apply -f kube-flannel.yml
#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml
```
安装calico   
```
kubectl apply -f calico.yaml
```
## 5 master节点可调度pod【可选】
```
kubectl taint nodes --all node-role.kubernetes.io/master-
```
This will remove the node-role.kubernetes.io/master taint from any nodes that have it, including the master node, meaning that the scheduler will then be able to schedule pods everywhere
## 6 worker node加入集群
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

## 7 Install helm and tiller
See the [installation guide](https://github.com/cheferrari/k8s-env-setting-up/tree/master/helm) for more information.

## 8 Install Traefik
See the [installation guide](https://github.com/cheferrari/k8s-env-setting-up/tree/master/traefik) for more information.

## 9 Install metrics-server
```
git clone https://github.com/kubernetes-incubator/metrics-server
cd metrics-server/metrics-server/deploy/1.8+

[root@k8s-node1 ~/metrics-server/deploy/1.8+]# ll
total 28
-rw-r--r-- 1 root root 384 Jun 21 10:35 aggregated-metrics-reader.yaml
-rw-r--r-- 1 root root 308 Jun 21 10:35 auth-delegator.yaml
-rw-r--r-- 1 root root 329 Jun 21 10:35 auth-reader.yaml
-rw-r--r-- 1 root root 298 Jun 21 10:35 metrics-apiservice.yaml
-rw-r--r-- 1 root root 991 Jun 21 10:41 metrics-server-deployment.yaml
-rw-r--r-- 1 root root 291 Jun 21 10:35 metrics-server-service.yaml
-rw-r--r-- 1 root root 502 Jun 21 10:35 resource-reader.yaml
```
### 修改metrics-server-deployment.yaml 
- imagePullPolicy: IfNotPresent
- 增加两个命令参数
```
# cat metrics-server-deployment.yaml
...
      - name: metrics-server
        image: k8s.gcr.io/metrics-server-amd64:v0.3.6
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
docker pull gcr.azk8s.cn/google_containers/metrics-server-amd64:v0.3.6
docker tag gcr.azk8s.cn/google_containers/metrics-server-amd64:v0.3.6 k8s.gcr.io/metrics-server-amd64:v0.3.6
```

### 部署metrics-server
```
kubectl apply -f 1.8+/
```
部署完成后过几分钟检查, API版本中出现 metrics.k8s.io/v1beta1, kubectl top命令可以正确输出即表明部署成功
```
# kubectl api-versions
metrics.k8s.io/v1beta1

# kubectl top node
NAME        CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
k8s-node1   238m         5%     806Mi           21%
```

## 10 使用小建议
### 10.1 kubectl命令自动补全
[Kubectl Autocomplete](https://kubernetes.io/docs/reference/kubectl/cheatsheet/ "Kubectl Autocomplete")
```
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc
```
```
# kubeadm自动补全
echo "source <(kubeadm completion bash)" >> ~/.bashrc
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
