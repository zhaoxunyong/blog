---
title: Kubernetes集群搭建
date: 2017-01-03 09:11:20
categories: ["kubernetes"]
tags: ["kubernetes"]
---
Kubernetes就不介绍了，用了都说好。

## 环境准备
### 3台虚拟机
具体参考：[Vagrant环境搭建](Vagrant环境搭建.html)
docker版本为：1.12.5
kubernetes版本为：v1.5.1

|主机IP|主机名称|软件|内存|
|----|--------|----------|------|
|192.168.10.6|k8s-master|docker、kube-dns、kube-apiserver、kube-controller-manager、kube-scheduler|1024m|
|192.168.10.7|k8s-node1|docker、kube-proxy、kubelet|512m|
|192.168.10.8|k8s-node2|docker、kube-proxy、kubelet|512m|

### 安装基础软件
以下为每台都需要同样的操作

配置yum源：
```bash
[root@k8s-master ~]$ tee /etc/yum.repos.d/docker.repo <<-'EOF'
[docker]
name=Docker Repository
baseurl=http://mirrors.aliyun.com/docker-engine/yum/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/docker-engine/yum/gpg
EOF
```

安装：
```bash
yum -y install docker-engine
```

修改配置：
```bash
#修改dns
cat /etc/NetworkManager/NetworkManager.conf|grep "dns=none" > /dev/null
if [[ $? != 0 ]]; then
  echo "dns=none" >> /etc/NetworkManager/NetworkManager.conf
  systemctl restart NetworkManager.service
fi

#修改时区
ln -sf /usr/share/zoneinfo/Asia/Chongqing /etc/localtime

#关闭内核安全
#sed -i 's;SELINUX=.*;SELINUX=disabled;' /etc/selinux/config
sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
#setenforce 0
#getenforce
#reboot
[root@k8s-node2 ~]# sestatus
SELinux status:                 disabled

#关闭防火墙
systemctl disable iptables
systemctl stop iptables
systemctl disable firewalld
systemctl stop firewalld

#优化内核
cat /etc/security/limits.conf|grep 65535 > /dev/null
if [[ $? != 0 ]]; then
cat >> /etc/security/limits.conf  << EOF
*               soft    nofile             65535
*               hard    nofile             65535
*               soft    nproc              65535
*               hard    nproc              65535
EOF
fi

#打开端口转发
#永久修改：/etc/sysctl.conf中的net.ipv4.ip_forward=1，生效：sysctl -p
#临时修改：echo 1 > /proc/sys/net/ipv4/ip_forward，重启后失效

cat /etc/sysctl.conf|grep "net.ipv4.ip_forward" > /dev/null
if [[ $? != 0 ]]; then
cat >> /etc/sysctl.conf  << EOF
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.ip_forward = 1
EOF
sysctl -p
fi


su - root -c "ulimit -a"
```

docker加速：
```bash
sed -i "s;^ExecStart=/usr/bin/dockerd$;ExecStart=/usr/bin/dockerd \
  --registry-mirror=http://3fecfd09.m.daocloud.io;" \
  /usr/lib/systemd/system/docker.service
```

docker启动:
```bash
systemctl daemon-reload
systemctl enable docker
systemctl start docker
systemctl status docker
```

### 镜像下载
由于kubernetes需要访问grc.io，国内无法访问。可以在安装完成docker后，先下载对应的docker镜像：
```bash
images=(pause-amd64:3.0 kubernetes-dashboard-amd64:v1.5.0)
for imageName in ${images[@]} ; do
  docker pull mritd/$imageName
  docker tag mritd/$imageName gcr.io/google_containers/$imageName
  docker rmi mritd/$imageName
done
```

### 修改配置
192.168.10.6执行：
```bash
hostnamectl --static set-hostname k8s-master


#初始化目录
mkdir -p /etc/kubernetes/ssl/

# 不重启情况下使内核生效
sysctl kernel.hostname=k8s-master

echo '192.168.10.6 k8s-master
192.168.10.7   k8s-node1
192.168.10.8   k8s-node2' >> /etc/hosts

#采用直接路由，docker0的网段不能一样，所以需要修改docker的子网地址--bip=10.1.10.1/24
#vim /usr/lib/systemd/system/docker.service
#在/etc/sysconfig/docker的OPTIONS添加：(1.10版本才生效)
sed -i "s;^ExecStart=/usr/bin/dockerd.*;ExecStart=/usr/bin/dockerd --bip=10.1.10.1/24 \
--registry-mirror=http://3fecfd09.m.daocloud.io;" \
 /usr/lib/systemd/system/docker.service

systemctl daemon-reload
systemctl restart docker

#打通router
##192.168.10.6:
#route add -net 10.1.20.0 netmask 255.255.255.0 gw 192.168.10.7
#route add -net 10.1.30.0 netmask 255.255.255.0 gw 192.168.10.8
##192.168.10.7:
#route add -net 10.1.10.0 netmask 255.255.255.0 gw 192.168.10.6
#route add -net 10.1.30.0 netmask 255.255.255.0 gw 192.168.10.8
##192.168.10.8:
#route add -net 10.1.10.0 netmask 255.255.255.0 gw 192.168.10.6
#route add -net 10.1.20.0 netmask 255.255.255.0 gw 192.168.10.7

#手动打通路由比较麻烦，建议通过Quagga打通
docker pull index.alauda.cn/georce/router
#保存至文件，下次可以直接导入，不用再下载
#docker save -o /docker/works/images/k8s/tar/quagga.tar
#docker load -i /docker/works/images/k8s/tar/quagga.tar
docker run -itd --name=router --privileged --net=host index.alauda.cn/georce/router
#注意，系统重启时要自动启动quagga，否则会有问题。可以把以下命令加到/etc/rc.local中：
#docker start `docker ps -a |grep 'index.alauda.cn/georce/router'|awk '{print $1}'`
echo "docker start \`docker ps -a |grep 'index.alauda.cn/georce/router'|awk '{print \$1}'\`" >> /etc/rc.local
#执行 ip route 查看下路由表，已有别的docker0的网段信息。
```

192.168.10.7执行：
```bash
hostnamectl --static set-hostname k8s-node1

#初始化目录
/etc/kubernetes/ssl/

# 不重启情况下使内核生效
sysctl kernel.hostname=k8s-node1

echo '192.168.10.6 k8s-master
192.168.10.7   k8s-node1
192.168.10.8   k8s-node2' >> /etc/hosts

#采用直接路由，docker0的网段不能一样，所以需要修改docker的子网地址--bip=10.1.20.1/24
#vim /usr/lib/systemd/system/docker.service
#在/etc/sysconfig/docker的OPTIONS添加：(1.10版本才生效)
sed -i "s;^ExecStart=/usr/bin/dockerd.*;ExecStart=/usr/bin/dockerd --bip=10.1.20.1/24 \
--registry-mirror=http://3fecfd09.m.daocloud.io;" \
 /usr/lib/systemd/system/docker.service

systemctl daemon-reload
systemctl restart docker

#手动打通路由比较麻烦，建议通过Quagga打通
docker pull index.alauda.cn/georce/router
#保存至文件，下次可以直接导入，不用再下载
#docker save -o /docker/works/images/k8s/tar/quagga.tar
#docker load -i /docker/works/images/k8s/tar/quagga.tar
docker run -itd --name=router --privileged --net=host index.alauda.cn/georce/router
#注意，系统重启时要自动启动quagga，否则会有问题。可以把以下命令加到/etc/rc.local中：
#docker start `docker ps -a |grep 'index.alauda.cn/georce/router'|awk '{print $1}'`
echo "docker start \`docker ps -a |grep 'index.alauda.cn/georce/router'|awk '{print $1}'\`" >> /etc/rc.local
#执行 ip route 查看下路由表，已有别的docker0的网段信息。
```

192.168.10.8执行：
```bash
hostnamectl --static set-hostname k8s-node2

#初始化目录
/etc/kubernetes/ssl/

# 不重启情况下使内核生效
sysctl kernel.hostname=k8s-node2

echo '192.168.10.6 k8s-master
192.168.10.7   k8s-node1
192.168.10.8   k8s-node2' >> /etc/hosts

#采用直接路由，docker0的网段不能一样，所以需要修改docker的子网地址--bip=10.1.30.1/24
#vim /usr/lib/systemd/system/docker.service
#在/etc/sysconfig/docker的OPTIONS添加：(1.10版本才生效)
sed -i "s;^ExecStart=/usr/bin/dockerd.*;ExecStart=/usr/bin/dockerd --bip=10.1.30.1/24 \
--registry-mirror=http://3fecfd09.m.daocloud.io;" \
 /usr/lib/systemd/system/docker.service

systemctl daemon-reload
systemctl restart docker

#手动打通路由比较麻烦，建议通过Quagga打通
docker pull index.alauda.cn/georce/router
#保存至文件，下次可以直接导入，不用再下载
#docker save -o /docker/works/images/k8s/tar/quagga.tar
#docker load -i /docker/works/images/k8s/tar/quagga.tar
docker run -itd --name=router --privileged --net=host index.alauda.cn/georce/router
#注意，系统重启时要自动启动quagga，否则会有问题。可以把以下命令加到/etc/rc.local中：
#docker start `docker ps -a |grep 'index.alauda.cn/georce/router'|awk '{print $1}'`
echo "docker start \`docker ps -a |grep 'index.alauda.cn/georce/router'|awk '{print $1}'\`" >> /etc/rc.local
#执行 ip route 查看下路由表，已有别的docker0的网段信息。
```

## 安装kubernetes

### yum安装

每台添加yum源：
```bash
tee /etc/yum.repos.d/k8s.repo <<-'EOF'
[k8s-repo]
name=kubernetes Repository
baseurl=https://rpm.mritd.me/centos/7/x86_64
enabled=1
gpgcheck=1
gpgkey=https://cdn.mritd.me/keys/rpm.public.key
EOF
```
如果这个源不稳定的话，可以下载我创建好的源，直接通过yum localinstall *.rpm方式安装
```bash
git clone https://git.coding.net/zhaoxunyong/repo.git
cd repo/yum/kubernetes/x86_64
yum -y localinstall kubernetes-1.5.1-git82450d0.el7.centos.x86_64.rpm
```

*** master(192.168.10.6)执行 ***
```bash
yum install -y etcd kubernetes
```

其他安装：
```bash
yum -y install kubernetes
```

### 二进制安装
```bash
wget https://storage.googleapis.com/kubernetes-release/release/v1.5.1/kubernetes.tar.gz
tar zxvf kubernetes.tar.gz
#下载对应的server与client文件
cd kubernetes
sh cluster/get-kube-binaries.sh
```

下载好的文件分别位于：
```bash
server/kubernetes-server-linux-amd64.tar.gz
client/kubernetes-client-linux-amd64.tar.gz
```

具体安装步骤稍后补充

## rpm方式配置kubernetes
### master(192.168.10.6)执行

#### 证书制作
如果不采用证书方式安装，请略过此节。
##### 自签 CA
```bash
# 创建证书存放目录
mkdir cert && cd cert
# 创建 CA 私钥
openssl genrsa -out ca-key.pem 2048
# 自签 CA
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kube-ca"
```

##### 签署 apiserver 证书
首先先修改openssl的配置
```bash
# 复制 openssl 配置文件
#cp /etc/pki/tls/openssl.cnf .
# 编辑 openssl 配置使其支持 IP 认证
vim openssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
# kubernetes server ip
IP.1 = 10.254.0.1
# master ip(如果都在一台机器上写一个就行)
IP.2 = 192.168.10.6
```

##### 签署apiserver相关的证书
```bash
# 生成apiserver私钥
openssl genrsa -out apiserver-key.pem 2048
# 生成签署请求
openssl req -new -key apiserver-key.pem -out apiserver.csr -subj "/CN=kube-apiserver" -config openssl.cnf
# 使用自建 CA 签署
openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 365 -extensions v3_req -extfile openssl.cnf
```

##### 签署 node 的证书

还需要签署每个节点的证书先修改一下openssl配置
```bash
# copy master 的 openssl 配置
#cp openssl.cnf worker-openssl.cnf
# 修改 worker-openssl 配置
vim worker-openssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
# 此处填写node的内网ip，多个node ip地址以此类推IP.2 = NODE2-IP
IP.1 = 192.168.10.7
IP.2 = 192.168.10.8
```

签署node1的证书

```bash
# 生成 node1 私钥
openssl genrsa -out node1-worker-key.pem 2048
# 生成 签署请求
openssl req -new -key node1-worker-key.pem -out node1-worker.csr -subj "/CN=node1" -config worker-openssl.cnf
# 使用自建 CA 签署
openssl x509 -req -in node1-worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out node1-worker.pem -days 365 -extensions v3_req -extfile worker-openssl.cnf
```

签署node2的证书
```bash
# 生成 node2 私钥
openssl genrsa -out node2-worker-key.pem 2048
# 生成 签署请求
openssl req -new -key node2-worker-key.pem -out node2-worker.csr -subj "/CN=node2" -config worker-openssl.cnf
# 使用自建 CA 签署
openssl x509 -req -in node2-worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out node2-worker.pem -days 365 -extensions v3_req -extfile worker-openssl.cnf
```

##### 生成集群管理证书
```bash
# 签署一个集群管理证书
openssl genrsa -out admin-key.pem 2048
openssl req -new -key admin-key.pem -out admin.csr -subj "/CN=kube-admin"
openssl x509 -req -in admin.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out admin.pem -days 365
```

##### 配置证书

##### 生成kubeconfig.yaml文件
此文件供需要通过证书方式访问apiserver时使用：
```bash
[root@k8s-master ~]$ vim kubeconfig.yaml
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/ssl/ca.pem
    server: https://192.168.10.6:6443
  name: default-cluster
contexts:
- context:
    cluster: default-cluster
    user: default-admin
  name: default-system
current-context: default-system
kind: Config
users:
- name: default-admin
  user:
    client-certificate: /etc/kubernetes/ssl/admin.pem
    client-key: /etc/kubernetes/ssl/admin-key.pem
```

##### 生成worker1-kubeconfig.yaml文件
此文件供需要通过证书方式访问kubelet时使用：
```bash
[root@k8s-master ~]$ vim worker1-kubeconfig.yaml
apiVersion: v1
kind: Config
clusters:
- name: local
  cluster:
    certificate-authority: /etc/kubernetes/ssl/ca.pem
users:
- name: kubelet
  user:
    client-certificate: /etc/kubernetes/ssl/node1-worker.pem
    client-key: /etc/kubernetes/ssl/node1-worker-key.pem
contexts:
- context:
    cluster: local
    user: kubelet
  name: kubelet-context
current-context: kubelet-context
```

##### 生成worker2-kubeconfig.yaml文件
此文件供需要通过证书方式访问kubelet时使用：
```bash
[root@k8s-master ~]$ vim worker2-kubeconfig.yaml
apiVersion: v1
kind: Config
clusters:
- name: local
  cluster:
    certificate-authority: /etc/kubernetes/ssl/ca.pem
users:
- name: kubelet
  user:
    client-certificate: /etc/kubernetes/ssl/node2-worker.pem
    client-key: /etc/kubernetes/ssl/node2-worker-key.pem
contexts:
- context:
    cluster: local
    user: kubelet
  name: kubelet-context
current-context: kubelet-context
```

##### copy证书
```bash
# 先把证书 copy 到配置目录
mkdir -p /etc/kubernetes/ssl
/bin/cp -a ca.pem apiserver.pem apiserver-key.pem \
  admin.pem admin-key.pem \
  kubeconfig.yaml \
  /etc/kubernetes/ssl
# rpm 安装的 kubernetes 默认使用 kube 用户，需要更改权限
chown kube:kube -R /etc/kubernetes/ssl

# copy证书到所有node节点：
scp kubeconfig.yaml admin.pem admin-key.pem ca.pem \
 node1-worker.pem node1-worker-key.pem worker1-kubeconfig.yaml root@192.168.10.7:/etc/kubernetes/ssl/

scp kubeconfig.yaml admin.pem admin-key.pem ca.pem \
 node2-worker.pem node2-worker-key.pem worker2-kubeconfig.yaml root@192.168.10.8:/etc/kubernetes/ssl/

```

#### etcd
```bash

sed -i 's;^ETCD_LISTEN_CLIENT_URLS=.*;ETCD_LISTEN_CLIENT_URLS="http://localhost:2379,http://192.168.10.6:2379";' /etc/etcd/etcd.conf
sed -i 's;^ETCD_ADVERTISE_CLIENT_URLS=.*;ETCD_ADVERTISE_CLIENT_URLS="http://localhost:2379,http://192.168.10.6:2379";' /etc/etcd/etcd.conf

[root@k8s-master ~]$ grep -v ^# /etc/etcd/etcd.conf 
ETCD_NAME=default
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_CLIENT_URLS="http://localhost:2379,http://192.168.10.6:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://localhost:2379,http://192.168.10.6:2379"

systemctl restart etcd.service
systemctl enable etcd.service
systemctl status etcd.service

etcdctl cluster-health
#member 8e9e05c52164694d is healthy: got healthy result from http://192.168.10.6:2379
#cluster is healthy

etcdctl member list
#8e9e05c52164694d: name=default peerURLs=http://localhost:2380 clientURLs=http://192.168.10.6:2379,http://localhost:2379 isLeader=true
```

#### config
```bash
tee /etc/kubernetes/config <<-'EOF'
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow-privileged=false"
KUBE_MASTER="--master=https://192.168.10.6:6443"
EOF

[root@k8s-master ~]$ grep -v ^# /etc/kubernetes/config
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow-privileged=false"
KUBE_MASTER="--master=https://192.168.10.6:6443"
```

#### apiserver
修改：
```bash
tee /etc/kubernetes/apiserver <<-'EOF'
KUBE_API_ADDRESS="--bind-address=192.168.10.6 --insecure-bind-address=127.0.0.1"
KUBE_API_PORT="--secure-port=6443 --insecure-port=8080"
KUBE_ETCD_SERVERS="--etcd-servers=http://192.168.10.6:2379"
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"
KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota"
KUBE_API_ARGS="--tls-cert-file=/etc/kubernetes/ssl/apiserver.pem --tls-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem --client-ca-file=/etc/kubernetes/ssl/ca.pem --service-account-key-file=/etc/kubernetes/ssl/apiserver-key.pem"
EOF

[root@k8s-master ~]$ grep -v ^# /etc/kubernetes/apiserver
KUBE_API_ADDRESS="--bind-address=192.168.10.6 --insecure-bind-address=127.0.0.1"
KUBE_API_PORT="--secure-port=6443 --insecure-port=8080"
KUBE_ETCD_SERVERS="--etcd-servers=http://192.168.10.6:2379"
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"
KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota"
KUBE_API_ARGS="--tls-cert-file=/etc/kubernetes/ssl/apiserver.pem --tls-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem --client-ca-file=/etc/kubernetes/ssl/ca.pem --service-account-key-file=/etc/kubernetes/ssl/apiserver-key.pem"
```

如果不使用证书的话：
```bash
[root@k8s-master ~]$ grep -v ^# /etc/kubernetes/apiserver
KUBE_API_ADDRESS="--address=0.0.0.0"
KUBE_API_PORT="port=8080"
KUBE_ETCD_SERVERS="--etcd-servers=http://192.168.10.6:2379"
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"
KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota"
KUBE_API_ARGS=""
```

启动：
```bash
systemctl enable kube-apiserver
systemctl restart kube-apiserver
systemctl status kube-apiserver
```

#### controller-manager
修改：
```bash
tee /etc/kubernetes/controller-manager <<-'EOF'
KUBE_CONTROLLER_MANAGER_ARGS="--service-account-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem  --root-ca-file=/etc/kubernetes/ssl/ca.pem --master=http://127.0.0.1:8080"
EOF

[root@k8s-master ~]$ grep -v ^# /etc/kubernetes/controller-manager
KUBE_CONTROLLER_MANAGER_ARGS="--service-account-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem  --root-ca-file=/etc/kubernetes/ssl/ca.pem --master=http://127.0.0.1:8080"
```

如果不使用证书的话：
```bash
KUBE_CONTROLLER_MANAGER_ARGS=""
```

启动：
```bash
systemctl enable kube-controller-manager
systemctl restart kube-controller-manager
systemctl status kube-controller-manager
```

#### scheduler
修改：
```bash
tee /etc/kubernetes/scheduler <<-'EOF'
KUBE_SCHEDULER_ARGS="--kubeconfig=/docker/k8s/kubernetes/config"
EOF

[root@k8s-master ~]$ grep -v ^# /etc/kubernetes/scheduler
KUBE_SCHEDULER_ARGS="--kubeconfig=/etc/kubernetes/ssl/kubeconfig.yaml"
```

如果不使用证书的话：
```bash
KUBE_SCHEDULER_ARGS=""
```

启动：
```bash
systemctl enable kube-scheduler
systemctl restart kube-scheduler
systemctl status kube-scheduler
```

#### kube-dns
参考：
> http://www.pangxie.space/docker/1055
> https://my.oschina.net/fufangchun/blog/732762
> https://seanzhau.com/blog/post/seanzhau/6261234da213

随便说一下kube-dns的作用：
kubernetes服务发现有两种：
> 环境变量方式:  这种方式必须要先创建service再创建pod，否则pod中没有对应的环境变量
> dns服务方式:  通过dns解析对应的服务，推荐使用。

域名规则：
SERVICENAME.NAMESPACENAME.svc.CLUSTERDOMAIN
- SERVICENAME：每个Service的名字
- NAMESPACENAME：Service所属的namespace的名字
- svc：固定值
- CLUSTERDOMAIN：集群内部的域名

解析特点：
从上面可以看出，我们的域名是又臭又长，看起来很不爽。但是在kubernetes集群中，我们在解析的时候不是必须完全输入完才可以解析。在同一个命令空间下如果我们引用的话，只需要引用对应的Service的名字。如果引用了非同一命名空间下的Service，那么我们只需要加上其对应的命名空间的名字即可。 
例如： 
a命名空间(namespace)下有个Service:s1 App: a1，b命名空间(namespace)下有个Service:s2 App: a2 
现在App a1中需要使用a1 和 a2，那么只需要写出 a1 和 a2.b即可。反过来a2也是这样。

kube-dns为1.3新增的功能，不用再手动安装skyDns，使用更方便，但没有包括在rpm包中。我们可以手动从二进制包中copy到/usr/bin目录中:
```bash
cp kube-dns /usr/bin/

#新建kube-dns配置文件
tee /etc/kubernetes/kube-dns <<-'EOF'
# kubernetes kube-dns config
KUBE_DNS_PORT="--dns-port=53"
KUBE_DNS_DOMAIN="--domain=k8s.zxy.com"
#KUBE_DNS_MASTER="--kube-master-url=http://127.0.0.1:8080"
KUBE_DNS_ARGS="--kubecfg-file=/etc/kubernetes/ss/kubeconfig.yaml"
EOF

[root@k8s-master]# grep -v ^# /etc/kubernetes/kube-dns
###
# kubernetes kube-dns config
KUBE_DNS_PORT="--dns-port=53"
KUBE_DNS_DOMAIN="--domain=k8s.zxy.com"
KUBE_DNS_ARGS="--kubecfg-file=/etc/kubernetes/ssl/kubeconfig.yaml"
```

如果不使用证书的话：
```bash
KUBE_DNS_PORT="--dns-port=53"
KUBE_DNS_DOMAIN="--domain=k8s.zxy.com"
KUBE_DNS_MASTER="--kube-master-url=http://127.0.0.1:8080"
KUBE_DNS_ARGS=""
```
 
新建kube-dns.service配置文件
```bash
tee /usr/lib/systemd/system/kube-dns.service <<-'EOF'
[Unit]
Description=Kubernetes Kube-dns Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=kube-apiserver.service
Requires=kube-apiserver.service
 
[Service]
WorkingDirectory=/var/lib/kube-dns
EnvironmentFile=-/etc/kubernetes/kube-dns
ExecStart=/usr/bin/kube-dns \
            $KUBE_DNS_PORT \
            $KUBE_DNS_DOMAIN \
            $KUBE_DNS_MASTER \
            $KUBE_DNS_ARGS
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
EOF
```

创建工作目录：
```bash
mkdir -p /var/lib/kube-dns
```

启动：
```bash
systemctl enable kube-dns
systemctl restart kube-dns
systemctl status kube-dns
```
注意：kube-dns重启好慢...

#### 修改/etc/resolv.conf
master主机添加域名：
```bash
tee /etc/resolv.conf <<-'EOF'
# k8s.zxy.com为对应的域名，其他保存不变
search default.svc.k8s.zxy.com svc.k8s.zxy.com k8s.zxy.com
# dns服务的ip
nameserver 192.168.10.6
 
nameserver 8.8.8.8
nameserver 114.114.114.114
EOF
```

测试：
```bash
nslookup -type=srv kubernetes
Server:         192.168.10.6
Address:        192.168.10.6#53

kubernetes.default.svc.k8s.zxy.com  service = 10 100 0 3563366661643766.kubernetes.default.svc.k8s.zxy.com.

curl http://127.0.0.1:8081/readiness
ok
curl http://127.0.0.1:8081/cache
```


### node1(192.168.10.7)执行

#### 修改/etc/resolv.conf
添加域名：
```bash
tee /etc/resolv.conf <<-'EOF'
# k8s.zxy.com为对应的域名，其他保存不变
search default.svc.k8s.zxy.com svc.k8s.zxy.com k8s.zxy.com
# dns服务的ip
nameserver 192.168.10.6
 
nameserver 8.8.8.8
nameserver 114.114.114.114
EOF
```

#### config
修改：
```bash
tee /etc/kubernetes/config <<-'EOF'
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow-privileged=false"
KUBE_MASTER="--master=https://192.168.10.6:6443"
EOF

[root@k8s-node1 ~]$ grep -v ^# /etc/kubernetes/config
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow-privileged=false"
KUBE_MASTER="--master=https://192.168.10.6:6443"
```

如果不使用证书的话：
```bash
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
KUBE_ALLOW_PRIV="--allow-privileged=false"
KUBE_MASTER="--master=http://127.0.0.1:8080"
```

#### kubelet
修改：
```bash
tee /etc/kubernetes/kubelet <<-'EOF'
KUBELET_ADDRESS="--address=192.168.10.7"
KUBELET_HOSTNAME="--hostname-override=k8s-node1"
KUBELET_API_SERVER="--api-servers=https://192.168.10.6:6443"
KUBELET_ARGS="--tls-cert-file=/etc/kubernetes/ssl/node1-worker.pem --tls-private-key-file=/etc/kubernetes/ssl/node1-worker-key.pem --kubeconfig=/etc/kubernetes/ssl/worker1-kubeconfig.yaml --cluster-domain=k8s.zxy.com --cluster-dns=192.168.10.6"
EOF

[root@k8s-node1 ~]$ grep -v ^# /etc/kubernetes/kubelet 
KUBELET_ADDRESS="--address=192.168.10.7"
KUBELET_HOSTNAME="--hostname-override=k8s-node1"
KUBELET_API_SERVER="--api-servers=https://192.168.10.6:6443"
KUBELET_ARGS="--tls-cert-file=/etc/kubernetes/ssl/node1-worker.pem --tls-private-key-file=/etc/kubernetes/ssl/node1-worker-key.pem --kubeconfig=/etc/kubernetes/ssl/worker1-kubeconfig.yaml --cluster-domain=k8s.zxy.com --cluster-dns=192.168.10.6"
```

如果不使用证书的话：
```bash
KUBELET_ADDRESS="--address=192.168.10.7"
KUBELET_HOSTNAME="--hostname-override=k8s-node1"
KUBELET_API_SERVER="--api-servers=http://192.168.10.6:8080"
KUBELET_ARGS="--cluster-domain=k8s.zxy.com --cluster-dns=192.168.10.6"
```

启动：
```bash
systemctl enable kubelet
systemctl restart kubelet
systemctl status kubelet
```

#### kube-proxy
修改：
```bash
tee /etc/kubernetes/proxy <<-'EOF'
KUBE_PROXY_ARGS="--kubeconfig=/etc/kubernetes/ssl/worker1-kubeconfig.yaml"
EOF

[root@k8s-node1 ~]$ grep -v ^# /etc/kubernetes/proxy
KUBE_PROXY_ARGS="--kubeconfig=/etc/kubernetes/ssl/worker1-kubeconfig.yaml"
```

如果不使用证书的话：
```bash
KUBE_PROXY_ARGS=""
```


启动：
```bash
systemctl enable kube-proxy
systemctl restart kube-proxy
systemctl status kube-proxy
```

查看日志：
```bash
[root@k8s-node1 ~]$ tail -n10 -f /var/log/messages  
Jan  4 06:40:49 localhost systemd: Configuration file /usr/lib/systemd/system/wpa_supplicant.service is marked executable. Please remove executable permission bits. Proceeding anyway.
Jan  4 06:40:49 localhost systemd: Started Kubernetes Kube-Proxy Server.
Jan  4 06:40:49 localhost systemd: Starting Kubernetes Kube-Proxy Server...
Jan  4 06:40:50 localhost kube-proxy: I0104 14:40:50.171482   12524 server.go:215] Using iptables Proxier.
Jan  4 06:40:50 localhost kube-proxy: W0104 14:40:50.174673   12524 proxier.go:254] clusterCIDR not specified, unable to distinguish between internal and external traffic
Jan  4 06:40:50 localhost kube-proxy: I0104 14:40:50.174701   12524 server.go:227] Tearing down userspace rules.
Jan  4 06:40:50 localhost kube-proxy: I0104 14:40:50.188726   12524 conntrack.go:81] Set sysctl 'net/netfilter/nf_conntrack_max' to 131072
Jan  4 06:40:50 localhost kube-proxy: I0104 14:40:50.189159   12524 conntrack.go:66] Setting conntrack hashsize to 32768
Jan  4 06:40:50 localhost kube-proxy: I0104 14:40:50.189401   12524 conntrack.go:81] Set sysctl 'net/netfilter/nf_conntrack_tcp_timeout_established' to 86400
Jan  4 06:40:50 localhost kube-proxy: I0104 14:40:50.189418   12524 conntrack.go:81] Set sysctl 'net/netfilter/nf_conntrack_tcp_timeout_close_wait' to 3600
```

#### node监控(ctAdvisor)
http://192.168.10.7:4194/

### node2(192.168.10.8)执行
同node1一样，以下内容会有所不一样：
```bash
#kubelet
KUBELET_ADDRESS="--address=192.168.10.8"
KUBELET_HOSTNAME="--hostname-override=k8s-node2"
KUBELET_ARGS="--tls-cert-file=/etc/kubernetes/ssl/node2-worker.pem --tls-private-key-file=/etc/kubernetes/ssl/node2-worker-key.pem --kubeconfig=/etc/kubernetes/ssl/worker2-kubeconfig.yaml --cluster-domain=k8s.zxy.com --cluster-dns=192.168.10.6"

#proxy
KUBE_PROXY_ARGS="--master=https://192.168.10.6:6443 --kubeconfig=/etc/kubernetes/ssl/worker1-kubeconfig.yaml"
```

启动服务
```bash
for SERVICES in kubelet kube-proxy; do
systemctl enable $SERVICES
systemctl start $SERVICES
systemctl status $SERVICES
done

### 测试
重启master所有服务：
```bash
for SERVICES in etcd kube-dns kube-apiserver kube-controller-manager kube-scheduler; do
systemctl restart $SERVICES
systemctl status $SERVICES
done
```

重启node所有服务：
```bash
for SERVICES in kubelet kube-proxy; do
systemctl restart $SERVICES
systemctl status $SERVICES
done
```

在master中可以查看node:
```bash
[root@k8s-master ~]$ kubectl get node
NAME        STATUS    AGE
k8s-node1   Ready     12m
k8s-node2   Ready     7m
#非master需要：
[root@k8s-master ~]$ kubectl --kubeconfig=/etc/kubernetes/ssl/kubeconfig.yaml get node
NAME        STATUS    AGE
k8s-node1   Ready     12m
k8s-node2   Ready     7m

[root@k8s-master ~]$ curl https://192.168.10.6:6443/api/v1/nodes \
  --cert /etc/kubernetes/ssl/apiserver.pem --key /etc/kubernetes/ssl/apiserver-key.pem --cacert /etc/kubernetes/ssl/ca.pem

#node中开启代理
[root@k8s-node1 ~]$ kubectl --kubeconfig=/etc/kubernetes/ssl/kubeconfig.yaml proxy  
```

## 二进制方式配置kubernetes
二进制方式与rpm方式差不多，此处只简单列出非加密方式的启动命令:

### master
kube-apiserver:
```bash
/usr/bin/kube-apiserver --logtostderr=true --v=0 \
  --etcd-servers=http://192.168.10.6:2379 \
  --address=0.0.0.0 port=8080 \
  --allow-privileged=false \
  --service-cluster-ip-range=10.254.0.0/16 \
  --admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota
```

kube-controller-manager:
```bash
/usr/bin/kube-controller-manager --logtostderr=true --v=0 --master=http://127.0.0.1:8080
```

kube-scheduler:
```bash
/usr/bin/kube-scheduler --logtostderr=true --v=0 --master=http://192.168.10.6:8080
```

kube-dns:
```bash
/usr/bin/kube-dns --dns-port=53 --domain=k8s.zxy.com --kube-master-url=http://127.0.0.1:8080
```

### node
kube-proxy:
```bash
/usr/bin/kube-proxy --logtostderr=true --v=0 --master=http://192.168.10.6:8080
```

kubelet:
```bash
/usr/bin/kubelet --logtostderr=true --v=0 \
  --api-servers=http://192.168.10.6:8080 \
  --address=192.168.10.7 \
  --hostname-override=k8s-node1 \
  --allow-privileged=false --cluster-domain=k8s.zxy.com --cluster-dns=192.168.10.6
```




## kube-dashboard
### 创建
对应的yaml文件可以参考[dashborad](https://github.com/zhaoxunyong/blog/tree/master/backup/k8s/yaml/dashborad)

如果apiserver为非加密方式，需要添加args参数(与ports平行)：
```bash
args:
 - --apiserver-host=http://127.0.0.1:8080
```

开始创建：
```bash
git clone https://github.com/kubernetes/kubernetes.git
cd kubernetes/cluster/addons/dashboard/

#docker load -i /docker/works/images/k8s/tar/kubernetes-dashboard-amd64.tar
#docker load -i /docker/works/images/k8s/tar/pause-amd64.tar

#create service
[root@k8s-master ~]$ kubectl create -f dashboard-service.yaml 
service "kubernetes-dashboard" created

# 查看service
[root@k8s-master ~]$ kubectl get svc -o wide -n kube-system
NAME                   CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE       SELECTOR
kubernetes-dashboard   10.254.142.79   <none>        80/TCP    12s       k8s-app=kubernetes-dashboard

# create rc
[root@k8s-master ~]$ kubectl create -f dashboard-controller.yaml 
replicationcontroller "kubernetes-dashboard-v1.5.0" created
```

如出现以下的日志表示创建成功：
```bash
[root@k8s-master dashboard]# kubectl logs kubernetes-dashboard-v1.5.0-fnlhb -n kube-system
Using HTTP port: 9090
Creating API server client for https://10.254.0.1:443
Successful initial request to the apiserver, version: 1.5.1
Creating in-cluster Heapster client
```

### 异常解决
#### ContainerCreating

查看pod:
```bash
[root@k8s-master ~]$ kubectl get po -o wide -n kube-system
NAME                                READY     STATUS              RESTARTS   AGE       IP        NODE
kubernetes-dashboard-v1.5.0-7tjjx   0/1       ContainerCreating   0          1m        <none>    k8s-node2
```
查看pod详情:
```bash
[root@k8s-master dashboard]# kubectl describe pod kubernetes-dashboard-v1.5.0-7tjjx -n kube-system    
...
Events:
  FirstSeen     LastSeen        Count   From                    SubObjectPath   Type            Reason          Message
  ---------     --------        -----   ----                    -------------   --------        ------          -------
  2m            2m              1       {default-scheduler }                    Normal          Scheduled       Successfully assigned kubernetes-dashboard-v1.5.0-7tjjx to k8s-node2
  1m            27s             2       {kubelet k8s-node2}                     Warning         FailedSync      Error syncing pod, skipping: failed to "StartContainer" for "POD" with ErrImagePull: "image pull failed for gcr.io/google_containers/pause-amd64:3.0, this may be because there are no credentials on this request.  details: (Error response from daemon: {\"message\":\"Get https://gcr.io/v1/_ping: dial tcp 74.125.204.82:443: i/o timeout\"})"

  12s   12s     1       {kubelet k8s-node2}             Warning FailedSync      Error syncing pod, skipping: failed to "StartContainer" for "POD" with ImagePullBackOff: "Back-off pulling image \"gcr.io/google_containers/pause-amd64:3.0\""
```
通过日志可以看到连不到gcr.io，需要事先下载：
> gcr.io/google_containers/pause-amd64:3.0
> gcr.io/google_containers/kubernetes-dashboard-amd64:v1.5.0
注意：需要下载并导入到node节点，而不是master节点。具体请参考[镜像下载](#镜像下载)

#### CrashLoopBackOff
> 参考：https://github.com/kubernetes/dashboard/issues/374
查看pod日志：
```bash
kubectl logs kubernetes-dashboard-v1.5.0-sp8qv -n kube-system            
Using HTTP port: 9090
Creating API server client for https://10.254.0.1:443
Error while initializing connection to Kubernetes apiserver. This most likely means that the cluster is misconfigured (e.g., it has invalid apiserver certificates or service accounts configuration) or the --apiserver-host param points to a server that does not exist. Reason: the server has asked for the client to provide credentials
Refer to the troubleshooting guide for more information: https://github.com/kubernetes/dashboard/blob/master/docs/user-guide/troubleshooting.md
```

请安装以下方式操作：
```bash
[root@k8s-master ~]$ kubectl get secrets --namespace=kube-system
NAME                  TYPE                                  DATA      AGE
default-token-fwvl9   kubernetes.io/service-account-token   3         1h

#kubectl delete secret `kubectl get secrets --namespace=kube-system |awk '{print $1}' | sed -e '1d'` --namespace=kube-system
[root@k8s-master ~]$ kubectl delete secret default-token-fwvl9 --namespace=kube-system
secret "default-token-fwvl9" deleted

[root@k8s-master ~]$ kubectl get rc -n kube-system
NAME                          DESIRED   CURRENT   READY     AGE
kubernetes-dashboard-v1.5.0   1         1         0         6m

#kubectl delete rc `kubectl get rc -n kube-system |awk '{print $1}' | sed -e '1d'` --namespace=kube-system 
[root@k8s-master ~]$ kubectl delete rc kubernetes-dashboard-v1.5.0 --namespace=kube-system      
replicationcontroller "kubernetes-dashboard-v1.5.0" deleted

[root@k8s-master ~]$ kubectl create -f dashboard-controller.yaml 
replicationcontroller "kubernetes-dashboard-v1.5.0" created
```

访问：
https://192.168.10.6:6443/ui
如果提示Unauthorized的话，需要在/etc/kubernetes/apiserver中KUBE_API_ARGS参数后添加：
```bash
KUBE_API_ARGS="--basic-auth-file=/etc/kubernetes/basic_auth.csv"
```

basic_auth.csv格式为：
```bash
password,username,uid
```

重启服务：
```bash
systemctl daemon-reload
systemctl restart kube-apiserver
```

具体node请用get pod命令查看:
```bash
kubectl get pod -o wide -n kube-system
NAME                                READY     STATUS    RESTARTS   AGE       IP          NODE
kubernetes-dashboard-v1.5.0-8hsb9   1/1       Running   0          13m       10.1.20.2   k8s-node1
```

## 创建服务
> 参考：http://running.iteye.com/blog/2322959
本例以kubernetes源码中的guestbook为例讲解如何创建服务

先下载源码：
```bash
#docker load -i /docker/works/images/others/redis-master.tar
#docker load -i /docker/works/images/others/guestbook-redis-slave.tar
#docker load -i /docker/works/images/others/guestbook-php-frontend.tar
git clone https://github.com/kubernetes/kubernetes.git
cd examples/guestbook/
```
由于不能访问gcr.io，可以修改相应的yaml文件：
修改legacy/redis-master-controller.yaml中的images，替换:
```bash
image: gcr.io/google_containers/redis:e2e  # or just image: redis
```
为
```bash
image: kubeguide/redis-master
imagePullPolicy: IfNotPresent
```

修改legacy/redis-slave-controller.yaml中的images，替换：
```bash
image: gcr.io/google_samples/gb-redisslave:v1
```
为
```bash
image: kubeguide/guestbook-redis-slave
imagePullPolicy: IfNotPresent
```
并添加：
```bash
env:
- name: GET_HOSTS_FROM
  value: env
```

修改frontend-service.yaml，添加：
```bash
type: NodePort
  ports:
  - port: 80
    nodePort: 30001
```
添加type: NodePort与nodePort: 30001参数，对外暴露30001

暴露对外端口方式：
1. 在service中通过nodePort定义：
```bash
type: NodePort
  ports:
  - port: 80
    nodePort: 30001
```
 其中端口号必须在：30000-32767之间

2. 通过rc定义：
```bash
ports:
 - containerPort: 80
   hostPort: 80
```

创建redis-master的service与rc:
```bash
kubectl create -f redis-slave-service.yaml
kubectl create -f legacy/redis-master-controller.yaml
```

创建redis-slave的service与rc:
```bash
kubectl create -f redis-slave-service.yaml
kubectl create -f legacy/redis-slave-controller.yaml
```

创建frontend的service与rc:
```bash
kubectl create -f frontend-service.yaml
kubectl create -f legacy/frontend-controller.yaml
```

或者直接下载已经修改后的[guestbook](https://github.com/zhaoxunyong/blog/tree/master/backup/k8s/examples/guestbook)

查看pod：
```bash
[root@k8s-master ~]$ kubectl get pod -o wide                                     
NAME                 READY     STATUS    RESTARTS   AGE       IP          NODE
frontend-5l5kp       1/1       Running   0          2s        10.1.20.3   k8s-node1
redis-master-2r7p7   1/1       Running   0          4m        10.1.30.2   k8s-node2
redis-slave-n6nz6    1/1       Running   0          2m        10.1.20.5   k8s-node1
redis-slave-rrl87    1/1       Running   0          2m        10.1.30.3   k8s-node2
```

异常问题：
该demo是基于环境变量，所以必须先创建service，再创建rc，否则会出现STATUS为Running，但功能会报错。

发现有一台始终没有iptables规则：
通过tail -n100 -f /var/log/message查看，发现有一台node，没有修改/etc/kubernetes/config中的apiserver的地址。

## docker registry
此章节为通过kubernetes方式部署。

```bash
git clone https://github.com/kubernetes/kubernetes.git
cd kubernetes/cluster/addons/registry
```
vim registry-pv.yaml
```bash
apiVersion: v1
kind: PersistentVolume
metadata:
  name: kube-system-kube-registry-pv
  labels:
    kubernetes.io/cluster-service: "true"
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: /data
  #nfs:
  #  path: /data/k8s
  #  server: 192.168.12.171
  persistentVolumeReclaimPolicy: Recycle
```

vim registry-pvc.yaml
```bash
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: kube-registry-pvc
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

创建：
```bash
kubectl create -f registry-pv.yaml 
kubectl create -f registry-pvc.yaml
``` 

查看pv：
```bash
kubectl get pv
```

新建registry svc和rc:
vim registry-rc.yaml 
```bash
apiVersion: v1
kind: ReplicationController
metadata:
  name: kube-registry-v0
  namespace: kube-system
  labels:
    k8s-app: kube-registry
    version: v0
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 1
  selector:
    k8s-app: kube-registry
    version: v0
  template:
    metadata:
      labels:
        k8s-app: kube-registry
        version: v0
        kubernetes.io/cluster-service: "true"
    spec:
      containers:
      - name: registry
        image: registry:2
        resources:
          # keep request = limit to keep this container in guaranteed class
          limits:
            cpu: 100m
            memory: 100Mi
          requests:
            cpu: 100m
            memory: 100Mi
        env:
        - name: REGISTRY_HTTP_ADDR
          value: :5000
        - name: REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY
          value: /var/lib/registry
        volumeMounts:
        - name: image-store
          mountPath: /var/lib/registry
        ports:
        - containerPort: 5000
          name: registry
          protocol: TCP
      volumes:
      - name: image-store
        persistentVolumeClaim:
          claimName: kube-registry-pvc
```

vim registry-svc.yaml
```bash
apiVersion: v1
kind: Service
metadata:
  name: kube-registry
  namespace: kube-system
  labels:
    k8s-app: kube-registry
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "KubeRegistry"
spec:
  selector:
    k8s-app: kube-registry
  type: NodePort
  ports:
  - name: registry
    port: 5000
    nodePort: 30009
    protocol: TCP
```

创建rc、svc:
```bash
kubectl create -f registry-rc.yaml 
kubectl create -f registry-svc.yaml
```

查看状态:
```bash
kubectl get svc --namespace=kube-system
```

每台修改docker的配置文件:
注意：insecure-registry不能加上http://
```bash
sed -i "s;^ExecStart=/usr/bin/dockerd.*;ExecStart=/usr/bin/dockerd --bip=10.1.20.1/24 \
  --insecure-registry=192.168.10.8:30009 \
  --registry-mirror=http://3fecfd09.m.daocloud.io;" \
 /usr/lib/systemd/system/docker.service
```

每台重启docker:
```bash
systemctl daemon-reload
systemctl restart docker
systemctl status docker
```

测试：
```bash
docker tag registry:2 192.168.10.8:30009/registry:2
docker push 192.168.10.8:30009/registry:2
```

## 参考
> http://blog.csdn.net/air_penguin/article/details/51350910
> https://mritd.me/2016/09/07/Kubernetes-%E9%9B%86%E7%BE%A4%E6%90%AD%E5%BB%BA/
> https://mritd.me/2016/09/11/kubernetes-%E5%8F%8C%E5%90%91-TLS-%E9%85%8D%E7%BD%AE/
> http://www.pangxie.space/docker/1055