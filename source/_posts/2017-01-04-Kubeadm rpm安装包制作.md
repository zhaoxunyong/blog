---
title: Kubeadm rpm安装包制作
date: 2017-01-04 10:22:47
categories: ["kubernetes"]
tags: ["kubernetes"]
toc: true
---
本文记录一下Kubeadm rpm安装包的制作过程。

<!-- more -->

## 生成rpm安装包

```bash
git clone https://github.com/kubernetes/release.git
cd release/rpm/
sh docker-build.sh
```

如出现rpm.po的错误，可以不用理会。
生成的包在output/x86_64目录下，可以直接安装rpm包，安装包有：

```bash
kubeadm-1.6.0-0.alpha.0.2074.a092d8e0f95f52.x86_64.rpm
kubectl-1.5.1-0.x86_64.rpm
kubelet-1.5.1-0.x86_64.rpm
kubernetes-cni-0.3.0.1-0.07a8a2.x86_64.rpm
```

可以直接安装rpm包，也可以通过yum源方式安装，具体参考下一节。
直接安装rpm包：
```bash
cd output/x86_64
yum localinstall *.rpm
```

## 添加yum源

对rpm签名，请参考: [rpm签名](Centos-yum源搭建.html#rpm签名)
```bash
tee /etc/yum.repos.d/k8s.repo <<-'EOF'
[k8s-repo]
name=kubernetes Repository
baseurl=file:///docker/works/yum
enabled=1
gpgcheck=1
gpgkey=file:///docker/works/yum/gpg
EOF
```

安装：
```bash
yum install -y kubelet kubectl kubernetes-cni kubeadm
```

