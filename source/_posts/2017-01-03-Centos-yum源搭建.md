---
title: Centos yum源搭建
date: 2017-01-03 11:45:45
categories: ["Centos"]
tags: ["Centos"]
---
Centos安装软件一些有两种，一种通过二进制编译安装或者rpm安装，一种通过yum安装。个人觉得最好还是通过yum安装，简单、好升级。但有些yum源不稳定，造成安装非常慢，本文介绍怎样将yum源下载并搭建到自己的yum源中。

## 下载rpm及依赖包

需要先安装createrepo与yum-utils
```bash
yum -y install createrepo yum-utils
```

下载rpm及依赖包
```bash
yum --downloadonly --downloaddir=x86_64 install nginx
```

或者：
```bash
yumdownloader --destdir=x86_64 --resolve nginx
```

## 创建repo
```bash
createrepo .
```

## rpm签名
需要先安装
```bash
yum install rpm-sign rng-tools
```

先查看gpg列表：
```bash
gpg --list-keys
```
没有的话，要创建：
```bash
$ gpg --gen-key
gpg (GnuPG) 2.0.14; Copyright (C) 2009 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
 
Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
Your selection?                                       #使用RSA&RSA方式
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (2048)        #密钥长度2048
Requested keysize is 2048 bits
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0)                                #默认永不过期
Key does not expire at all
Is this correct? (y/N) y
 
GnuPG needs to construct a user ID to identify your key.
 
#输入密钥所有者的联系方式
Real name: zhaoxunyong
Email address: zhaoxunyong@qq.com
Comment: 
You selected this USER-ID:
    "zhaoxunyong <zhaoxunyong@qq.com>"
Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O
You need a Passphrase to protect your secret key.
 
can't connect to `/root/.gnupg/S.gpg-agent': No such file or directory
gpg-agent[9337]: directory `/root/.gnupg/private-keys-v1.d' created
 
Enter passphrase时，直接设为空。

We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
gpg: key C3FE29C9 marked as ultimately trusted
public and secret key created and signed.

gpg: checking the trustdb
gpg: 3 marginal(s) needed, 1 complete(s) needed, PGP trust model
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
pub   2048R/C3FE29C9 2017-01-03
      Key fingerprint = C02E 0B2A 8402 97DA ACC6  239F DF03 083E C3FE 29C9
uid                  zhaoxunyong <zhaoxunyong@qq.com>

Note that this key cannot be used for encryption.  You may want to use
the command "--edit-key" to generate a subkey for this purpose.
```

当现在:
We need to generate a lot of random bytes. It is a good idea to perform some other action (type on the keyboard, move the mouse, utilize the disks) during the prime generation; this gives the random number generator a better chance to gain enough entropy.
可使用：使用以下命令加速urandom伪设备产生随机数的速度：
```bash
rngd -r /dev/urandom
```
 

查询gpg列表：
```bash
# gpg --list-keys
/root/.gnupg/pubring.gpg
------------------------
pub   2048R/C3FE29C9 2017-01-03
uid                  zhaoxunyong <zhaoxunyong@qq.com>
```

修改rpm宏,使用我们的密钥对:
```bash
echo '%_gpg_name C3FE29C9' >> ~/.rpmmacros
```

导出公钥:
```bash
gpg -o /docker/works/yum/gpg -a --export C3FE29C9
```

对rpm签名：
```bash
#rpm --resign etcd-3.0.15-1.x86_64.rpm
cd /docker/works/yum/
find ./ -name "*.rpm" -type f -exec rpm --resign '{}' \;
```

当rpm太多时，每次输入密码很麻烦，可以用expect自动输入
先安装expect：
```bash
yum install expect
```

自动输入密码并签名：
```bash
#!/bin/bash
echo "Start..."
yum -y install expect
YUM_PATH=/docker/works/yum
EXPECT_FILE=/tmp/expectfile_$(date +%y%m%d)
cd $YUM_PATH
rpms=`find ./ -name "*.rpm" -type f`
for rpm in $rpms 
do
echo "rpm --resign $YUM_PATH/$rpm"
cat << EOF > $EXPECT_FILE
#!/usr/bin/expect
set PASS Aa123456
spawn rpm --resign $YUM_PATH/$rpm
expect "Enter pass phrase:" { send "\$PASS\r" }
set timeout -1
expect eof
EOF
expect -f $EXPECT_FILE
rm -fr $EXPECT_FILE
done

echo "finished.."
```

当出现[Errno 256] No more mirrors to try的解决办法：
```bash
yum clean metadata
yum clean all
yum -y update
```
注意：执行yum -y update后会升级内核会导致vagrant加载不了外面的目录，具体解决办法请参考：[Vagrant环境搭建#异常解决](Vagrant环境搭建.html#异常解决)

## 添加yum源
```bash
tee /etc/yum.repos.d/myreop.repo <<-'EOF'
[my-repo]
name=kubernetes Repository
baseurl=file:///docker/works/yum
enabled=1
gpgcheck=1
gpgkey=file:///docker/works/yum/gpg
EOF
```

测试
```bash
yum list | grep my-repo
docker-engine-debuginfo.x86_64          1.12.5-1.el7.centos            my-repo  
etcd.x86_64                             3.0.15-1                       my-repo  
flannel.x86_64                          0.6.2-1                        my-repo  
                                                                       my-repo  
kubectl.x86_64                          1.5.1-0                        my-repo  
kubelet.x86_64                          1.5.1-0                        my-repo  
kubernetes-cni.x86_64                   0.3.0.1-0.07a8a2               my-repo  
rkt.x86_64                              1.21.0-1                       my-repo  
```

## 参考
> http://debugo.com/gpg/
> http://blog.sina.cn/dpool/blog/s/blog_6a5aee670101rx0a.html


