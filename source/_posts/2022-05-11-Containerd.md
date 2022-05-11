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
#Uninstall
systemctl disable containerd
systemctl disable buildkit
systemctl stop containerd
systemctl stop buildkit
tar -tf nerdctl-full-0.19.0-linux-amd64.tar.gz |grep "^bin/.+*"|sed 's;^;rm /usr/local/;'|sh +x
rm -fr /usr/local/share/doc/nerdctl*
rm -fr /usr/local/libexec/cni
rm -fr /var/lib/buildkit
rm -fr /var/lib/docker/buildkit
rm /usr/local/lib/systemd/system/containerd.service 
rm /usr/local/lib/systemd/system/buildkit.service
```

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
wget https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
#Extract it under /opt/cni/bin
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz
systemctl enable --now containerd
#Nerdctl mini version
wget https://github.com/containerd/nerdctl/releases/download/v0.19.0/nerdctl-0.19.0-linux-amd64.tar.gz
tar Cxzvvf /usr/local/bin nerdctl-0.19.0-linux-amd64.tar.gz
#Buildkit
wget https://github.com/moby/buildkit/releases/download/v0.10.3/buildkit-v0.10.3.linux-amd64.tar.gz
tar Cxzvvf /usr/local/ buildkit-v0.10.3.linux-amd64.tar.gz
cp -a buildkit.service /usr/local/lib/systemd/system/buildkit.service
systemctl enable --now buildkit
```

cat Dockerfile:

```bash
FROM nginx:alpine
RUN echo 'Hello Nerdctl From Containerd' > /usr/share/nginx/html/index.html
```

cat buildkit.service

```bash
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]


After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/buildkitd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target

# This file was converted from containerd.service, with `sed -E 's@bin/containerd@bin/buildkitd@g; s@(Description|Documentation)=.*@@'`
```

cat containerd.service

```bash
# Copyright The containerd Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
```

## Usage

```bash
#test
#nerdctl build  -t nginx:nerctl -f Dockerfile .
nerdctl run -d --name nginx -p 80:80 nginx:alpine
curl localhost
```

## Reference 

- https://github.com/containerd/containerd/blob/main/docs/getting-started.md
- https://www.qikqiak.com/post/containerd-usage/
- https://kubernetes.io/zh/docs/tasks/administer-cluster/migrating-from-dockershim/change-runtime-containerd/
- https://www.51cto.com/article/678323.html
- https://developer.51cto.com/article/700609.html
- https://www.jianshu.com/p/4c31554df8c9



