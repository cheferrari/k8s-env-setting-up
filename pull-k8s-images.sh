#!/bin/bash
VERSION=${K8S_VERSION:-v1.22.2}

###################################################################################################
# 拉取kubeadm初始化所需镜像，有以下几个镜像源可选：
# 1. mirrorgooglecontainers  https://hub.docker.com/u/mirrorgooglecontainers  无coredns镜像
# 2. https://hub.docker.com/u/anjia0532/，https://github.com/anjia0532/gcr.io_mirror 最近没有更新
# 3. Azure Mirrors中国  http://mirror.azure.cn/help/gcr-proxy-cache.html  
#    GCR Proxy Cache服务器相当于一台GCR镜像服务器，国内用户可以经由该服务器从gcr.io下载镜像
#    docker pull gcr.azk8s.cn/google_containers/kube-apiserver:v1.14.2
#    docker pull gcr.azk8s.cn/kubernetes-helm/tiller:v2.13.1  
#    目前Proxy Server仅限于 Azure China IP 使用，不再对外提供服务
# 4. aliyun阿里云
#    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/kube-apiserver:v1.14.2
#    docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.13.1
#    docker pull registry.aliyuncs.com/google_containers/kube-proxy:v1.15.0
####################################################################################################

# 运行 kubeadm config images list 命令可查看该版本kubeadm 所需那些镜像及版本信息

#[root@k8s-node1 ~]# kubeadm config images list
#k8s.gcr.io/kube-apiserver:v1.22.2
#k8s.gcr.io/kube-controller-manager:v1.22.2
#k8s.gcr.io/kube-scheduler:v1.22.2
#k8s.gcr.io/kube-proxy:v1.22.2
#k8s.gcr.io/pause:3.5
#k8s.gcr.io/etcd:3.5.0-0
#k8s.gcr.io/coredns/coredns:v1.8.4

images=(kube-proxy:$VERSION kube-scheduler:$VERSION kube-controller-manager:$VERSION kube-apiserver:$VERSION etcd:3.5.0-0 pause:3.5)
for imageName in "${images[@]}" ; do
ctr -n k8s.io i pull registry.aliyuncs.com/google_containers/"${imageName}"
ctr -n k8s.io i tag registry.aliyuncs.com/google_containers/"${imageName}" k8s.gcr.io/"${imageName}"
ctr -n k8s.io i rmi registry.aliyuncs.com/google_containers/"${imageName}"
done
ctr -n k8s.io i pull docker.io/coredns/coredns:1.8.4
ctr -n k8s.io i tag docker.io/coredns/coredns:1.8.4 registry.aliyuncs.com/google_containers/coredns:v1.8.4
