# k8s-env-setting-up
![language](https://img.shields.io/badge/language-shell-orange.svg)  
k8s-env-setting-up is a shell script to initialize the kubernetes's machine environment.
This script is suitable for centos7. 
- os: CentOS7
- kubernetes v1.14.1
- docker-ce 18.06.2
- network add-on: flannel v0.11.0(可选)
- kube-proxy mode: ipvs (可选)
- coredns 1.3.1
- etcd 3.3.10
- helm & tiller：[v2.13.1](https://github.com/cheferrari/k8s-env-setting-up/tree/master/helm)
- ingress: [traefik](https://github.com/cheferrari/k8s-ingress-controller-demo/tree/master/Traefik)
## Usage
### 环境准备
两台centos7.5主机，最小化安装  
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
### 2 下载镜像
#### 【可选】下载镜像前运行 kubeadm config images list 获取所需镜像及版本信息，如下
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
#### 【替换脚本中镜像tag】下载镜像（所有节点均执行）
```
bash pull-k8s-images.sh
```
### 3 kubeadm 初始化 k8s 集群
master节点执行如下命令，替换成自己的k8s版本  
参考：https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#instructions
```
kubeadm init --kubernetes-version=v1.14.1 --pod-network-cidr=10.244.0.0/16
# 如果kube-proxy要启用ipvs模式，则执行如下命令
# kubeadm init --config=kubeadm-config.yaml
```
根据提示拷贝kubeconfig文件到指定目录
```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
记录加入集群的命令
```
Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.75.165:6443 --token e0bj9u.x0083tvpogchq5bt \
    --discovery-token-ca-cert-hash sha256:5f744ed3b7e63cbcffa4a71bfacd90143fd7f371ee5d82aba77205514b33721c
```
### 4 安装网络附件 Flannel
master节点执行如下命令，安装网络附件addon  
```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml
```
### 5 master节点可调度pod【可选】
```
kubectl taint nodes --all node-role.kubernetes.io/master-
```
This will remove the node-role.kubernetes.io/master taint from any nodes that have it, including the master node, meaning that the scheduler will then be able to schedule pods everywhere
### 6 worker node加入集群
```
kubeadm join --token <token> <master-ip>:<master-port> --discovery-token-ca-cert-hash sha256:<hash>
```
### 7 Install helm and tiller
See the [installation guide](https://github.com/cheferrari/k8s-env-setting-up/tree/master/helm) for more information.
### 8使用小建议
#### 8.1 kubectl命令自动补全
[Kubectl Autocomplete](https://kubernetes.io/docs/reference/kubectl/cheatsheet/ "Kubectl Autocomplete")
```
echo "source <(kubectl completion bash)" >> ~/.bashrc
# 立即生效
source .bashrc 
```
```
# kubeadm自动补全
echo "source <(kubeadm completion bash)" >> ~/.bashrc
# 立即生效
source .bashrc
```
#### 8.2 安装kubens命令
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
#### 8.3 kubectl效率提升
[Kubectl效率提升指北](https://aleiwu.com/post/kubectl-guru/)
#### 8.4 kubeadm-ha
[kubeadm-ha](https://github.com/lentil1016/kubeadm-ha "kubeadm-ha")
