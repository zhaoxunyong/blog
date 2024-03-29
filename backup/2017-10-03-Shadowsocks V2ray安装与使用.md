---
title: Shadowsocks V2ray安装与使用
date: 2017-10-03 20:04:19
categories: ["Shadowsocks"]
tags: ["Shadowsocks"]
toc: true
---
为什么要设置代理，大家都懂的...

本章内容也过期，不建议使用，推荐:xray/trojan：

xray: vless+tcp+xtls

trojan: trojan+xtls

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
具体可参考[SwitchyOmega.zip](/files/Shadowsocks-V2ray安装与使用/SwitchyOmega.zip)
如果是firefox，如下配置proxy：127.0.0.1:8899  类型选择sock5，并且勾选remote dns。
如果不勾，照样无法使用ss翻墙。

推荐大陆白名单模式:

https://www.vos.cn/other/440.html

在SwitchOmega中的PAC设置：

```bash
#推荐
https://raw.githubusercontent.com/pexcn/daily/gh-pages/pac/whitelist.pac
#或者
https://git.io/chinaip

#将内容修改为：
const proxy = "PROXY x.x.x.x:1082;";
```

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
    echo -e "The proxy has been closed!"
}

function proxy_on() {
    export no_proxy="127.0.0.1,localhost,10.0.0.0/8,172.0.0.0/8,192.168.0.0/16,*.zerofinance.net"
    export http_proxy="http://127.0.0.1:1080"
    export https_proxy=$http_proxy
    echo -e "The proxy has been opened!"

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

![shadowsocks-01.png](/images/Shadowsocks-V2ray安装与使用/shadowsocks-01.png)

![shadowsocks-02.png](/images/Shadowsocks-V2ray安装与使用/shadowsocks-02.png)

#### 监控所有端口

如果想将shadowsocks做为中转服务的话，可以将它监听本地所有端口，这样其他客户端配置SwitchyOmega的话，也可以通过这台的http服务中转。

![shadowsocks-03.png](/images/Shadowsocks-V2ray安装与使用/shadowsocks-03.png)

注意：ProxyServer为HTTP服务。

#### 更新PAC

![shadowsocks-04.png](/images/Shadowsocks-V2ray安装与使用/shadowsocks-04.png)

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

install: 

curl https://get.acme.sh | sh

如果开启tls证书的话，因为80端口不能使用，需要使用acme.sh的dns方式生成证书。修改/usr/lib/python3.6/site-packages/v2ray_util/util_core/utils.py文件：

```bash
#get_ssl_cmd = "bash /root/.acme.sh/acme.sh  --issue -d " + domain + "   --standalone  --keylength ec-256"
get_ssl_cmd = "bash /root/.acme.sh/acme.sh  --issue --dns dns_dp -d " + domain + " --keylength ec-256"
```
#https://ethanblog.com/tech/configure-and-anto-renew-let-s-encrypt-free-certificate-using-acme-sh-and-dnspod.html
#https://blog.axis-studio.org/2019/04/05/%E8%85%BE%E8%AE%AF%E4%BA%91%E5%9F%9F%E5%90%8D%E4%BD%BF%E7%94%A8acme-sh%E7%AD%BE%E5%8F%91letsencrypt%E7%9A%84wildcard/index.html
#https://console.dnspod.cn/account/token
首先登陆DNSPod，在“用户中心”——“安全设置”中为acme.sh添加独立的Token, 生成你的 api id 和 api key, 都是免费的. 然后先执行：

```bash
export DP_Id=""
export DP_Key=""
acme.sh --issue --dns dns_dp -d gcalls.cn -d *.gcalls.cn
#acme.sh --issue --dns dns_dp -d registry.gcalls.cn --keylength ec-256
Your cert is in  /home/dev/.acme.sh/gcalls.cn/gcalls.cn.cer 
Your cert key is in  /home/dev/.acme.sh/gcalls.cn/gcalls.cn.key 
The intermediate CA cert is in  /home/dev/.acme.sh/gcalls.cn/ca.cer 
The full chain certs is there:  /home/dev/.acme.sh/gcalls.cn/fullchain.cer
```

然后执行v2ray->3.更改配置->6.更改TLS设置->1.开启 TLS，输入对应的域名即可自动完成。
不过建议通过nginx配置TLS，v2ray不需要开启TLS并绑定127.0.0.1：

nginx代理转发：

```bash
server {
  listen 443;
  server_name  www.a.com;
  server_tokens off;
  client_max_body_size 0;
  charset utf-8;

  ssl on;
  ssl_certificate      /root/.acme.sh/www.a.com_ecc/fullchain.cer;
  ssl_certificate_key  /root/.acme.sh/www.a.com_ecc/www.a.com.key;
  ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers ECDH:AESGCM:HIGH:!RC4:!DH:!MD5:!aNULL:!eNULL;

  ## Individual nginx logs for this GitLab vhost
  access_log  /var/log/nginx/www_access.log main;
  error_log   /var/log/nginx/www_error.log;

  #/qYDx3Nrl/必须与config.json中的path一样，包含最后的/
  location /qYDx3Nrl/ {
    proxy_redirect off;
    #config.json中的ws的地址
    proxy_pass https://127.0.0.1:5817;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $http_host;
  }

#   location / {
#     #deny all;
#     proxy_pass http://127.0.0.1:8082;
#   }

  # location ^~ /api/ {
  #   proxy_pass http://127.0.0.1:8062;
  # }
}
```

v2ray/config.json配置：

```conf
  "inbounds": [
    {
      "port": 15817,
      "listen":"127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "11111111111",
            "level": 0,
            "alterId": 100
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "tcpSettings": {},
        "kcpSettings": {},
        "httpSettings": {},
        "wsSettings": {
          "connectionReuse": true,
          "path": "/qYDx3Nrl/",
          "headers": {
            "Host": "www.a.com"
          }
        },
        "quicSettings": {}
      }
    }
  ],
```

另外，还可以添加ss服务：

```bash
v2ray add ss
```

也可以先手动生成证书，然后再手动指定证书路径。不过只需要用上面的方面就可以了，不需要使用以下的方式，以下只作记录：

```bash
#install acme.sh
curl https://get.acme.sh | sh

#Create alias for: acme.sh=~/.acme.sh/acme.sh.
#cat ~/.bash_profile
alias acme.sh=~/.acme.sh/acme.sh
#active
. ~/.bash_profile

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

使用acme.sh会到期前自动更新，查看crontab -l看看是否有加入，没有的话使用crontab -e添加一下：

```bash
52 0 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null
```

如果不使用了nginx代理转发，则需要添加config.json中的tls配置，以下配置只作参考：

```config
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/root/.acme.sh/www.a.com_ecc/fullchain.cer",
              "keyFile": "/root/.acme.sh/www.a.com_ecc/www.a.com.key"
            }
          ]
        },
        "wsSettings": {
          "connectionReuse": true,
          "path": "/qYDx3Nrl/",
          "headers": {
            "Host": "www.a.com"
          }
        },
        "quicSettings": {}
      }
```

### sprov-ui

一个web ui的v2ray服务端，也很方便。

- https://github.com/sprov065/v2-ui
- https://blog.sprov.xyz/2019/08/03/v2-ui/
- https://blog.sprov.xyz/2019/05/06/crt-or-pem-to-jks/

```bash
#https://www.jianshu.com/p/2de3c13cde89

#修改时区
ln -sf /usr/share/zoneinfo/Asia/Chongqing /etc/localtime

#关闭内核安全
sed -i 's;SELINUX=.*;SELINUX=disabled;' /etc/selinux/config
setenforce 0
getenforce

#关闭防火墙
systemctl disable iptables
systemctl stop iptables
systemctl disable firewalld
systemctl stop firewalld

#优化内核
cat /etc/security/limits.conf|grep 65535 > /dev/null
if [[ $? != 0 ]]; then
cat >> /etc/security/limits.conf  << EOF
*               soft    nofile             65535
*               hard    nofile             65535
*               soft    nproc              65535
*               hard    nproc              65535
EOF
fi

#打开端口转发
#永久修改：/etc/sysctl.conf中的net.ipv4.ip_forward=1，生效：sysctl -p
#临时修改：echo 1 > /proc/sys/net/ipv4/ip_forward，重启后失效

cat /etc/sysctl.conf|grep "net.ipv4.ip_forward" > /dev/null
if [[ $? != 0 ]]; then
cat >> /etc/sysctl.conf  << EOF
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.ip_forward = 1
EOF
sysctl -p
fi

yum -y install epel-release
yum install vim lsof nginx -y

export DP_Id=""
export DP_Key=""

acme.sh --issue --dns dns_dp -d www.a.com --keylength ec-256

#/etc/nginx/conf.d/ssl.conf
server {
  listen 443;
  server_name  www.a.com;
  server_tokens off;
  client_max_body_size 0;
  charset utf-8;

  ssl on;
  ssl_certificate      /root/.acme.sh/www.a.com_ecc/fullchain.cer;
  ssl_certificate_key  /root/.acme.sh/www.a.com_ecc/www.a.com.key;
  ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers ECDH:AESGCM:HIGH:!RC4:!DH:!MD5:!aNULL:!eNULL;

  ## Individual nginx logs for this GitLab vhost
  access_log  /var/log/nginx/www_access.log main;
  error_log   /var/log/nginx/www_error.log;

  #/qYDx3Nrl/必须与config.json中的path一样，包含最后的/
  location /qYDx3Nrl/ {
    proxy_redirect off;
    #config.json中的ws的地址
    proxy_pass http://127.0.0.1:56805;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $http_host;
  }

#   location / {
#     #deny all;
#     proxy_pass http://127.0.0.1:8082;
#   }

  location ^~ / {
    proxy_pass http://127.0.0.1:65432;
  }
}
```

使用使用[KeyManager](https://keymanager.org/)，将www.a.com.key与fullchain.cer转换成jks。

### 安装v2ray-server

建议使用multi-v2ray安装，不使用v2ray-server。

```bash
curl -L -s https://raw.githubusercontent.com/v2ray/v2ray-core/master/release/install-release.sh | sudo bash
```

修改配置文件/etc/v2ray/config.json:

![v2ray-server-config](/images/Shadowsocks-V2ray安装与使用/v2ray-server-config.png)

还可以同时作为V2Ray和Shadowsocks的服务器，响应不同客户端的连接：

![v2ray-shadowsocks-config](/images/Shadowsocks-V2ray安装与使用/v2ray-shadowsocks-config.png)

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

![v2ray-client-config](/images/Shadowsocks-V2ray安装与使用/v2ray-client-config.png)

然后运行wv2ray.exe或者v2ray.exe文件启动即可。wv2ray.exe运行后没有命令行窗口。

服务端与客户端的配置文件可以参考：[v2ray-config.zip](/files/Shadowsocks-V2ray安装与使用/v2ray-config.zip)

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

