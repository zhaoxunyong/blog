---
title: A Guide to Vagrant
date: 2022-04-29 10:43:46
categories: ["Linux"]
tags: ["Linux","Vagrant"]
toc: true
---

This is a guide to how to use Vagrant to virtual some OS, like Linux/Windows/MacOS etc.

<!-- more -->

## Introduction

Simple and Powerful

HashiCorp Vagrant provides the same, easy workflow regardless of your role as a developer, operator, or designer. It leverages a declarative configuration file which describes all your software requirements, packages, operating system configuration, users, and more.

Works where you work

Vagrant works on Mac, Linux, Windows, and more. Remote development environments force users to give up their favorite editors and programs. Vagrant works on your local system with the tools you're already familiar with. Easily code in your favorite text editor, edit images in your favorite manipulation program, and debug using your favorite tools, all from the comfort of your local laptop.

## Installation

Here just show you how to install vagrant on Ubuntu:

```bash
#https://www.vagrantup.com/downloads
#The executable 'bsdtar' Vagrant is trying to run was not found in the PATH variable. This is an error. Please verify this software is installed and on the path.
# wget https://releases.hashicorp.com/vagrant/2.2.19/vagrant_2.2.19_linux_amd64.zip
# unzip vagrant_2.2.19_linux_amd64.zip
#Recommend:
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install vagrant

#VirtualBox
wget https://download.virtualbox.org/virtualbox/6.1.34/virtualbox-6.1_6.1.34-150636.1~Ubuntu~eoan_amd64.deb
dpkg -i virtualbox-6.1_6.1.34-150636.1~Ubuntu~eoan_amd64.deb
##If some error occurred, executing the following command, and run again:
# sudo apt install -f
# dpkg -i virtualbox-6.1_6.1.34-150636.1~Ubuntu~eoan_amd64.deb
sudo apt install -y gcc make perl
sudo /sbin/vboxconfig
#If some error occurred, just following the messge to resolve.

#extpack
VBoxManage extpack install Oracle_VM_VirtualBox_Extension_Pack-6.1.34.vbox-extpack
```

## Configuration

How to get the box images?

Search from https://app.vagrantup.com/boxes/search to get a certain box, like "ubuntu 20.04", going to the details you can get the following command:

```bash
vagrant init generic/ubuntu2004
vagrant up
```

Just running the command above, you will see the box url. Since the internet connection is very slow in China, you can interrupt the operation when you get the final download url.

```
#Centos
https://vagrantcloud.com/centos/boxes/7/versions/2004.01/providers/virtualbox.box
#Ubuntu
https://vagrantcloud.com/bento/boxes/ubuntu-20.04/versions/202112.19.0/providers/virtualbox.box
#Win10
http://vagrantcloud.com/gusztavvargadr/boxes/windows-10/versions/2102.0.2204/providers/virtualbox.box
```

### Ubuntu

Adding box:

```
sudo vagrant box add ubuntu20.04 box/ubuntu-20.04.box
sudo vagrant plugin install vagrant-disksize
```

Vagrantfile:

```bash
# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|

  #config.vm.box = "ubuntu20.04"
  #config.vm.hostname = "mydocker"
  #config.vm.network "private_network", ip: "192.168.10.9"
#
  #config.vm.synced_folder "/data/docker/registry", "/docker/registry"
  #config.vm.synced_folder "/data/docker/works", "/docker/works"
#
  #config.vm.provider "virtualbox" do |vb|
  #  #vb.gui = true
  #  vb.memory = "2048"
  #end
  #
  #config.vm.provision "shell", run: "always", inline: <<-SHELL
  #  systemctl restart network
  #SHELL
  #config.vm.provision "shell", path: "script.sh"

  config.vm.define :node1 do |node1|
    node1.vm.box = "ubuntu20.04"
    node1.vm.hostname = "node1"
    node1.vm.network "public_network", ip: "192.168.101.83", netmask: "255.255.255.0", gateway: "192.168.101.254", bridge: "enp2s0"
    #node1.vm.synced_folder "/home/dev/vagrant", "/data/vagrant"
    node1.vm.provider "virtualbox" do |vb|
      #vb.gui = true
      vb.cpus = 4 
      vb.memory = "4096"
    end
    node1.vm.provision "shell", run: "always", inline: <<-SHELL
      #cp -a /vagrant/sources.list /etc/apt/sources.list
      #apt-get install sudo net-tools -y
      #sudo route del default gw 10.0.2.2
    SHELL
    node1.vm.provision "shell" do |s|
      s.path = "script.sh"
      #s.args = ["--bip=10.1.10.1/24"]
    end
    #node1.vm.provision "shell", path: "script.sh"
  end


  config.vm.define :node2 do |node2|
    node2.vm.box = "ubuntu20.04"
    node2.vm.hostname = "node2"
    node2.vm.network "public_network", ip: "192.168.101.84", netmask: "255.255.255.0", gateway: "192.168.101.254", bridge: "enp2s0"
    #node1.vm.synced_folder "/home/dev/vagrant", "/data/vagrant"
    node2.vm.provider "virtualbox" do |vb|
      #vb.gui = true
      vb.cpus = 4
      vb.memory = "4096"
    end
    node2.vm.provision "shell", run: "always", inline: <<-SHELL
      #cp -a /vagrant/sources.list /etc/apt/sources.list
      #apt-get install sudo net-tools -y
      #sudo route del default gw 10.0.2.2
    SHELL
    node2.vm.provision "shell" do |s|
      s.path = "script.sh"
      #s.args = ["--bip=10.1.20.1/24"]
    end
  end

end
```

script.sh

```bash
#!/bin/bash
#http://www.360doc.com/content/14/1125/19/7044580_428024359.shtml
#http://blog.csdn.net/54powerman/article/details/50684844
#http://c.biancheng.net/cpp/view/2739.html
echo "scripting......"

cp /etc/apt/sources.list /etc/apt/sources.list.bak
# cat >> /etc/apt/sources.list.d/aliyun.list << EOF
tee /etc/apt/sources.list << EOF
#For ubuntu 20.04
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF

apt update
apt install net-tools wget htop vim screen curl lsof lrzsz zip unzip expect openssh-server -y

#LANG="en_US.UTF-8"
#sed -i 's;LANG=.*;LANG="zh_CN.UTF-8";' /etc/locale.conf


systemctl disable iptables
systemctl stop iptables
systemctl disable firewalld
systemctl stop firewalld

#ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
timedatectl set-timezone Asia/Shanghai

#logined limit
cat /etc/security/limits.conf|grep 100000|egrep "^\*" > /dev/null
if [[ $? != 0 ]]; then
cat >> /etc/security/limits.conf  << EOF
*                -       nofile          100000
*                -       nproc           100000
EOF
fi

#systemd service limit
cat /etc/systemd/system.conf|egrep '^DefaultLimitCORE' > /dev/null
if [[ $? != 0 ]]; then
cat >> /etc/systemd/system.conf << EOF
DefaultLimitCORE=infinity
DefaultLimitNOFILE=100000
DefaultLimitNPROC=100000
EOF
fi

cat /etc/sysctl.conf|grep "net.ipv4.ip_local_port_range" > /dev/null
if [[ $? != 0 ]]; then
	cat >> /etc/sysctl.conf  << EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 500
net.ipv4.ip_forward = 1
fs.inotify.max_user_watches=524288
vm.overcommit_memory=1
fs.protected_regular=0
EOF
sysctl -p
fi

su - root -c "ulimit -a"

# echo "192.168.10.6   k8s-master
# 192.168.10.7   k8s-node1
# 192.168.10.8   k8s-node2" >> /etc/hosts

#tee /etc/resolv.conf << EOF
#search myk8s.com
#nameserver 114.114.114.114
#nameserver 8.8.8.8
#EOF

sed -i 's;#PermitRootLogin.*;PermitRootLogin yes;g' /etc/ssh/sshd_config
systemctl enable ssh
systemctl restart ssh

su - root -c "/vagrant/changpwd.sh"
```

changpwd.sh

```bash
#!/usr/bin/expect
set timeout -1
set PWD "password"
spawn passwd 
expect "New password:" 
send "$PWD\r"
expect "Retype new password:"
send "$PWD\r"
interact
#expect eof
```

Starting:

```
vagrant up
```

### CentOS

Adding box:

```
sudo vagrant box add centos7 box/CentOS-7-x86_64-Vagrant-2004_01.VirtualBox.box
```

Vagrantfile

```bash
# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|

  #config.vm.box = "centos7"
  #config.vm.hostname = "mydocker"
  #config.vm.network "private_network", ip: "192.168.10.9"
#
  #config.vm.synced_folder "/data/docker/registry", "/docker/registry"
  #config.vm.synced_folder "/data/docker/works", "/docker/works"
#
  #config.vm.provider "virtualbox" do |vb|
  #  #vb.gui = true
  #  vb.memory = "2048"
  #end
  #
  #config.vm.provision "shell", run: "always", inline: <<-SHELL
  #  systemctl restart network
  #SHELL
  #config.vm.provision "shell", path: "script.sh"

  config.vm.define :node1 do |node1|
    node1.vm.box = "centos7"
    node1.vm.hostname = "node1"
    node1.vm.network "public_network", ip: "192.168.101.83", netmask: "255.255.255.0", gateway: "192.168.101.254", bridge: "enp2s0"
    #node1.vm.synced_folder "/home/dev/vagrant", "/data/vagrant"
    node1.vm.provider "virtualbox" do |vb|
      #vb.gui = true
      vb.cpus = 4 
      vb.memory = "4096"
    end
    node1.vm.provision "shell", run: "always", inline: <<-SHELL
      yum -y install net-tools > /dev/null
      #ifconfig eth1 192.168.101.83 netmask 255.255.255.0 up
      #route add default gw 192.168.101.254
      sudo route del default gw 10.0.2.2
    SHELL
    node1.vm.provision "shell" do |s|
      s.path = "script.sh"
      #s.args = ["--bip=10.1.10.1/24"]
    end
    #node1.vm.provision "shell", path: "script.sh"
  end


  config.vm.define :node2 do |node2|
    node2.vm.box = "centos7"
    node2.vm.hostname = "node2"
    node2.vm.network "public_network", ip: "192.168.101.84", netmask: "255.255.255.0", gateway: "192.168.101.254", bridge: "enp2s0"
    #node1.vm.synced_folder "/home/dev/vagrant", "/data/vagrant"
    node2.vm.provider "virtualbox" do |vb|
      #vb.gui = true
      vb.cpus = 4
      vb.memory = "4096"
    end
    node2.vm.provision "shell", run: "always", inline: <<-SHELL
      yum -y install net-tools > /dev/null
      #ifconfig eth1 192.168.101.84 netmask 255.255.255.0 up
      #route add default gw 192.168.101.254
      sudo route del default gw 10.0.2.2
    SHELL
    node2.vm.provision "shell" do |s|
      s.path = "script.sh"
      #s.args = ["--bip=10.1.20.1/24"]
    end
  end

end
```

script.sh

```bash
#!/bin/sh
#http://www.360doc.com/content/14/1125/19/7044580_428024359.shtml
#http://blog.csdn.net/54powerman/article/details/50684844
#http://c.biancheng.net/cpp/view/2739.html
echo "scripting......"

yum -y install net-tools wget

sed -i 's;SELINUX=.*;SELINUX=disabled;' /etc/selinux/config
setenforce 0
getenforce

#LANG="en_US.UTF-8"
#sed -i 's;LANG=.*;LANG="zh_CN.UTF-8";' /etc/locale.conf

cat /etc/NetworkManager/NetworkManager.conf|grep "dns=none" > /dev/null
if [[ $? != 0 ]]; then
    echo "dns=none" >> /etc/NetworkManager/NetworkManager.conf
    systemctl restart NetworkManager.service
fi

systemctl disable iptables
systemctl stop iptables
systemctl disable firewalld
systemctl stop firewalld

#ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
timedatectl set-timezone Asia/Shanghai

#logined limit
cat /etc/security/limits.conf|grep 100000 > /dev/null
if [[ $? != 0 ]]; then
cat >> /etc/security/limits.conf  << EOF
*               -    nofile             100000
*               -    nproc              100000
EOF
fi

sed -i 's;4096;100000;g' /etc/security/limits.d/20-nproc.conf

#systemd service limit
cat /etc/systemd/system.conf|egrep '^DefaultLimitCORE' > /dev/null
if [[ $? != 0 ]]; then
cat >> /etc/systemd/system.conf << EOF
DefaultLimitCORE=infinity
DefaultLimitNOFILE=100000
DefaultLimitNPROC=100000
EOF
fi

cat /etc/sysctl.conf|grep "net.ipv4.ip_local_port_range" > /dev/null
if [[ $? != 0 ]]; then
cat >> /etc/sysctl.conf  << EOF
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.ip_forward = 1
#k8s
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p
fi

su - root -c "ulimit -a"

echo "192.168.10.6   k8s-master
192.168.10.7   k8s-node1
192.168.10.8   k8s-node2" >> /etc/hosts

#tee /etc/resolv.conf << EOF
#search myk8s.com
#nameserver 114.114.114.114
#nameserver 8.8.8.8
#EOF

#yum -y install gcc kernel-devel
mv -f /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
# wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel-7.repo http://mirrors.aliyun.com/repo/epel-7.repo

yum -y install epel-release

sudo mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
sudo mv /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup

cat > /etc/yum.repos.d/epel.repo  << EOF
[epel]
name=Extra Packages for Enterprise Linux 7 - \$basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/\$basearch
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - \$basearch - Debug
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/\$basearch/debug
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
[epel-source]
name=Extra Packages for Enterprise Linux 7 - \$basearch - Source
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/SRPMS
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
EOF

yum clean all
yum makecache

#yum -y install createrepo rpm-sign rng-tools yum-utils 
yum -y install htop bind-utils bridge-utils ntpdate setuptool iptables system-config-securitylevel-tui system-config-network-tui \
 ntsysv net-tools lrzsz telnet lsof vim dos2unix unix2dos zip unzip \
 lsof openssl openssh-server openssh-clients

systemctl enable sshd

sed -i 's;#PasswordAuthentication yes;PasswordAuthentication yes;g' /etc/ssh/sshd_config
systemctl restart sshd
```

Starting:

```
vagrant up
```

### Windows10

Adding box:

```
sudo vagrant box add win10 box/win10.box
```

Vagrantfile

```bash
# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = "win10"
  config.vm.hostname = "node3"
  config.vm.network "public_network", ip: "192.168.101.85", netmask: "255.255.255.0", gateway: "192.168.101.254", bridge: "enp2s0"
  config.vm.provider "virtualbox" do |vb|
    #vb.gui = true
    vb.cpus = 2
    vb.memory = "2048"
  end
  config.vm.provision "shell", run: "always", inline: <<-SHELL
    netsh advfirewall set allprofiles state off
    ROUTE ADD 0.0.0.0  MASK 0.0.0.0  192.168.101.254  METRIC 25
  SHELL
end
```

Starting:

```
vagrant up
```

### MacOS

It doesn't work, reslove it later.

Adding box:

```
sudo vagrant box add macos box/macos-10.15.box
```

Vagrantfile

```bash
# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = "macos"
  config.vm.hostname = "node4"
  config.vm.network "public_network", ip: "192.168.101.86", netmask: "255.255.255.0", gateway: "192.168.101.254", bridge: "enp2s0"
  config.vm.provider "virtualbox" do |vb|
    #vb.gui = true
    vb.cpus = 2
    vb.memory = "2048"
  end
  config.vm.provision "shell", run: "always", inline: <<-SHELL
    #netsh advfirewall set allprofiles state off
    #ROUTE ADD 0.0.0.0  MASK 0.0.0.0  192.168.101.254  METRIC 25
  SHELL
end
```

Starting:

```
vagrant up
```

## Command Usage

```bash
#cd vagrant
#Remove box
sudo vagrant box remove centos7
#Add box
sudo vagrant box add centos7 centos7-0.0.99.box
#List box
sudo vagrant box list

#sudo vagrant init centos7
sudo vagrant up
#sudo vagrant up node1
sudo vagrant halt
sudo vagrant reload
#sudo vagrant destroy
sudo vagrant ssh
#sudo vagrant ssh node1
vagrant status

#Export and use "add box" to import 
sudo vagrant package node1 --output node1.box

#Snapshot
sudo vagrant plugin install vagrant-vbox-snapshot
sudo vagrant snapshot list node1
#snapshot save
sudo vagrant snapshot save node1 node1_snapshot
#snapshot restore
sudo vagrant snapshot restore node1 node1_snapshot
```

Modifying the directory of VirtualBox:

```bash
#Using root to handle:
#https://www.jianshu.com/p/12cf1ecb224b
#https://www.cnblogs.com/csliwei/p/5860005.html
mv ~/.vagrant.d/ /data/vagrant/
vim ~/.bashrc
export VAGRANT_HOME='/data/vagrant'
export VAGRANT_DISABLE_VBOXSYMLINKCREATE=1

#VBoxManage setproperty machinefolder  /data/vagrant/
sudo mkdir -p "/data/vagrant/"
mv "/root/VirtualBox VMs" "/data/vagrant/VirtualBox VMs"
sudo ln -s "/data/vagrant/VirtualBox VMs" "/root/VirtualBox VMs"
#To relogin to take effect
```


Resize Disk:

```bash
vagrant plugin install vagrant-disksize
#Edit the Vagrantfile:
Vagrant.configure('2') do |config|
  ...
  config.vm.box = 'ubuntu/xenial64'
  config.disksize.size = '150GB'
  ...
end
vagrant halt && vagrant up
```

Note: this will not work with vagrant reload