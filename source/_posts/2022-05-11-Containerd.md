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

```bash
#https://github.com/containerd/nerdctl/releases
wget https://github.com/containerd/nerdctl/releases/download/v0.19.0/nerdctl-full-0.19.0-linux-amd64.tar.gz
#Extract the archive to a path like /usr/local/bin or ~/bin
tar Cxzvvf /usr/local nerdctl-full-0.19.0-linux-amd64.tar.gz
systemctl enable --now containerd
systemctl enable --now buildkit
#Test
sudo nerdctl run -d --name nginx -p 80:80 nginx:alpine
```

Maybe nerdctl is not the latest version, you can install the latest version step by step by the following instructions:

https://github.com/containerd/containerd/blob/main/docs/getting-started.md

```bash
#Option 1: From the official binaries
Step 1: Installing containerd
Step 2: Installing runc
Step 3: Installing CNI plugins
#Option 2: From apt-get or dnf
The containerd.io packages in DEB and RPM formats are distributed by Docker (not by the containerd project). See the Docker documentation for how to set up apt-get or dnf to install containerd.io packages:
The containerd.io package contains runc too, but does not contain CNI plugins.
```

## Reference 

- https://www.qikqiak.com/post/containerd-usage/
- https://kubernetes.io/zh/docs/tasks/administer-cluster/migrating-from-dockershim/change-runtime-containerd/
- https://www.51cto.com/article/678323.html
- https://developer.51cto.com/article/700609.html
- https://www.jianshu.com/p/4c31554df8c9



