---
title: 使用packer制作vagrant box
date: 2017-01-03 09:42:40
categories: ["vagrant"]
tags: ["vagrant"]
toc: true
---
box可以从官网下载，但有时候下载很慢，并且对应的版本可能不是自己想要的。本文以centos7为例介绍一下怎样制作vagrant box。

<!-- more -->

## 环境准备

### 创建目录
```bash
mkdir -p /Vagrant/packer/
cd /Vagrant/packer/
```

### 下载centos镜像
```bash
#wget http://mirrors.aliyun.com/centos/7.2.1511/isos/x86_64/CentOS-7-x86_64-DVD-1511.iso
#wget http://mirrors.aliyun.com/centos/7.3.1611/isos/x86_64/CentOS-7-x86_64-DVD-1611.iso
wget http://mirrors.aliyun.com/centos/7.4.1708/isos/x86_64/CentOS-7-x86_64-DVD-1708.iso
```
注意：不要用Minimal版本，否则创建后使用时会出现/sbin/mount.vboxsf: mounting failed with the error的错误。

### 安装packer工具
```bash
#MacOS
#wget https://releases.hashicorp.com/packer/0.12.1/packer_0.12.1_darwin_amd64.zip
#unzip packer_0.12.1_darwin_amd64.zip 
wget https://releases.hashicorp.com/packer/1.1.0/packer_1.1.0_darwin_amd64.zip
unzip packer_1.1.0_darwin_amd64.zip
sudo mv packer /usr/local/bin/
```

### 下载centos.json
```bash
#git clone https://github.com/chef/bento.git
git clone https://github.com/boxcutter/centos.git
```

## 开始制作

### 修改centos7.json
先进入centos目录，然后修改cento7.json文件：
```bash
{
  "_comment": "Build with `packer build -var-file=centos7.json centos.json`",
  "vm_name": "centos7",
  "cpus": "1",
  "disk_size": "102400",
  "http_directory": "kickstart/centos7",
  "iso_checksum": "ec7500d4b006702af6af023b1f8f1b890b6c7ee54400bb98cef968b883cd6546",
  "iso_checksum_type": "sha256",
  "iso_name": "CentOS-7-x86_64-DVD-1708.iso",
  "iso_url": "/Vagrant/packer/CentOS-7-x86_64-DVD-1708.iso",
  "memory": "1024",
  "parallels_guest_os_type": "centos7"
}
```

主要修改iso_checksum、iso_name、iso_url几个参数，其中iso_checksum值可以通过以下命令获取：
```bash
$ shasum -a 256 CentOS-7-x86_64-DVD-1708.iso
ec7500d4b006702af6af023b1f8f1b890b6c7ee54400bb98cef968b883cd6546  CentOS-7-x86_64-DVD-1708.iso
```

### 开始生成
```bash
cd centos
#默认会生成所有虚拟机环境的文件，包括vmware/virtualbox/parallels，前提是安装了相应的虚拟机。
packer build -var-file=centos7.json centos.json
(或者bin/box build centos7，只能在unix环境下执行)

#也可以指定生成的是哪个虚拟机：
# packer build -only=virtualbox-iso -var-file=centos7.json centos.json
# 或者bin/box build centos72 virtualbox

# packer build -only=parallels-iso -var-file=centos7.json centos.json
# 或者bin/box build centos7 parallels
```

如果使用parallels，vagrant需要安装plugin：
```bash
vagrant plugin install vagrant-parallels
```

使用parallels时，如出现ImportError: No module named prlsdkapi错误，需要安装ParallelsVirtualizationSDK：
参考：https://forum.parallels.com/threads/error-while-building-with-packer.339491/
```bash
#brew cask install parallels-virtualization-sdk
#wget http://download.parallels.com/desktop/v11/11.2.0-32581/ParallelsVirtualizationSDK-11.2.0-32581-mac.dmg
wget http://download.parallels.com/desktop/v12/12.1.3-41532/ParallelsVirtualizationSDK-12.1.3-41532-mac.dmg
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
--> virtualbox-iso: 'virtualbox' provider box: box/virtualbox/centos7-0.0.99.box
```

生成的文件很小，只有439M：
```bash
$ ls -lh box/virtualbox/centos7-0.0.99.box
-rw-r--r--  1 zxy  wheel   439M  1  3 10:19 box/virtualbox/centos7-0.0.99.box
```

## 参考
> http://www.cnblogs.com/qinqiao/p/packer-vagrant-centos-box.html
> https://www.zzxworld.com/post/create-vagrant-box-base-on-centos.html
> http://www.tuicool.com/articles/F7ZjQvy


