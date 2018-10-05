#!/bin/bash
# 适用于CentOS7，快速配置k8s机器所需环境
# 配置 CentOS Base 源，清华大学
mkdir -p /etc/yum.repos.d/base && mv /etc/yum.repos.d/* /etc/yum.repos.d/base
cat >/etc/yum.repos.d/CentOS-Base.repo <<EOF
# CentOS-Base.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the
# remarked out baseurl= line instead.
#
#

[base]
name=CentOS-$releasever - Base
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/os/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates
[updates]
name=CentOS-$releasever - Updates
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/updates/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/extras/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/$releasever/centosplus/$basearch/
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF

# 配置EPEL源，阿里云epel
# wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
curl -fsSL -o /etc/yum.repos.d/epel.repo https://mirrors.aliyun.com/repo/epel-7.repo

# 配置 docker-ce 源，阿里云
curl -fsSL -o /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

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


# 安装一些常用工具
yum makecache fast
yum install -y yum-utils lrzsz bash-completion wget net-tools

# 系统及内核配置
# 关闭Selinux and firewalld
systemctl stop firewalld && systemctl disable firewalld
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
 
# 关闭交换分区, Kubernetes v1.8+ 要求关闭系统 Swap
swapoff -a
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
# cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1 
net.bridge.bridge-nf-call-iptables = 1 
net.ipv4.ip_forward = 1
vm.swappiness=0 
EOF
sysctl --system
# sysctl -p

# 如果k8s proxy-model 要使用 ipvs ，则内核开启 ipvs 模块, ipvs 对内核版本有要求
cat >/etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_pe_sip ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack_ipv4"
for kernel_module in \${ipvs_modules}; do
    /sbin/modinfo -F filename \${kernel_module} > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        /sbin/modprobe \${kernel_module}
    fi
done
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules
# 立即加载ipvs相关模块
bash /etc/sysconfig/modules/ipvs.modules && lsmod |grep "ip_vs"

# 时间同步，-u参数可以越过防火墙与主机同步
# yum install -y ntpdate
# ntpdate -u ntp1.aliyun.com

# 安装 docker-ce 依赖
yum install -y yum-utils device-mapper-persistent-data lvm2

# 安装指定版本的 docker-ce 
# k8s 1.11.3 The validated docker versions are the same as for v1.10: 1.11.2 to 1.13.1 and 17.03.x (ref)
# k8s 1.12.0 The list of validated docker versions was updated to 1.11.1, 1.12.1, 1.13.1, 17.03, 17.06, 17.09, 18.06

# 如果是 k8s 1.11版本，则要安装 docker-ce 17.03 系列
#yum install  -y --setopt=obsoletes=0 \
#   docker-ce-17.03.2.ce-1.el7.centos.x86_64 \
#   docker-ce-selinux-17.03.2.ce-1.el7.centos.noarch

# 本脚本默认安装 docker-ce 版本: 18.06.1.ce
# 还可以在命令行 export DOCKER_VERSION=xxx 来安装其他版本 docker 
yum install -y docker-ce-${DOCKER_VERSION:-18.06.1.ce}

# docker 加速
mkdir -p /etc/docker
cat > /etc/docker/daemon.json<<EOF
{
  "registry-mirrors": ["https://registry.docker-cn.com", "https://docker.mirrors.ustc.edu.cn", "https://hub-mirror.c.163.com"],
  "max-concurrent-downloads": 20
}
EOF
systemctl daemon-reload

# 设置docker开机自启并启动docker
systemctl enable docker && systemctl restart docker

# Installing kubeadm, kubelet and kubectl
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable kubelet && systemctl start kubelet
