#!/bin/bash
VERSION=v1.13.2
# 拉取kubeadm1.13.2初始化所需镜像，mirrorgooglecontainers  https://hub.docker.com/u/anjia0532/，https://github.com/anjia0532/gcr.io_mirror
# 运行 kubeadm config images list 命令可查看该版本kubeadm 所需那些镜像及版本信息
images=(kube-proxy:$VERSION kube-scheduler:$VERSION kube-controller-manager:$VERSION kube-apiserver:$VERSION etcd:3.2.24 coredns:1.2.2 pause:3.1 )
for imageName in ${images[@]} ; do
docker pull mirrorgooglecontainers/$imageName
docker tag mirrorgooglecontainers/$imageName k8s.gcr.io/$imageName
docker rmi mirrorgooglecontainers/$imageName
done

# kubeadm 初始化 k8s 集群，master节点执行，https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#instructions
# kubeadm init --kubernetes-version=v1.13.2 --pod-network-cidr=10.244.0.0/16
