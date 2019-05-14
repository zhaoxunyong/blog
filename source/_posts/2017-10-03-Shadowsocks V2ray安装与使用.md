---
title: Shadowsocks V2ray安装与使用
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
    "method":"aes-256-gcm"
}
```

其中server为你的服务器IP，默认是127.0.0.1 , 只在本地监听，不允许远程连接，设置为0.0.0.0时在服务器全部IP监听。server_port为服务器监听的端口，这里是45678。

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
    "local_port":8899, //本地监听socks5端口
    "password":"changeme", //ss密码
    "timeout":60,
    "method":"aes-256-gcm" //ss加密方式
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

启动：
```bash
systemctl enable sslocal
systemctl start sslocal
```

查看端口：
```bash
[root@k8s-master ~]# lsof -i:8899
COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
ss-local 4405 root    6u  IPv4  37703      0t0  TCP *:socks (LISTEN)
```

测试：
```bash
[root@k8s-master ~]# curl --socks5 127.0.0.1:8899 http://httpbin.org/ip
{
  "origin": "x.x.x.x"
}
```

如果返回你的 ss 服务器 ip 则测试成功。

### SwitchyOmega

浏览器配置proxy:
如果是chrome浏览器，参考其他教程：安装个SwitchyOmega插件就行。
具体可参考[SwitchyOmega.zip](/files/SwitchyOmega.zip)
如果是firefox，如下配置proxy：127.0.0.1:8899  类型选择sock5，并且勾选remote dns。
如果不勾，照样无法使用ss翻墙。

### ssh client

可以找一台国外或者香港的服务器作为代理，然后在国内的服务器上，执行以下命令：

```bash
ssh -q -N -f -D 0.0.0.0:8899 vagrant@47.12.12.116
```

然后就可以直接在chrome中配置proxy：127.0.0.1:8899，类型选择sock5了。
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
forward-socks5t / 127.0.0.1:8899 .
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

可以在chrome通过SwitchyOmega设置SOCKS5的8899的端口、或者http的1080端口。

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

## v2ray

参考:
> https://dcamero.azurewebsites.net/v2ray-windows-linux.html
> https://www.rultr.com/tutorials/proxy/2268.html

### multi-v2ray

#### 安装

```bash
#https://github.com/Jrohy/multi-v2ray.git
#new install
source <(curl -sL https://git.io/fNgqx)
#keep profile to update
source <(curl -sL https://git.io/fNgqx) -k
#uninstall
source <(curl -sL https://git.io/fNgqx) --remove
```

#### TLS配置

参考：

- https://blog.atomur.com/2017-01-18/use-the-acme-sh-to-issue-the-letsencrypt-certificate-for-the-domain-name-without-80-port/
- https://boxjan.com/2018/11/use_acme_sh_to_set_up_rsa_and_ecc.html
- https://github.com/Neilpang/acme.sh/wiki/dnsapi

如果开启tls证书的话，因为80端口不能使用，需要使用acme.sh的dns方式生成证书。修改/usr/lib/python3.6/site-packages/v2ray_util/util_core/utils.py文件：

```bash
#get_ssl_cmd = "bash /root/.acme.sh/acme.sh  --issue -d " + domain + "   --standalone  --keylength ec-256"
get_ssl_cmd = "bash /root/.acme.sh/acme.sh  --issue --dns dns_dp -d " + domain + " --keylength ec-256"
```

首先登陆DNSPod，在“用户中心”——“安全设置”中为acme.sh添加独立的Token, 生成你的 api id 和 api key, 都是免费的. 然后先执行：

```bash
export DP_Id=""
export DP_Key=""
```

然后执行v2ray->3.更改配置->6.更改TLS设置->1.开启 TLS，输入对应的域名即可自动完成。

还可以添加ss服务：

```bash
v2ray add ss
```

也可以先手动生成证书，然后再手动指定证书路径。不过只需要用上面的方面就可以了，不需要使用以下的方式，以下只作记录：

```bash
export DP_Id=""
export DP_Key=""
#ras
#acme.sh --issue --dns dns_dp -d www.a.com
#acme.sh --renew -d www.a.com
#ras
#mkdir -p /etc/ssl/www.a.com
#acme.sh --ecc --install-cert -d www.a.com \
#--key-file       /etc/ssl/www.a.com/keyFile.key  \
#--fullchain-file /etc/ssl/www.a.com/fullchain.cer \
#--reloadcmd     "service nginx force-reload"

#ecc
acme.sh --issue --dns dns_dp -d www.a.com --keylength ec-256
#ecc
mkdir -p /etc/ssl/www.a.com
acme.sh --ecc --install-cert -d www.a.com \
--key-file       /etc/ssl/www.a.com_ecc/keyFile.key  \
--fullchain-file /etc/ssl/www.a.com_ecc/fullchain.cer \
--reloadcmd     "service nginx force-reload"
```

### sprov-ui

一个web ui的v2ray服务端，也很方便。

- https://github.com/sprov065/sprov-ui
- https://blog.sprov.xyz/2019/02/09/sprov-ui/
- https://blog.sprov.xyz/2019/05/06/crt-or-pem-to-jks/

使用使用[KeyManager](https://keymanager.org/)，将www.a.com.key与fullchain.cer转换成jks。




### 安装v2ray-server

建议使用multi-v2ray安装，不使用v2ray-server。

```bash
curl -L -s https://raw.githubusercontent.com/v2ray/v2ray-core/master/release/install-release.sh | sudo bash
```

修改配置文件/etc/v2ray/config.json:

![v2ray-server-config](/images/v2ray-server-config.png)

还可以同时作为V2Ray和Shadowsocks的服务器，响应不同客户端的连接：

![v2ray-shadowsocks-config](/images/v2ray-shadowsocks-config.png)


```bash
systemctl start v2ray
systemctl enable v2ray
```

### 安装v2ray-client

命令行方式使用，不建议。

下载v2ray-core：

```bash
#from https://github.com/v2ray/v2ray-core/releases
wget https://github.com/v2ray/v2ray-core/releases/download/v3.25.1/v2ray-windows-64.zip
```

解压后，修改config.json文件：

![v2ray-client-config](/images/v2ray-client-config.png)

然后运行wv2ray.exe或者v2ray.exe文件启动即可。wv2ray.exe运行后没有命令行窗口。

服务端与客户端的配置文件可以参考：[v2ray-config.zip](/files/v2ray-config.zip)

### SwitchyOmega

参考[SwitchyOmega](#SwitchyOmega)

### windows客户端

安装v2rayN：

```bash
https://github.com/2dust/v2rayN/releases
```

解压后进行相关的配置即可。

### Mac客户端

```bash
#https://github.com/yanue/V2rayU
https://github.com/yanue/V2rayU/releases/
```






