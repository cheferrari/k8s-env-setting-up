#!/bin/bash
VERSION=${K8S_VERSION:-v1.14.1}
# 拉取kubeadm1.14.1初始化所需镜像，mirrorgooglecontainers  https://hub.docker.com/u/anjia0532/，https://github.com/anjia0532/gcr.io_mirror
# 运行 kubeadm config images list 命令可查看该版本kubeadm 所需那些镜像及版本信息
# [root@localhost ~]# kubeadm config images list
# k8s.gcr.io/kube-apiserver:v1.13.2
# k8s.gcr.io/kube-controller-manager:v1.13.2
# k8s.gcr.io/kube-scheduler:v1.13.2
# k8s.gcr.io/kube-proxy:v1.13.2
# k8s.gcr.io/pause:3.1
# k8s.gcr.io/etcd:3.2.24
# k8s.gcr.io/coredns:1.2.6
# root@ip-172-31-36-102:~# kubeadm config images list
# k8s.gcr.io/kube-apiserver:v1.14.1
# k8s.gcr.io/kube-controller-manager:v1.14.1
# k8s.gcr.io/kube-scheduler:v1.14.1
# k8s.gcr.io/kube-proxy:v1.14.1
# k8s.gcr.io/pause:3.1
# k8s.gcr.io/etcd:3.3.10
# k8s.gcr.io/coredns:1.3.1
images=(kube-proxy:$VERSION kube-scheduler:$VERSION kube-controller-manager:$VERSION kube-apiserver:$VERSION etcd:3.3.10 pause:3.1)
for imageName in ${images[@]} ; do
docker pull mirrorgooglecontainers/$imageName
docker tag mirrorgooglecontainers/$imageName k8s.gcr.io/$imageName
docker rmi mirrorgooglecontainers/$imageName
done
docker pull coredns/coredns:1.3.1
docker tag coredns/coredns:1.3.1 k8s.gcr.io/coredns:1.3.1
docker rmi coredns/coredns:1.3.1
# kubeadm 初始化 k8s 集群，master节点执行，https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#instructions
# kubeadm init --kubernetes-version=v1.13.2 --pod-network-cidr=10.244.0.0/16
