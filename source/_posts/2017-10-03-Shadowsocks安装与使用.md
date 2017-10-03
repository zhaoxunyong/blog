---
title: Shadowsocks安装与使用
date: 2017-10-03 20:04:19
categories: ["Shadowsocks"]
tags: ["Shadowsocks"]
toc: true
---
为什么要设置代理，大家都懂的...

<!-- more -->

## 安装shadowsocks-libev

shadowsocks-libev为linux下的server或者client组件。

ss-server是搭建服务器用到的组件（就是你买了一个vps，要用它来翻墙。那么你要在这个vps上面搭建ss服务器，搭建好了你才能用你的笔记本啊，手机啊链接这个vps上网。）
ss-local就是本地客户端。就是windows下面的那个ss。centos客户端对应的就是ss-local。
很多人搭建的时候都反应，会遇到这个错误：
socket.error: [Errno 99] Cannot assign requested address
就是 因为搞错了服务端与客户端。

### ss-server

以centos为例：
参考[http://www.cellmean.com/centos7-%E5%AE%89%E8%A3%85shadowsocks-libev](http://www.cellmean.com/centos7-%E5%AE%89%E8%A3%85shadowsocks-libev)
从[Fedora Copr](https://copr.fedoraproject.org/coprs/librehat/shadowsocks/)下载repo文件放到 /etc/yum.repos.d/ 目录下，使用root执行:

```bash
wget -O /etc/yum.repos.d/shadowsocks-epel-7.repo https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-7/librehat-shadowsocks-epel-7.repo

yum install shadowsocks-libev
```

编辑文件 /etc/shadowsocks-libev/config.json：

```json
{
    "server":"0.0.0.0",
    "server_port":45678,
    "password":"你的密码",
    "timeout":300,
    "method":"aes-256-cfb"
}
```

其中server为你的服务器IP，默认是127.0.0.1 , 只在本地监听，不允许远程连接，设置为0.0.0.0时在服务器全部IP监听。server_port为服务器监听的端口，这里是8888。

启动：
```bash
systemctl enable shadowsocks-libev
systemctl start shadowsocks-libev
```

### ss-local
参考[http://blog.csdn.net/onlyellow/article/details/52021429](http://blog.csdn.net/onlyellow/article/details/52021429)

一般用户都是买了ss账号，想在linux用起来。那么就应该用ss-local启动客户端，而不是用ss-server。

编辑文件 /etc/shadowsocks-libev/client.json：
```json
{
    "server":"x.x.x.x", //ss服务器
    "server_port":20982, //ss端口
    "local_address":"0.0.0.0", //本地监听socks5 ip
    "local_port":8888, //本地监听socks5端口
    "password":"changeme", //ss密码
    "timeout":60,
    "method":"aes-128-gcm" //ss加密方式
}
```

手动启动：
```bash
ss-local -c /etc/shadowsocks-libev/client.json
```

添加服务：
```bash
tee /etc/systemd/system/sslocal.service << EOF
[Unit]  
Description=Shadowsocks  
  
[Service]  
TimeoutStartSec=0  
ExecStart=/usr/bin/ss-local -c /etc/shadowsocks-libev/client.json
  
[Install]  
WantedBy=multi-user.target  
EOF
```

查看端口：
```bash
[root@k8s-master ~]# lsof -i:8888
COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
ss-local 4405 root    6u  IPv4  37703      0t0  TCP *:socks (LISTEN)
```

测试：
```bash
[root@k8s-master ~]# curl --socks5 127.0.0.1:8888 http://httpbin.org/ip
{
  "origin": "x.x.x.x"
}
```

如果返回你的 ss 服务器 ip 则测试成功。

浏览器配置proxy:
如果是chrome浏览器，参考其他教程：安装个SwitchyOmega插件就行。
具体可参考[SwitchyOmega.zip](/files/SwitchyOmega.zip)
如果是firefox，如下配置proxy：127.0.0.1:8888  类型选择sock5，并且勾选remote dns。
如果不勾，照样无法使用ss翻墙。

### ssh client

可以找一台国外或者香港的服务器作为代理，然后在国内的服务器上，执行以下命令：

```bash
ssh -q -N -f -D 0.0.0.0:8888 vagrant@47.12.12.116
```

然后就可以直接在chrome中配置proxy：127.0.0.1:8888，类型选择sock5了。
还可以通过privoxy将SOCKS5转换为http服务，具体请参考[Privoxy](#Privoxy)

### Privoxy
Shadowsocks 是一个 socket5 服务，我们需要使用 Privoxy 把流量转到 http／https 上。

安装：
```bash
yum install -y epel-release
yum install -y privoxy
```

配置：
vim /etc/privoxy/config
编辑或者新增：
```bash
# 监听端口
listen-address  0.0.0.0:1080
# shadowsocks 的本地端口
forward-socks5t / 127.0.0.1:8888 .
```

启动：
```bash
systemctl enable privoxy
systemctl start privoxy
```

查看是否正常：
```bash
[root@k8s-master ~]# lsof -i:1080
COMMAND  PID    USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
privoxy 5141 privoxy    4u  IPv4  39841      0t0  TCP *:distinct (LISTEN)
```

### 命令行模式

命令行模式不能自动使用Shadowsocks，需要手动设置HTTP_PROXY与HTTPS_PROXY：

```bash
#Windows:
SET HTTP_PROXY=http://127.0.0.1:1080
SET HTTPS_PROXY=http://127.0.0.1:1080

#Mac:
export HTTP_PROXY=http://127.0.0.1:1080
export HTTPS_PROXY=http://127.0.0.1:1080
```

也可以在~/.bash_profile中添加：

```bash 
function proxy_off(){
    unset http_proxy
    unset https_proxy
    echo -e "已关闭代理"
}

function proxy_on() {
    export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com,www.a.com"
    export http_proxy="http://127.0.0.1:1080"
    export https_proxy=$http_proxy

 }
 ```
source ~/.bash_profile生效。

开启代理： proxy_no
关闭代理： proxy_off

可以在chrome通过SwitchyOmega设置SOCKS5的8888的端口、或者http的1080端口。

## shadowsocks GUI客户端

[https://shadowsocks.org/en/download/clients.html](https://shadowsocks.org/en/download/clients.html)

### 下载

#### Windows

```bash
https://github.com/shadowsocks/shadowsocks-windows/releases/download/4.0.6/Shadowsocks-4.0.6.zip
```

#### Mac

```bash
https://github.com/shadowsocks/ShadowsocksX-NG/releases/download/v1.6.1/ShadowsocksX-NG.1.6.1.zip
```

### Shadowsocks客户端设置

以Windows为例说明Shadowsocks的设置

#### 添加服务器

![shadowsocks-01.png](/images/shadowsocks-01.png)

![shadowsocks-02.png](/images/shadowsocks-02.png)

#### 监控所有端口

如果想将shadowsocks做为中转服务的话，可以将它监听本地所有端口，这样其他客户端配置SwitchyOmega的话，也可以通过这台的http服务中转。

![shadowsocks-03.png](/images/shadowsocks-03.png)

注意：ProxyServer为HTTP服务。

#### 更新PAC

![shadowsocks-04.png](/images/shadowsocks-04.png)

## free-shadowsocks

参考[https://www.npmjs.com/package/free-shadowsocks](https://www.npmjs.com/package/free-shadowsocks)

### 安装

```bash
npm install -g free-shadowsocks
```

### 获取

```bash
free-shadowsocks git:(master)
```

![free-shadowsocks.png](/images/free-shadowsocks.png)






