#!/bin/bash
VERSION=${K8S_VERSION:-v1.14.2}

###################################################################################################
# 拉取kubeadm1.14.1初始化所需镜像，有以下几个镜像源可选：
# 1. mirrorgooglecontainers  https://hub.docker.com/u/mirrorgooglecontainers  无coredns镜像
# 2. https://hub.docker.com/u/anjia0532/，https://github.com/anjia0532/gcr.io_mirror 最近没有更新
# 3. Azure Mirrors中国  http://mirror.azure.cn/help/gcr-proxy-cache.html  
#    GCR Proxy Cache服务器相当于一台GCR镜像服务器，国内用户可以经由该服务器从gcr.io下载镜像
#    docker pull gcr.azk8s.cn/google_containers/kube-apiserver:v1.14.1
#    docker pull gcr.azk8s.cn/kubernetes-helm/tiller:v2.13.1
# 4. aliyun阿里云
#    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.14.1
#    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.13.1
####################################################################################################

# 运行 kubeadm config images list 命令可查看该版本kubeadm 所需那些镜像及版本信息
# root@ip-172-31-36-102:~# kubeadm config images list
# k8s.gcr.io/kube-apiserver:v1.14.1
# k8s.gcr.io/kube-controller-manager:v1.14.1
# k8s.gcr.io/kube-scheduler:v1.14.1
# k8s.gcr.io/kube-proxy:v1.14.1
# k8s.gcr.io/pause:3.1
# k8s.gcr.io/etcd:3.3.10
# k8s.gcr.io/coredns:1.3.1

#[root@k8s-node1 ~]# kubeadm config images list
#k8s.gcr.io/kube-apiserver:v1.14.2
#k8s.gcr.io/kube-controller-manager:v1.14.2
#k8s.gcr.io/kube-scheduler:v1.14.2
#k8s.gcr.io/kube-proxy:v1.14.2
#k8s.gcr.io/pause:3.1
#k8s.gcr.io/etcd:3.3.10
#k8s.gcr.io/coredns:1.3.1

images=(kube-proxy:$VERSION kube-scheduler:$VERSION kube-controller-manager:$VERSION kube-apiserver:$VERSION etcd:3.3.10 pause:3.1 coredns:1.3.1)
for imageName in ${images[@]} ; do
docker pull gcr.azk8s.cn/google_containers/$imageName
docker tag gcr.azk8s.cn/google_containers/$imageName k8s.gcr.io/$imageName
docker rmi gcr.azk8s.cn/google_containers/$imageName
done
#docker pull coredns/coredns:1.3.1
#docker tag coredns/coredns:1.3.1 k8s.gcr.io/coredns:1.3.1
#docker rmi coredns/coredns:1.3.1
# kubeadm 初始化 k8s 集群，master节点执行，https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#instructions
# kubeadm init --kubernetes-version=v1.13.2 --pod-network-cidr=10.244.0.0/16
