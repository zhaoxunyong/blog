---
title: 使用Flannel搭建docker网络
date: 2017-01-16 17:18:45
categories: ["docker", "kubernetes"]
tags: ["docker", "kubernetes"]
toc: true
---
docker跨宿主机的网络解决方案有几种：
1. 直接路由+quagga
2. calico
3. flannel
4. weave

calico与flannel综合性能比还是很不错，建议使用。本文详细介绍flannel的安装与配置。

<!-- more -->

具体网络模型如图所示：
![flannel](/images/packet-01.png)

本文详细介绍一下flannel的安装与配置。

## 安装
### 安装etcd
参考[etcd集群安装](etcd集群安装.html)

### rpm安装

#### 安装
```bash
yum install -y flannel
```
版本：0.7.1

#### 配置
在etcd中设置flannel所使用的ip段:
```bash
etcdctl --endpoints "http://192.168.10.6:2379,http://192.168.10.7:2379,http://192.168.10.8:2379" set /coreos.com/network/config '{"NetWork":"10.244.0.0/16"}'
```

每台执行：
```bash
$ sed -i 's;^FLANNEL_ETCD_ENDPOINTS=.*;FLANNEL_ETCD_ENDPOINTS="http://192.168.10.6:2379,192.168.10.7:2379,192.168.10.8:2379";g' \
/etc/sysconfig/flanneld

$ sed -i 's;^FLANNEL_ETCD_PREFIX=.*;FLANNEL_ETCD_PREFIX="/coreos.com/network";g' \
/etc/sysconfig/flanneld

$ grep -v ^# /etc/sysconfig/flanneld
FLANNEL_ETCD_ENDPOINTS="http://192.168.10.6:2379,192.168.10.7:2379,192.168.10.8:2379"
FLANNEL_ETCD_PREFIX="/coreos.com/network"
```

如果是vagrant启动的虚拟机的话，会多个10.0.2.15的eth0网段，需要添加--iface参数，需要修改/usr/lib/systemd/system/flanneld.service：
```bash
$ sed -i 's;^ExecStart=.*;ExecStart=/usr/bin/flanneld-start --iface=eth1 -etcd-endpoints=${FLANNEL_ETCD_ENDPOINTS} -etcd-prefix=${FLANNEL_ETCD_PREFIX} $FLANNEL_OPTIONS;g' \
/usr/lib/systemd/system/flanneld.service

启动服务：
systemctl daemon-reload
systemctl enable flanneld
systemctl start flanneld
systemctl status flanneld
```

在service脚本中，会自动通过以下命令生成docker bip所需要的环境变量：
```bash
[root@k8s-master ~]# /usr/libexec/flannel/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker

[root@k8s-master ~]# cat /run/flannel/docker
DOCKER_OPT_BIP="--bip=10.244.38.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=true"
DOCKER_OPT_MTU="--mtu=1472"
DOCKER_NETWORK_OPTIONS=" --bip=10.244.38.1/24 --ip-masq=true --mtu=1472"
```

docker网段修改：
a. 修改docker网段：
```bash
sed -i -e '/ExecStart=/iEnvironmentFile=/run/flannel/docker' /usr/lib/systemd/system/docker.service

sed -i -e '/ExecStart=/iEnvironmentFile=/run/flannel/docker' -e 's;^ExecStart=/usr/bin/dockerd;ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTIONS;g' \
/usr/lib/systemd/system/docker.service

#$ vim /usr/lib/systemd/system/docker.service
#EnvironmentFile=/run/flannel/docker
#ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTIONS

#重启docker服务
systemctl daemon-reload
systemctl enable docker
systemctl restart docker
```

b. 手动修改docker网段：
也可以在docker服务启动后，手动修改docker网段，不过每次开机都要执行，很麻烦。建议采用：[修改docker网段](#a. 修改docker网段)：
```bash
source /run/flannel/subnet.env
ifconfig docker0 ${FLANNEL_SUBNET}
```

### docker方式
安装flannel:
```bash
etcdctl rm /coreos.com/network/ --recursive
etcdctl mk /coreos.com/network/config '{"NetWork":"10.244.0.0/16"}'
#etcdctl set /coreos.com/network/config '{"NetWork":"10.244.0.0/16"}'

docker run --net=host -d --privileged=true --restart=always \
 --name flannel \
 -v /run:/run \
 -v /etc/kubernetes:/etc/kubernetes \
 quay.io/coreos/flannel-git:v0.6.1-28-g5dde68d-amd64 /opt/bin/flanneld --iface=eth1 \
 -etcd-endpoints=http://192.168.10.6:2379,192.168.10.7:2379,192.168.10.8:2379 -etcd-prefix=/coreos.com/network

#查看网络段：
etcdctl ls /coreos.com/network/subnets
 ```
宿主机执行：
```bash
source /run/flannel/subnet.env
ifconfig docker0 ${FLANNEL_SUBNET}
```

~~#修改docker启动文件：
vim /usr/lib/systemd/system/docker.service
EnvironmentFile=/run/flannel/subnet.env
ExecStart=/usr/bin/dockerd --bip=$FLANNEL_SUBNET --ip-masq=$FLANNEL_IPMASQ --mtu=$FLANNEL_MTU~~

### 二进制文件安装
安装：
```bash
wget https://github.com/coreos/flannel/releases/download/v0.6.1/flannel-v0.6.1-linux-amd64.tar.gz
tar -zxvf flannel-v0.6.1-linux-amd64.tar.gz
```
解压后的文件有：flanneld、mk-docker-opts.sh，其中flanneld为执行文件，sh脚本用于生成Docker启动参数。

在etcd中设置flannel所使用的ip段:
```bash
etcdctl --endpoints "http://192.168.10.6:2379,http://192.168.10.7:2379,http://192.168.10.8:2379" set /coreos.com/network/config '{"NetWork":"10.244.0.0/16"}'
```

启动：
```bash
flanneld --iface=eth1 -etcd-endpoints=http://192.168.10.6:2379,192.168.10.7:2379,192.168.10.8:2379 -etcd-prefix=/coreos.com/network
```

手动生成docker变量：
```bash
[root@k8s-master ~]# mk-docker-opts.sh -d /run/flannel/docker_opts.env -c
[root@k8s-master ~]# cat /run/flannel/docker_opts.env
DOCKER_OPTS=" --bip=10.244.38.1/24 --ip-masq=true --mtu=1472"
```

修改docker启动文件：
```bash
$ vim /usr/lib/systemd/system/docker.service
EnvironmentFile=/run/docker_opts.env
ExecStart=/usr/bin/dockerd $DOCKER_OPTS
```

重启docker服务:
```bash
$ systemctl daemon-reload
$ systemctl enable docker
$ systemctl restart docker
```

## 测试
在3台机器上运行：
```bash
docker run -it --rm --name centos centos bash
```

进入bash后，ip addr查看各自ip，互相ping一下对方的ip，如果可以ping通，表示安装正常，否则请检查相关的安装步骤。


## 参考
> https://mritd.me/2016/09/03/Dokcer-%E4%BD%BF%E7%94%A8-Flannel-%E8%B7%A8%E4%B8%BB%E6%9C%BA%E9%80%9A%E8%AE%AF/
> http://qkxue.net/info/108138/docker-kubernetes-flannel
> https://segmentfault.com/a/1190000007585313
> http://blog.dataman-inc.com/shurenyun-docker-133/
> http://cmgs.me/life/docker-network-cloud
> http://dockone.io/article/1115
> http://blog.liuker.cn/index.php/docker/30.html