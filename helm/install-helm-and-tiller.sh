#!/bin/bash

#############################
# https://feisky.xyz/kubernetes-handbook/appendix/mirrors.html
# http://mirror.azure.cn/kubernetes/helm/
# http://mirror.azure.cn/help/gcr-proxy-cache.html
# docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:<tag>
#############################

HELM_VERSION=v2.14.2
TILLER_VERSION=v2.14.2
echo "INSTALL HELM ${HELM_VERSION} ..."
curl -fsSL -o /opt/helm-${HELM_VERSION}-linux-amd64.tar.gz http://mirror.azure.cn/kubernetes/helm/helm-${HELM_VERSION}-linux-amd64.tar.gz
mkdir -p /opt/helm
tar zxvf /opt/helm-${HELM_VERSION}-linux-amd64.tar.gz -C /opt/helm
cp /opt/helm/linux-amd64/helm /usr/local/bin/

echo "INSTALL TILLER ${TILLER_VERSION} ..."
# docker pull registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:${TILLER_VERSION}
docker pull gcr.azk8s.cn/kubernetes-helm/tiller:${TILLER_VERSION}
helm init --service-account tiller \
--tiller-image gcr.azk8s.cn/kubernetes-helm/tiller:${TILLER_VERSION}
