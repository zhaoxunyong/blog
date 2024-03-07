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
Step 2: Installing runc
Step 3: Installing CNI plugins
#Option 2: From apt-get or dnf
#The containerd.io packages in DEB and RPM formats are distributed by Docker (not by the containerd project). See the Docker documentation for how to set up apt-get or dnf to install containerd.io packages:
#The containerd.io package contains runc too, but does not contain CNI plugins.
apt install containerd.io

#Installing CNI plugins
wget https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz
#Extract it under /opt/cni/bin
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.4.0.tgz

#https://github.com/containerd/containerd/blob/main/containerd.service
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -P /usr/local/lib/systemd/system/
sed -i 's;/usr/local/bin/containerd;/usr/bin/containerd;g' /usr/local/lib/systemd/system/containerd.service
systemctl enable --now containerd

#Nerdctl
wget https://github.com/containerd/nerdctl/releases/download/v1.7.4/nerdctl-1.7.4-linux-amd64.tar.gz
#Extract the archive to a path like /usr/local/bin or ~/bin
tar Cxzvvf /usr/local/bin nerdctl-1.7.4-linux-amd64.tar.gz

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

## Reference 

- https://github.com/containerd/containerd/blob/main/docs/getting-started.md
- https://www.qikqiak.com/post/containerd-usage/
- https://kubernetes.io/zh/docs/tasks/administer-cluster/migrating-from-dockershim/change-runtime-containerd/
- https://www.51cto.com/article/678323.html
- https://developer.51cto.com/article/700609.html
- https://www.jianshu.com/p/4c31554df8c9



