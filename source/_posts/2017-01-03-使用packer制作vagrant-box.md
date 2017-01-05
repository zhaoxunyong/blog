---
title: 使用packer制作vagrant box
date: 2017-01-03 09:42:40
categories: ["vagrant"]
tags: ["vagrant"]
---
box可以从官网下载，但有时候下载很慢，并且对应的版本可能不是自己想要的。本文以centos7为例介绍一下怎样制作vagrant box。

## 环境准备

### 创建目录
```bash
mkdir -p /Vagrant/packer/
cd /Vagrant/packer/
```

### 下载centos7.2镜像
```bash
wget http://mirrors.aliyun.com/centos/7.2.1511/isos/x86_64/CentOS-7-x86_64-DVD-1511.iso
```
注意：不要用CentOS-7-x86_64-Minimal-1511.iso，否则创建后使用时会出现/sbin/mount.vboxsf: mounting failed with the error的错误。

### 安装packer工具
```bash
wget https://releases.hashicorp.com/packer/0.12.1/packer_0.12.1_darwin_amd64.zip
unzip packer_0.12.1_darwin_amd64.zip 
sudo mv packer /usr/local/bin/
```

### 下载centos.json
```bash
git clone https://github.com/boxcutter/centos.git
```

## 开始制作

### 修改centos72.json
先进入centos目录，然后修改cento72.json文件：
```bash
{
  "_comment": "Build with `packer build -var-file=centos72.json centos.json`",
  "vm_name": "centos72",
  "cpus": "1",
  "disk_size": "65536",
  "iso_checksum": "4c6c65b5a70a1142dadb3c65238e9e97253c0d3a",
  "iso_checksum_type": "sha1",
  "iso_name": "CentOS-7-x86_64-DVD-1511.iso",
  "iso_url": "file:///Vagrant/packer/CentOS-7-x86_64-DVD-1511.iso",
  "kickstart": "ks7.cfg",
  "memory": "512",
  "parallels_guest_os_type": "centos7"
}
```
主要修改iso_checksum、iso_name、iso_url几个参数，其中iso_checksum值可以通过以下命令获取：
```bash
$ shasum CentOS-7-x86_64-DVD-1511.iso 
4c6c65b5a70a1142dadb3c65238e9e97253c0d3a  CentOS-7-x86_64-DVD-1511.iso
```

### 开始生成
```bash
cd centos
bin/box build centos72
(或者packer build -var-file=centos72.json centos.json)
```
注意生成期间不要进入虚拟机进行任何操作。

如果想自定义安装一些软件，可以在script/update.sh中定义，比如：
```bash
#!/bin/bash -eux
if [[ $UPDATE  =~ true || $UPDATE =~ 1 || $UPDATE =~ yes ]]; then
    echo "==> Applying updates" 
    yum -y update
    # 安装自定义软件
    #yum -y install gcc gcc-c++ make wget autoconf kernel-devel
    yum -y install gcc kernel-devel

    # reboot
    echo "Rebooting the machine..."
    reboot
    sleep 60
fi
```

如出现以下表示制作成功：
```html
==> Builds finished. The artifacts of successful builds are:
--> virtualbox-iso: 'virtualbox' provider box: box/virtualbox/centos72-2.0.22.box
```

生成的文件很小，只有378M：
```bash
$ ls -lh box/virtualbox/centos72-2.0.22.box
-rw-r--r--  1 zxy  wheel   378M  1  3 10:19 box/virtualbox/centos72-2.0.22.box
```

## 参考
> http://www.cnblogs.com/qinqiao/p/packer-vagrant-centos-box.html
> https://www.zzxworld.com/post/create-vagrant-box-base-on-centos.html
> http://www.tuicool.com/articles/F7ZjQvy


