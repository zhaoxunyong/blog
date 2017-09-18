---
title: Centos ULIMIT资源限制
date: 2017-02-06 17:55:40
categories: ["Centos"]
tags: ["Centos"]
toc: true
---
Centos下是通过ulimit进行资源限制，本文介绍一下ulimit的详细设置。

<!-- more -->

## 默认配置
默认情况下，ulimit是最小设置。重点参数为open files与max user processes，open files默认为1024，max user processes默认为3870。

可能通过以下命令查看：
```bash
#查看所有的参数：
[root@zhaoxy ~]# ulimit -a
core file size          (blocks, -c) 0
data seg size           (kbytes, -d) unlimited
scheduling priority             (-e) 0
file size               (blocks, -f) unlimited
pending signals                 (-i) 3870
max locked memory       (kbytes, -l) 64
max memory size         (kbytes, -m) unlimited
open files                      (-n) 1024
pipe size            (512 bytes, -p) 8
POSIX message queues     (bytes, -q) 819200
real-time priority              (-r) 0
stack size              (kbytes, -s) 8192
cpu time               (seconds, -t) unlimited
max user processes              (-u) 3870
virtual memory          (kbytes, -v) unlimited
file locks                      (-x) unlimited

#查看max user processes参数：
[root@zhaoxy ~]# ulimit -u
3870

#查看open files参数：
[root@zhaoxy ~]# ulimit -n
1024
```
尤其是open files参数，过小时会造成程序在高并发时出现Too many open files的错误。


## 登录用户配置调整
在centos 5/6 等版本中，资源限制的配置可以在/etc/security/limits.conf设置，针对root/user等各个用户或者*代表所有用户来设置。 当然，/etc/security/limits.d/ 中可以配置，系统是先加载limits.conf然后按照英文字母顺序加载limits.d目录下的配置文件，后加载配置覆盖之前的配置。

```bash
#添加以下参数：
[root@zhaoxy ~]# vim /etc/security/limits.conf
#*                -       nofile             65535
#*                -       nproc              65535
*               soft    nofile             65535
*               hard    nofile             65535
*               soft    nproc              65535
*               hard    nproc              65535
```
其中：
*：     代表所有的用户
nofile：代表open files
nproc： 代表max user processes
soft：  代表一个警告值，超过这个范围，会出现警告，但不会报错
hard：  代表一个真正意义的阀值，超过就会报错
-:      代表soft与hard

注意：
系统是先加载/etc/security/limits.conf中的配置，再加载/etc/security/limits.d/中的配置，后者会覆盖前者。
当用户为*时，受/etc/security/limits.d/中的配置限制，当指定具体的用户时，不受/etc/security/limits.d/中的限制。

当/etc/security/limits.conf中指定的用户为*时，需要修改/etc/security/limits.d/20-nproc.conf文件：
```bash
[root@zhaoxy ~]# vim /etc/security/limits.d/20-nproc.conf
#*          soft    nproc     65535
root       soft    nproc     unlimited
```

## SYSTEMD SERVICE配置调整
在CentOS 7/RHEL 7的系统中，使用Systemd替代了之前的SysV，因此/etc/security/limits.conf文件的配置作用域缩小了一些。limits.conf这里的配置，只适用于通过PAM认证登录用户的资源限制，它对systemd的service的资源限制不生效。登录用户的限制，通过/etc/security/limits.conf和limits.d来配置即可。

对于systemd service的资源限制，全局的配置，放在文件/etc/systemd/system.conf和/etc/systemd/user.conf。 同时，也会加载两个对应的目录中的所有.conf文件/etc/systemd/system.conf.d/*.conf和/etc/systemd/user.conf.d/*.conf
其中，system.conf是系统实例使用的，user.conf用户实例使用的。一般的sevice，使用system.conf中的配置即可。systemd.conf.d/*.conf中配置会覆盖system.conf。

可以添加默认参数，修改/etc/systemd/system.conf配置：
```bash
[Manager]
DefaultLimitCORE=infinity
DefaultLimitNOFILE=100000
DefaultLimitNPROC=100000
```
注意：修改了system.conf后，需要重启系统才会生效。

针对单个Service，也可以设置，以nginx为例。虽然我们修改了/etc/security/limits.conf与/etc/security/limits.d/20-nproc.conf文件，但通过systemctl启动的服务还是默认的参数：
```bash
[root@zhaoxy proc]# cat /proc/3347/limits           
Limit                     Soft Limit           Hard Limit           Units     
...    
Max processes             3870                 3870                 processes 
Max open files            1024                 4096                 files     
...
```

我们需要编辑/usr/lib/systemd/system/nginx.service 文件，添加以下参数：
```bash
[Service]
LimitCORE=infinity
LimitNOFILE=100000
LimitNPROC=100000
```

然后重启：
```bash
systemctl daemon-reload
systemctl restart nginx.service
```

再看看修改后的配置：
```bash
[root@zhaoxy proc]# cat /proc/3347/limits           
Limit                     Soft Limit           Hard Limit           Units     
...    
Max processes             100000               100000               processes 
Max open files            100000               100000               files    
...
```

参考
> http://www.cnblogs.com/MYSQLZOUQI/p/5054559.html
> http://smilejay.com/2016/06/centos-7-systemd-conf-limits