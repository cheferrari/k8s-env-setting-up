# 环境准备：安装nfs-server
## 1、kubeadm 安装的有三个节点的集群
一个Master, 两个Node
## 2、三个节点均安装nfs-utils  
这点很重要，不然后面pod使用持久卷会出现挂载不成功的现象
```
yum install nfs-utils -y
```
## 3、Master节点配置NFS服务器
```
mkdir -pv /ifs/kubernetes
cat >> /etc/exports <<EOF
/ifs/kubernetes *(rw,no_root_squash,no_all_squash,sync)
EOF
```
## 4、启动rpcbind和nfs服务
```
systemctl enable rpcbind && systemctl start rpcbind
systemctl enable nfs.service && systemctl start nfs.service
```

## 5、查看NFS状态
```
showmount -e
```

## 6、Install nfs-client-provisioner
```
#修改nfs server地址
vi deployment.yaml
...
...
          env:
            - name: PROVISIONER_NAME
              value: fuseim.pri/ifs
            - name: NFS_SERVER
              value: 192.168.75.131
            - name: NFS_PATH
              value: /ifs/kubernetes
      volumes:
        - name: nfs-client-root
          nfs:
            server: 192.168.75.131
            path: /ifs/kubernetes

```
安装
```
kubectl apply -f rbac.yaml
kubectl apply -f deployment.yaml
kubectl apply -f class.yaml
```
