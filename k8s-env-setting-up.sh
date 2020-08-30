#!/bin/bash
# 适用于CentOS7及以上，快速配置k8s机器所需环境

# 设定k8s and docker-ce version
K8S_VERSION=1.18.8
DOCKER_VERSION=19.03.11

# 系统及内核配置
# 关闭Selinux and firewalld
systemctl stop firewalld && systemctl disable firewalld
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
 
# 关闭交换分区, Kubernetes v1.8+ 要求关闭系统 Swap
swapoff -a
# 永久关闭 分隔符为/ &引用前面的匹配内容
sed -i 's/.*swap.*/#&/' /etc/fstab
#yes | cp /etc/fstab /etc/fstab_bak
#cat /etc/fstab_bak |grep -v swap > /etc/fstab


# 修改系统 ulimit 限制
cat >> /etc/security/limits.conf <<EOF
root soft nofile 65535
root hard nofile 65535
* soft nofile 65535
* hard nofile 65535
* soft noproc 65535
* hard noproc 65535 
EOF

# 开启forward
# Docker从1.13版本开始调整了默认的防火墙规则
# 禁用了iptables filter表中FOWARD链
# 这样会引起Kubernetes集群中跨Node的Pod无法通信
# iptables -P FORWARD ACCEPT

# 上面的可以直接修改内核参数实现
# 配置各节点系统内核参数使流过网桥的流量也进入iptables/netfilter框架中, 开启ipv4转发
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1 
net.bridge.bridge-nf-call-iptables = 1 
net.ipv4.ip_forward = 1
vm.swappiness=0 
EOF
sysctl --system
# sysctl -p

# 如果k8s proxy-model 要使用 ipvs ，则内核开启 ipvs 模块, ipvs 对内核版本有要求
#cat >/etc/sysconfig/modules/ipvs.modules <<EOF
##!/bin/bash
#ipvs_mods_dir="/usr/lib/modules/\$(uname -r)/kernel/net/netfilter/ipvs"
#for i in \$(ls $ipvs_mods_dir | grep -o "^[^.]*"); do
#    /sbin/modinfo -F filename \$i &> /dev/null
#    if [ \$? -eq 0 ]; then
#        /sbin/modprobe \$i
#    fi
#done
cat >/etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_pe_sip ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack_ipv4"
for kernel_module in \${ipvs_modules}; do
    /sbin/modinfo -F filename \${kernel_module} > /dev/null 2>&1
    if [ \$? -eq 0 ]; then
        /sbin/modprobe \${kernel_module}
    fi
done
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules
# 立即加载ipvs相关模块
bash /etc/sysconfig/modules/ipvs.modules && lsmod |grep -e ip_vs -e nf_conntrack_ipv4

# 配置 CentOS Base 源
mkdir -p /etc/yum.repos.d/base && mv /etc/yum.repos.d/* /etc/yum.repos.d/base
curl -fsSL -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo

# 配置EPEL源，阿里云epel
# wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
curl -fsSL -o /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo

# 配置 docker-ce 源，阿里云
curl -fsSL -o /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 配置 kubernetes 源 ，阿里云
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

# 生成缓存
echo "y" | yum makecache fast

# 安装一些常用工具
yum install -y yum-utils lrzsz bash-completion wget net-tools
# kube-proxy开启ipvs模式需要的软件包
yum install -y ipvsadm ipset
# 时间同步，-u参数可以越过防火墙与主机同步
# yum install -y ntpdate
# ntpdate -u ntp1.aliyun.com

# 安装 docker-ce 依赖
yum install -y yum-utils device-mapper-persistent-data lvm2

# 安装指定版本的 docker-ce 
# k8s 1.15.3 The list of validated docker versions remains unchanged. The current list is 1.13.1, 17.03, 17.06, 17.09, 18.06, 18.09
# k8s 1.12.0 The list of validated docker versions was updated to 1.11.1, 1.12.1, 1.13.1, 17.03, 17.06, 17.09, 18.06

# 如果是 k8s 1.11版本，则要安装 docker-ce 17.03 系列
#yum install  -y --setopt=obsoletes=0 \
#   docker-ce-17.03.2.ce-1.el7.centos.x86_64 \
#   docker-ce-selinux-17.03.2.ce-1.el7.centos.noarch

# 本脚本默认安装 docker-ce 版本: 19.03.8
# 还可以在命令行 export DOCKER_VERSION=xxx 来安装其他版本 docker 
# https://kubernetes.io/docs/setup/cri/#docker    Version 18.06.2 is recommended
yum install -y containerd.io-1.2.13 docker-ce-${DOCKER_VERSION} docker-ce-cli-${DOCKER_VERSION}

# https://kubernetes.io/docs/setup/cri/#cgroup-drivers  
# kubeadm开始建议使用systemd作为节点的cgroup控制器，因此建议读者参考本文流程配置docker为使用systemd，而非默认的Cgroupfs
# docker 加速
mkdir -p /etc/docker
cat > /etc/docker/daemon.json<<EOF
{
  "registry-mirrors": ["https://registry.docker-cn.com", "https://hub-mirror.c.163.com"],
  "max-concurrent-downloads": 20,
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
mkdir -p /etc/systemd/system/docker.service.d

# 设置docker开机自启并启动docker
systemctl daemon-reload
systemctl enable docker && systemctl restart docker

# Installing kubeadm, kubelet and kubectl
# 安装指定版本的 kubeadm
# yum list kubeadm --showduplicates
# yum install -y kubelet-1.15.3 kubeadm-1.15.3 kubectl-1.15.3
yum install -y kubelet-${K8S_VERSION} kubeadm-${K8S_VERSION} kubectl-${K8S_VERSION} --disableexcludes=kubernetes
systemctl enable kubelet && systemctl start kubelet
