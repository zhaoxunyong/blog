---
title: Containerd
date: 2022-05-11 11:44:06
categories: ["Linux"]
tags: ["Linux","Kubernetes"]
toc: true
---

An industry-standard container runtime with an emphasis on simplicity, robustness and portability: https://containerd.io/

<!-- more -->

## Installation

nerdctl is a Docker-compatible CLI for containerd. The release full version has been included dependencies such as containerd, runc, and CNI.
Maybe nerdctl is not the latest version, you can install the latest version step by step by the following instructions:

https://github.com/containerd/containerd/blob/main/docs/getting-started.md

```bash
#Option 1: From the official binaries
Step 1: Installing containerd
#Step 2: Installing runc
Step 2: Installing CNI plugins
#Option 2: From apt-get or dnf
#The containerd.io packages in DEB and RPM formats are distributed by Docker (not by the containerd project). See the Docker documentation for how to set up apt-get or dnf to install containerd.io packages:
#The containerd.io package contains runc too, but does not contain CNI plugins.

#https://docs.docker.com/engine/install/ubuntu/
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

apt install containerd.io

#Installing CNI plugins
wget https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz
#Extract it under /opt/cni/bin
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.4.0.tgz

#https://github.com/containerd/containerd/blob/main/containerd.service
#wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -P /usr/local/lib/systemd/system/
#sed -i 's;/usr/local/bin/containerd;/usr/bin/containerd;g' /usr/local/lib/systemd/system/containerd.service
systemctl enable --now containerd

#Optional: Proxy
sudo mkdir -p /etc/systemd/system/containerd.service.d
sudo touch /etc/systemd/system/containerd.service.d/http-proxy.conf
sudo tee /etc/systemd/system/containerd.service.d/http-proxy.conf <<-'EOF'
[Service]
Environment="HTTP_PROXY=http://127.0.0.1:1082"
Environment="HTTPS_PROXY=http://127.0.0.1:1082"
Environment="NO_PROXY=127.0.0.1,localhost,10.0.0.0/8,172.0.0.0/8,192.168.0.0/16,*.zerofinance.net,*.aliyun.com,*.163.com,*.docker-cn.com,kubernetes.docker.internal"
EOF
# Restart service:
sudo systemctl daemon-reload
sudo systemctl restart containerd
sudo systemctl show --property=Environment containerd


#Nerdctl(Optional)
wget https://github.com/containerd/nerdctl/releases/download/v1.7.4/nerdctl-1.7.4-linux-amd64.tar.gz
#Extract the archive to a path like /usr/local/bin or ~/bin
tar Cxzvvf /usr/local/bin nerdctl-1.7.4-linux-amd64.tar.gz

ln -s /usr/local/bin/nerdctl /usr/local/bin/docker

#Buildkit
wget https://github.com/moby/buildkit/releases/download/v0.13.0/buildkit-v0.13.0.linux-amd64.tar.gz
tar Cxzvvf /usr/local/ buildkit-v0.13.0.linux-amd64.tar.gz

#https://github.com/moby/buildkit/tree/master/examples/systemd/system
wget https://raw.githubusercontent.com/moby/buildkit/master/examples/systemd/system/buildkit.service -P /usr/local/lib/systemd/system/
wget https://raw.githubusercontent.com/moby/buildkit/master/examples/systemd/system/buildkit.socket -P /usr/local/lib/systemd/system/
#cp -a buildkit.service /usr/local/lib/systemd/system/buildkit.service
systemctl enable --now buildkit


#Uninstall
systemctl stop containerd
systemctl stop buildkit
tar -tf nerdctl-1.7.4-linux-amd64.tar.gz | sed 's;^;rm /usr/local/bin/;' | sh +x
tar -tf buildkit-v0.13.0.linux-amd64.tar.gz | grep "^bin/.+*" | sed 's;^;rm /usr/local/;' | sh +x
rm -fr /opt/cni/bin/
rm /usr/local/lib/systemd/system/buildkit.socket
rm /usr/local/lib/systemd/system/buildkit.service

apt remove containerd.io
rm /usr/local/lib/systemd/system/containerd.service

#Test
sudo nerdctl run --rm --name nginx -p 80:80 nginx:alpine

```

cat Dockerfile:

```bash
FROM nginx:alpine
RUN echo 'Hello Nerdctl From Containerd' > /usr/share/nginx/html/index.html
```

Relocated /var/lib/containerd:

```bash
systemctl stop containerd
mv /var/lib/containerd /data/containerd-lib
ln -s /data/containerd-lib /var/lib/containerd
systemctl start containerd
```

## Usage

```bash
#Build:
nerdctl build  -t nginx:nerctl -f Dockerfile .
#Run:
nerdctl run -d --name nginx -p 80:80 nginx:nerctl
#Test:
curl localhost
```

The native containderd command:

```bash
#https://cloudyuga.guru/blogs/containerd-and-ctr/
#https://medium.com/@seifeddinerajhi/understanding-and-using-containerd-a-comprehensive-guide-7b34f6136058
ctr --help

#container can short as c
#task can short as t
ctr c ls
ctr t ls

#vie namespace
ctr ns ls

#pull
ctr images pull docker.io/library/nginx:alpine

#push
#ctr image push localhost:5000/saif/test:latest

#List out the images
ctr images ls

#For listing the images with names
ctr images ls -q

#mount images
mkdir /tmp/nginx
ctr images mount docker.io/library/nginx:alpine /tmp/golang
ls -l /tmp/nginx/

#unmount point
ctr images unmount /tmp/nginx

#extract the tarball to a temporary directory and explore its contents
mkdir /tmp/nginx_image
tar -xf /tmp/nginx.tar -C /tmp/nginx_image/
ls -lah /tmp/nginx_image/

#delete the images
ctr images rm docker.io/library/nginx:alpine
ctr image remove docker.io/library/nginx:alpine

#tag
ctr image tag docker.io/library/nginx:alpine localhost:5000/library/nginx:alpine

#export images
ctr images export /data/images/nginx.tar docker.io/library/nginx:alpine --platform linux/amd64

#import images
ctr images import /data/images/nginx.tar

#create a container
ctr container create docker.io/library/nginx:alpine nginx_ctr

#List out the containers
ctr containers ls

#start
ctr task start nginx_ctr

#List the tasks
ctr task ls

#create and start
ctr run -d docker.io/library/nginx:alpine nginx_web

#To see the stdout and stderr of a running task
#But be careful, the ctr task attach command will also reconnect the stdin stream and start forwarding signals from the controlling terminal to the task processes, so hitting Ctrl+C might kill the task.
#Unfortunately, ctr doesn't support the Ctrl+P+Q shortcut to detach from a task - it's solely docker's feature. There is also no ctr task logs, so you can't see the stdout/stderr of a task without attaching to it. Neither can you easily see the logs of a stopped task. It's a lower-level tool, remember?
ctr task attach nginx_web

#interact with the container
ctr task exec -t --exec-id bash_1 nginx_web sh

#check the usage of the metrics by the task
ctr task metrics nginx_web

#stop all the tasks
ctr task kill nginx_web

#remove the container
ctr container rm nginx_web

#inspect
ctr container info nginx_web

#snapshot commit
ctr snapshot commit dave_nginx_ctr nginx_ctr

#snapshot list
ctr snapshot ls

```

## Reference 

- https://github.com/containerd/containerd/blob/main/docs/getting-started.md
- https://www.qikqiak.com/post/containerd-usage/
- https://kubernetes.io/zh/docs/tasks/administer-cluster/migrating-from-dockershim/change-runtime-containerd/
- https://www.51cto.com/article/678323.html
- https://developer.51cto.com/article/700609.html
- https://www.jianshu.com/p/4c31554df8c9



