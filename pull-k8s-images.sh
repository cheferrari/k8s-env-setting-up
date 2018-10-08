#!/bin/bash
# 拉取kubeadm1.12.0初始化所需镜像，https://hub.docker.com/u/anjia0532/，https://github.com/anjia0532/gcr.io_mirror
images=(kube-proxy:v1.12.0 kube-scheduler:v1.12.0 kube-controller-manager:v1.12.0 kube-apiserver:v1.12.0 etcd:3.2.24 coredns:1.2.2 pause:3.1 )
for imageName in ${images[@]} ; do
docker pull anjia0532/google-containers.$imageName
docker tag anjia0532/google-containers.$imageName k8s.gcr.io/$imageName
docker rmi anjia0532/google-containers.$imageName
done

# kubeadm 初始化 k8s 集群，master节点执行，https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#instructions
# kubeadm init --kubernetes-version=v1.12.0 --pod-network-cidr=10.244.0.0/16
