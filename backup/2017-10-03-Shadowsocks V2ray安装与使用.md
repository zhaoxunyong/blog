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

### 路由器

- https://www.aplayerscreed.com/%E5%9C%A8asuswrt-merlin%E4%B8%8A%E5%AE%89%E8%A3%85v2ray/ 
- https://yuanmomo.net/2019/11/03/router-v2ray-transparent-proxy/ 
- https://guide.v2fly.org/app/transparent_proxy.html#%E8%AE%BE%E7%BD%AE%E6%AD%A5%E9%AA%A4 
- https://enterpr1se.info/2017/10/v2ray-gfw-asuswrt-merlin/

For Merlin Version, 以RT-AC88U为例

```bash
wget https://udomain.dl.sourceforge.net/project/asuswrt-merlin/RT-AC88U/Release/RT-AC88U_386.1_2.zip
#刷机，参考https://www.aplayerscreed.com/%E5%9C%A8asuswrt-merlin%E4%B8%8A%E5%AE%89%E8%A3%85v2ray/
#上传RT-AC88U_386.1_2.trx。注意：上传时没有提示，会直接开始刷机
#然后需要在Administration-System中允许写入JFFS分区和打开SSH。接着就可以用你喜欢的SSH工具连进去了。第一次要格式化JFFS分区，所以两个都选yes，然后重启。
#登录路由器，密码为路由器网页的登录密码
ssh admin@192.168.3.1
cd /jffs
mkdir v2ray
cd v2ray/
#wget https://github.com/v2ray/v2ray-core/releases/download/v4.22.1/v2ray-linux-arm.zip
wget https://github.com/v2ray/v2ray-core/releases/download/v4.20.0/v2ray-linux-arm.zip
unzip v2ray-linux-arm.zip
rm v2ray_armv7 v2ray_armv6 v2ctl_armv7
chmod +x v2ray v2ctl

scp /d/config.json admin@192.168.3.1:/jffs/v2ray/config.json
```

config.json

```json
{
  "policy": null,
  "log": {
    "access": "",
    "error": "",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 1080,
      "listen":"192.168.3.1",
      "protocol": "socks",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
      "settings": {
        // "auth": "noauth",
        "auth": "password",
        "accounts": [
          {
            "user": "admin",
            "pass": "111111"
          }
        ],
        "udp": true
      }
    },
    {
      "port": 1081,
      "listen":"192.168.3.1",
      "protocol": "http",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      },
      "settings": {
        "auth": "noauth",
        "udp": false
      }
    },
    {
      "port": 12345,
      "protocol": "dokodemo-door",
      "settings": {
        "network": "tcp,udp",
        "followRedirect": true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "x.x.x.x",
            "port": 33333,
            "users": [
              {
                "id": "xxxxxxxxxxxxxxxxxxxx",
                "alterId": 2,
                "email": "a@a.a",
                "security": "auto"
              }
            ]
          }
        ],
        "servers": null,
        "response": null
      },
      "streamSettings": {
        "network": "ws",
        "security": null,
        "tlsSettings": null,
        "tcpSettings": null,
        "kcpSettings": null,
        "wsSettings": {
          "connectionReuse": true,
          "path": "/v7aea",
          "headers": null
        },
        "httpSettings": null,
        "quicSettings": null,
        "sockopt": {
          "mark": 255
        }
      },
      "mux": {
        "enabled": true,
        "concurrency": 8
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {
        "vnext": null,
        "servers": null,
        "response": null
      },
      "streamSettings": {
        "sockopt": {
          "mark": 255
        }
      },
      "mux": null
    },
    {
      "tag": "block",
      "protocol": "blackhole",
      "settings": {
        "vnext": null,
        "servers": null,
        "response": {
          "type": "http"
        }
      },
      "streamSettings": {
        "sockopt": {
          "mark": 255
        }
      },
      "mux": null
    }
  ],
  "stats": null,
  "api": null,
  "dns": null,
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "port": null,
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "ip": null,
        "domain": null
      },
      {
        "type": "field",
        "port": null,
        "inboundTag": null,
        "outboundTag": "proxy",
        "ip": null,
        "domain": [
          "geosite:google",
          "geosite:github",
          "geosite:netflix",
          "geosite:steam",
          "geosite:telegram",
          "geosite:tumblr",
          "geosite:speedtest",
          "geosite:bbc",
          "domain:gvt1.com",
          "domain:textnow.com",
          "domain:twitch.tv",
          "domain:wikileaks.org",
          "domain:naver.com"
        ]
      },
      {
        "type": "field",
        "port": null,
        "inboundTag": null,
        "outboundTag": "proxy",
        "ip": [
          "91.108.4.0/22",
          "91.108.8.0/22",
          "91.108.12.0/22",
          "91.108.20.0/22",
          "91.108.36.0/23",
          "91.108.38.0/23",
          "91.108.56.0/22",
          "149.154.160.0/20",
          "149.154.164.0/22",
          "149.154.172.0/22",
          "74.125.0.0/16",
          "173.194.0.0/16",
          "172.217.0.0/16",
          "216.58.200.0/24",
          "216.58.220.0/24",
          "91.108.56.116",
          "91.108.56.0/24",
          "109.239.140.0/24",
          "149.154.167.0/24",
          "149.154.175.0/24"
        ],
        "domain": null
      },
      {
        "type": "field",
        "port": null,
        "inboundTag": null,
        "outboundTag": "direct",
        "ip": null,
        "domain": [
          "domain:12306.com",
          "domain:51ym.me",
          "domain:52pojie.cn",
          "domain:8686c.com",
          "domain:abercrombie.com",
          "domain:adobesc.com",
          "domain:air-matters.com",
          "domain:air-matters.io",
          "domain:airtable.com",
          "domain:akadns.net",
          "domain:apache.org",
          "domain:api.crisp.chat",
          "domain:api.termius.com",
          "domain:appshike.com",
          "domain:appstore.com",
          "domain:aweme.snssdk.com",
          "domain:bababian.com",
          "domain:battle.net",
          "domain:beatsbydre.com",
          "domain:bet365.com",
          "domain:bilibili.cn",
          "domain:ccgslb.com",
          "domain:ccgslb.net",
          "domain:chunbo.com",
          "domain:chunboimg.com",
          "domain:clashroyaleapp.com",
          "domain:cloudsigma.com",
          "domain:cloudxns.net",
          "domain:cmfu.com",
          "domain:culturedcode.com",
          "domain:dct-cloud.com",
          "domain:didialift.com",
          "domain:douyutv.com",
          "domain:duokan.com",
          "domain:dytt8.net",
          "domain:easou.com",
          "domain:ecitic.net",
          "domain:eclipse.org",
          "domain:eudic.net",
          "domain:ewqcxz.com",
          "domain:fir.im",
          "domain:frdic.com",
          "domain:fresh-ideas.cc",
          "domain:godic.net",
          "domain:goodread.com",
          "domain:haibian.com",
          "domain:hdslb.net",
          "domain:hollisterco.com",
          "domain:hongxiu.com",
          "domain:hxcdn.net",
          "domain:images.unsplash.com",
          "domain:img4me.com",
          "domain:ipify.org",
          "domain:ixdzs.com",
          "domain:jd.hk",
          "domain:jianshuapi.com",
          "domain:jomodns.com",
          "domain:jsboxbbs.com",
          "domain:knewone.com",
          "domain:kuaidi100.com",
          "domain:lemicp.com",
          "domain:letvcloud.com",
          "domain:lizhi.io",
          "domain:localizecdn.com",
          "domain:lucifr.com",
          "domain:luoo.net",
          "domain:mai.tn",
          "domain:maven.org",
          "domain:miwifi.com",
          "domain:moji.com",
          "domain:moke.com",
          "domain:mtalk.google.com",
          "domain:mxhichina.com",
          "domain:myqcloud.com",
          "domain:myunlu.com",
          "domain:netease.com",
          "domain:nfoservers.com",
          "domain:nssurge.com",
          "domain:nuomi.com",
          "domain:ourdvs.com",
          "domain:overcast.fm",
          "domain:paypal.com",
          "domain:paypalobjects.com",
          "domain:pgyer.com",
          "domain:qdaily.com",
          "domain:qdmm.com",
          "domain:qin.io",
          "domain:qingmang.me",
          "domain:qingmang.mobi",
          "domain:qqurl.com",
          "domain:rarbg.to",
          "domain:rrmj.tv",
          "domain:ruguoapp.com",
          "domain:sm.ms",
          "domain:snwx.com",
          "domain:soku.com",
          "domain:startssl.com",
          "domain:store.steampowered.com",
          "domain:symcd.com",
          "domain:teamviewer.com",
          "domain:tmzvps.com",
          "domain:trello.com",
          "domain:trellocdn.com",
          "domain:ttmeiju.com",
          "domain:udache.com",
          "domain:uxengine.net",
          "domain:weather.bjango.com",
          "domain:weather.com",
          "domain:webqxs.com",
          "domain:weico.cc",
          "domain:wenku8.net",
          "domain:werewolf.53site.com",
          "domain:windowsupdate.com",
          "domain:wkcdn.com",
          "domain:workflowy.com",
          "domain:xdrig.com",
          "domain:xiaojukeji.com",
          "domain:xiaomi.net",
          "domain:xiaomicp.com",
          "domain:ximalaya.com",
          "domain:xitek.com",
          "domain:xmcdn.com",
          "domain:xslb.net",
          "domain:xteko.com",
          "domain:yach.me",
          "domain:yixia.com",
          "domain:yunjiasu-cdn.net",
          "domain:zealer.com",
          "domain:zgslb.net",
          "domain:zimuzu.tv",
          "domain:zmz002.com",
          "domain:samsungdm.com"
        ]
      },
      {
        "type": "field",
        "port": null,
        "inboundTag": null,
        "outboundTag": "block",
        "ip": null,
        "domain": [
          "geosite:category-ads"
        ]
      },
      {
        "type": "field",
        "port": null,
        "inboundTag": null,
        "outboundTag": "direct",
        "ip": [
          "geoip:private"
        ],
        "domain": null
      },
      {
        "type": "field",
        "port": null,
        "inboundTag": null,
        "outboundTag": "direct",
        "ip": [
          "geoip:cn"
        ],
        "domain": null
      },
      {
        "type": "field",
        "port": null,
        "inboundTag": null,
        "outboundTag": "direct",
        "ip": null,
        "domain": [
          "geosite:cn"
        ]
      }
    ]
  }
}
```

转换格式：

```
dos2unix /jffs/v2ray/config.json
```

接着我们要为V2Ray创建开机启动。

建议通过wan-event启动，wan connected后执行，详见: [wan-start]{https://github.com/RMerl/asuswrt-merlin.ng/wiki/User-scripts#wan-start}

vi /jffs/scripts/wan-event

```bash
#!/bin/sh

if test $2 = "connected"; then
  #check v2ray every 5 minute
  cru a check-v2ray "*/5 * * * * /jffs/scripts/v2ray-check.sh > /dev/null"

  #check dnspod on 00:00 of every day
  cru a ddns-start "0 0 * * * /jffs/scripts/ddns-start > /dev/null"

  /jffs/scripts/ipset.sh
  /jffs/scripts/startVPN.sh > /jffs/vpn/startVPN.log &

  sleep 5
  /jffs/scripts/v2ray-check.sh

  ddns
  /jffs/scripts/ddns-start
fi
```

chmod +x /jffs/scripts/wan-event

也可以通过开机启动，services-start是梅林启动时会执行的shell脚本：

https://github.com/RMerl/asuswrt-merlin.ng/wiki/User-scripts

nano /jffs/scripts/services-start

```bash
#!/bin/sh

#cru a check-oversea "*/5 * * * * /jffs/scripts/oversea.sh >> /var/log/oversea.log"
#/jffs/scripts/oversea.sh > /var/log/oversea.log

#check v2ray every 5 minute
cru a check-v2ray "*/5 * * * * /jffs/scripts/v2ray-check.sh > /dev/null"

#check dnspod on 00:00 of every day
cru a ddns-start "0 0 * * * /jffs/scripts/ddns-start > /dev/null"

/jffs/scripts/ipset.sh
/jffs/scripts/startVPN.sh > /jffs/vpn/startVPN.log &

sleep 10
/jffs/scripts/v2ray-check.sh

#ddns
/jffs/scripts/ddns-start
```

设置国内ip源：

- https://www.starx.ink/archives/%E5%9F%BA%E4%BA%8Eiptables%E7%9A%84%E5%88%86%E6%B5%81%E7%A7%91%E5%AD%A6%E7%BD%91%E5%85%B3/
- https://www.ookangzheng.com/block-china-ip-by-iptables/
- https://www.cnblogs.com/cash/p/13280800.html
- https://gist.github.com/justinemter/5dcbb595b53e5671601bce9f8c096403
- https://www.ichenfu.com/2020/01/07/block-ips-outside-china-with-iptables-and-ipset/
- http://blog.pzxbc.com/2019/01/06/home-router-auto-proxy/

nano /jffs/scripts/ipset.sh

```
#!/bin/sh

if test -z "$(ipset list -n)";
then
  echo "Ipset is not existing, recreating..."
  ipset create china_ip hash:net maxelem 1000000
  for ip in $(cat '/jffs/scripts/cn.zone'); do
    ipset add china_ip $ip
  done
  echo "Creating ipset successfully."
else
  echo "Ipset is existing, continute..."
fi
```

nano /jffs/scripts/router-iptables.sh

```
#!/bin/sh

#iptables -nL INPUT|grep 1080 > /dev/null 2>&1
iptables -t nat -nL V2RAY > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "iptables wasn't existing, starting:     $(date)"
    #/jffs/scripts/ipset-cn.sh
    #新建一个名为 V2RAY 的链
    iptables -t nat -N V2RAY
    #内部流量不转发给V2RAY直通
    iptables -t nat -A V2RAY -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A V2RAY -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A V2RAY -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A V2RAY -d 169.254.0.0/16 -j RETURN
    iptables -t nat -A V2RAY -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A V2RAY -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A V2RAY -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A V2RAY -d 240.0.0.0/4 -j RETURN
    #直连中国的IP
    #iptables -t nat -A V2RAY -m set --match-set china dst -j RETURN
    # 直连 SO_MARK为 0xff 的流量(0xff 是 16 进制数，数值上等同与上面的 255)，此规则目的是避免代理本机(网关)流量出现回环问题
    iptables -t nat -A V2RAY -p tcp -j RETURN -m mark --mark 0xff
    # 其余流量转发到 12345 端口（即 V2Ray）
    iptables -t nat -A V2RAY -p tcp -j REDIRECT --to-ports 12345
    # 对局域网其他设备进行透明代理
    #iptables -t nat -A PREROUTING -p tcp -j V2RAY
    #iptables -t nat -A PREROUTING -s 192.168.0.0/16 -p tcp --dport 1:1024 -j V2RAY
    iptables -t nat -A PREROUTING -s 192.168.0.0/16 -p tcp -j V2RAY
    # 对本机进行透明代理(不开启不影响路由器其他设备访问)
    #iptables -t nat -A OUTPUT -p tcp -j V2RAY
    ##iptables -t nat -A OUTPUT -p tcp --dport 1:1024 -j V2RAY
    ##iptables -t nat -A OUTPUT -s 192.168.0.0/16 -p tcp -j V2RAY

    iptables -I INPUT -p tcp --dport 1080 -j ACCEPT
    iptables -I INPUT -p tcp --dport 1081 -j ACCEPT
fi
```

nano /jffs/scripts/v2ray-check.sh

```
#! /bin/sh
case "$(pidof v2ray | wc -w)" in
0)  echo "Restarting V2ray:     $(date)" >> /var/log/v2ray/v2ray-status.log
    nohup /jffs/v2ray/v2ray --config=/jffs/v2ray/config.json >/dev/null 2>&1 &
    #iptables
    /jffs/scripts/router-iptables.sh >> /var/log/v2ray/v2ray-status.log
    ;;
1)  # all ok
    #iptables
    /jffs/scripts/router-iptables.sh >> /var/log/v2ray/v2ray-status.log
    ;;
*)  echo "Removed double V2ray: $(date)" >> /var/log/v2ray/v2ray-status.log
    kill $(pidof v2ray | awk '{print $1}')
    ;;
esac
```

赋权限并重启：

```bash
chmod a+rx /jffs/scripts/*
reboot
```

如果需要删除某条路由：

```bash
iptables -nvL
iptables -nL --line-number
#Only for INPUT
iptables -nL INPUT --line-number
#Delete rule
iptables -D INPUT 2

iptables -t nat -nL V2RAY
iptables -t nat -nL V2RAY --line-number
iptables -t nat -D V2RAY 11

#插入到INPUT链中的第7行位置
iptables -I INPUT 7 -i ens192 -p tcp -m tcp --dport 11111 -j ACCEPT 
#最前
iptables -I
#最后
iptables -A

#Delete
iptables -D INPUT -i ens192 -p udp -m udp --dport 11111 -j ACCEPT 
iptables -nL INPUT --line-number
iptables -D INPUT 7

```

iptables相关的指令为设置路由器透明代理，这个路由器下的所有终端就可以直接实现代理了，包括在命令行下。参考：

- https://guide.v2fly.org/app/transparent_proxy.html
- https://yuanmomo.net/2019/11/03/router-v2ray-transparent-proxy/

也可以弄一台同一网段的Linux(Ubuntu20)系统配置为透明上网网关，原理同路由器一样。客户端将网关IP改为这台Linux的IP即可。参考：[https://tstrs.me/1488.html](https://tstrs.me/1488.html)

开机自启：
```
nano /etc/rc.local
chmod +x /etc/rc.local

#内容如下：
#!/bin/bash

nohup /works/app/v2ray/v2ray --config /works/app/v2ray/config.json &
/works/app/v2ray/ipset-cn.sh
/works/app/v2ray/router-iptables.sh

exit 0
```

相关配置文件参考：[jffs.zip](/files/Shadowsocks-V2ray安装与使用/jffs.zip)


## 原版固件开机自启动

必须插入U盘才支持该功能，其原理就是利用U盘挂载时触发对应的脚本。

https://www.pianshen.com/article/4824845820/

需要在以下2个目录中设置
1. /opt/etc/init.d/S50servicesstart
2. /opt/lib/ipkg/info/servicesstart.control


/opt/etc/init.d/S50servicesstart

```
#!/bin/sh

/jffs/scripts/services-start &
```

/opt/lib/ipkg/info/servicesstart.control

```
Enabled: yes
```

赋权限:

```
chmod a+rx /opt/etc/init.d/S50servicesstart
chmod a+rx /opt/lib/ipkg/info/servicesstart.control
```

## VPN

### OpenConnect

推荐使用，兼容Cisio AnyConnect:

- https://github.com/RMerl/asuswrt-merlin.ng/wiki/Entware
- https://www.snbforums.com/threads/a-simple-guide-to-use-ocserver-openconnect-vpn-under-asuswrt-merlin.33089/
- https://www.logcg.com/archives/1343.html
- https://cokebar.info/archives/1363
- https://github.com/the-darkvoid/AsusWRT-Merlin-AC87U/tree/master/scripts

安装EntWine，参考：[https://github.com/RMerl/asuswrt-merlin.ng/wiki/Entware](https://github.com/RMerl/asuswrt-merlin.ng/wiki/Entware)

Important: Asus's DownloadMaster is based on Optware, and therefore is NOT compatible with Entware. You will have to uninstall DownloadMaster and look at the alternatives provided by Entware.

After uninstalling, you should make sure "asusware.arm" or "asusware.*" dir on mounted disk partition is deleted. Otherwise, Entware won't work properly. After uninstalling DownloadMaster ensure the router is rebooted.

You will need to plug a USB disk that's formatted in a native Linux filesystem (ext2, ext3 or ext4).

The installation and configuration process must be done through telnet or SSH. If that part scares you, then forget about Entware already: everything must be installed and configured through telnet/SSH.

To start the installation process, first connect to your router over SSH.
Then, launch the amtm application by simply running

```cmd
amtm
```

The menu will offer you an option to initiate the Entware installation.

The installation of OpenConnect:

```cmd
opkg update
opkg install ocserv
```

Modifying the configuration file:

```conf
vi /opt/etc/ocserv/ocserv.conf
1. Commented out the line: auth = "certificate"
2. Added line: auth = "plain[passwd=/opt/etc/ocserv/ocpasswordfile]"
3. Also, I changed the ports to 7443 (both tcp & udp)
4. ipv4-network = 192.168.0.80
   ipv4-netmask = 255.255.255.192
   dns = 192.168.0.1
   dns = 8.8.8.8
   dns = 8.8.4.4
5. Generating username and password:
   ocpasswd -c /opt/etc/ocserv/ocpasswordfile dave
6. Adding iptables:
   iptables -I INPUT -p tcp --dport 7443 -j ACCEPT
7. ocserv as a gateway:
   iptables -t nat -I POSTROUTING -s 192.168.0.0/24 -j MASQUERADE
   iptables -I FORWARD -i vpns+ -s 192.168.0.0/24 -j ACCEPT
   iptables -I INPUT -i vpns+ -s 192.168.0.0/24 -j ACCEPT
```

If can't connect to the server, executing the following scripts:

```bash
vim /opt/etc/ocserv/ocserv_iptables.sh
#!/bin/sh
OCconfig='/opt/etc/ocserv/ocserv.conf'
TCPPORT=`grep tcp-port $OCconfig |awk '{print $3;}'`
UDPPORT=`grep udp-port $OCconfig |awk '{print $3;}'`
DEVICE=`grep '^\ *device' $OCconfig |awk '{print $3;}'`
[ $TCPPORT -gt 0 ] && iptables -I INPUT -p tcp --destination-port $TCPPORT -j ACCEPT
[ $UDPPORT -gt 0 ] && iptables -I INPUT -p udp --destination-port $UDPPORT -j ACCEPT
[ -n $DEVICE ] && iptables -I INPUT -i ${DEVICE}+ -j ACCEPT
[ -n $DEVICE ] && iptables -I FORWARD -i ${DEVICE}+ -j ACCEPT
[ -n $DEVICE ] && iptables -I FORWARD -o ${DEVICE}+ -j ACCEPT
[ -n $DEVICE ] && iptables -I OUTPUT -o ${DEVICE}+ -j ACCEPT

chmod +x /opt/etc/ocserv/ocserv_iptables.sh
$Just running once:
/opt/etc/ocserv/ocserv_iptables.sh
```

Generating certificate key:

```bash
Since the certificate has been generated by LetsEncrypt, just using it:

mkdir -p /opt/etc/ocserv/cert/
ln -s /etc/key.pem /opt/etc/ocserv/cert/server-key.pem
ln -s /etc/cert.pem /opt/etc/ocserv/cert/server-cert.pem
```

Starting openconnect server:

```cmd
#ocserv -f -d 1
It'll be started automatically when route is started, no need to start manually.
```

### OpenVPN

在路由器开启OpenVPN，然后下载client.ovpn文件，编辑文件，在最后添加，否则vpn后不能连接本地网络：

```bash
#https://community.openvpn.net/openvpn/wiki/IgnoreRedirectGateway
#Method 1: filter the pushed option
--pull-filter ignore redirect-gateway
```

下载windows openvpn client: [OpenVPN-2.5.1-I601-amd64.msi](https://swupdate.openvpn.org/community/releases/OpenVPN-2.5.1-I601-amd64.msi)

## DDNS

For Merlin Version

scp ddns-start admin@192.168.3.1:/jffs/scripts/

chmod +x /jffs/scripts/ddns-start，在DDNS页面中选择Cumstom，并输入域名：router.gcalls.cn

登录dnspod后台创建域名router，ip随便指一下，后面会更新的。

/jffs/scripts/ddns-start

[https://koolshare.cn/thread-37553-1-1.html](https://koolshare.cn/thread-37553-1-1.html)

```bash
#!/bin/sh

# 使用Token认证(推荐) 请去 https://www.dnspod.cn/console/user/security 获取
arToken="ID,token"
# 使用邮箱和密码认证
arMail=""
arPass=""

# 获得外网地址
arIpAdress() {
    local inter=`nvram get wan0_ipaddr`
    echo $inter
}

# 查询域名地址
# 参数: 待查询域名
arNslookup() {
    local inter="http://119.29.29.29/d?dn="
    wget --quiet --output-document=- $inter$1
}

# 读取接口数据
# 参数: 接口类型 待提交数据
arApiPost() {
    local agent="AnripDdns/5.07(mail@anrip.com)"
    local inter="https://dnsapi.cn/${1:?'Info.Version'}"
    if [ "x${arToken}" = "x" ]; then # undefine token
        local param="login_email=${arMail}&login_password=${arPass}&format=json&${2}"
    else
        local param="login_token=${arToken}&format=json&${2}"
    fi
    wget --quiet --no-check-certificate --output-document=- --user-agent=$agent --post-data $param $inter
}

# 更新记录信息
# 参数: 主域名 子域名
arDdnsUpdate() {
    local domainID recordID recordRS recordCD
    # 获得域名ID
    domainID=$(arApiPost "Domain.Info" "domain=${1}")
    domainID=$(echo $domainID | sed 's/.\+{"id":"\([0-9]\+\)".\+/\1/')
    # 获得记录ID
    recordID=$(arApiPost "Record.List" "domain_id=${domainID}&sub_domain=${2}")
    recordID=$(echo $recordID | sed 's/.\+\[{"id":"\([0-9]\+\)".\+/\1/')
    # 更新记录IP
    recordRS=$(arApiPost "Record.Ddns" "domain_id=${domainID}&record_id=${recordID}&sub_domain=${2}&record_line=默认")
    recordCD=$(echo $recordRS | sed 's/.\+{"code":"\([0-9]\+\)".\+/\1/')
    # 输出记录IP
    if [ "$recordCD" == "1" ]; then
        echo $recordRS | sed 's/.\+,"value":"\([0-9\.]\+\)".\+/\1/'
        return 1
    fi
    # 输出错误信息
    echo $recordRS | sed 's/.\+,"message":"\([^"]\+\)".\+/\1/'
}

# 动态检查更新
# 参数: 主域名 子域名
arDdnsCheck() {
    local postRS
    local hostIP=$(arIpAdress)
    local lastIP=$(arNslookup "${2}.${1}")
    echo "hostIP: ${hostIP}"
    echo "lastIP: ${lastIP}"
    if [ "$lastIP" != "$hostIP" ]; then
        postRS=$(arDdnsUpdate $1 $2)
        echo "postRS: ${postRS}"
        if [ $? -ne 1 ]; then
            return 1
        fi
    fi
    return 0
}

###################################################
# 检查更新域名
echo "Checking dnspod for router.gcalls.cn:     $(date)" >> /var/log/v2ray/v2ray-status.log
arDdnsCheck "gcalls.cn" "router"

if [ $? -eq 0 ]; then
    /sbin/ddns_custom_updated 1
else
    /sbin/ddns_custom_updated 0
fi
```

## OpenWRT_Koolshare

通过Windows下的Hyper-V进行配置。

参考：

- https://blog.skk.moe/post/hyper-v-win10-lede/
- https://blog.yoitsu.moe/tech_misc/hyper_v_with_openwrt.html
- https://docs.microsoft.com/zh-cn/windows-server/storage/disk-management/manage-virtual-hard-disks
- https://fw.koolcenter.com/LEDE_X64_fw867/
- https://github.com/acgpiano/koolshare-v2ray-x64
- https://downloads.openwrt.org/releases/21.02.0/targets/x86/64/

### 软路由

直接在“管理->磁盘管理”中创建VHD磁盘，注意选择vhdx，容量10G左右、动态扩容磁盘，启动格式为GPT。下载[rufus](https://rufus.ie)与[openwrt-koolshare-router](https://fw.koolcenter.com/LEDE_X64_fw867/openwrt-koolshare-router-v2.37-r17471-8ed31dafdf-x86-64-generic-squashfs-combined-efi.img.gz)并将openWRT img文件刷到VHD磁盘中。

在Hyper的网络设置中创建一下网络：

~~- 内部网络，命名: Internal(openwrt中设置桥接模式)，用于与宿主机通信~~

~~- 外部网络，命名: LAN(openwrt中设置桥接模式，不要勾选“允许管理操作系统共享此网络适配器”)，用于连接AP设备~~

- 外部网络，命名: LAN(openwrt中设置桥接模式，勾选“允许管理操作系统共享此网络适配器”)，用于连接AP设备
- 外部网络，命名: WAN(openwrt中用于拨号，不要勾选“允许管理操作系统共享此网络适配器”)，用于连接光猫拨号

虚拟机中设置：

~~添加硬件：Internal、LAN、WLAN~~

```bash
安全：取消启动安全启动
添加硬件：LAN、WLAN
网络适配器：高级功能中勾选“启动MAC地址欺骗”
自动启动操作：始终自动启动此虚拟机
```

各个IP设置如下：

~~Internal IP(bridge): 192.168.2.1~~

LAN(bridge): 192.168.0.1

WLAN: PPPoE

AP路由器: 192.168.0.2

具体安装参考：https://blog.skk.moe/post/hyper-v-win10-lede/

~~安装完成后，登录后将192.168.1.1 IP 修改为：192.168.2.1（为了不与光猫网段重复）~~

安装完成后，登录后将192.168.1.1 IP 修改为：192.168.0.1（即网关的IP，记得添加option gateway参数）

```bash
vim /etc/config/network

...
        option type 'bridge'
        option ifname 'eth0'
        option proto 'static'
        option ipaddr '192.168.0.1'
        option netmask '255.255.255.0'
        option gateway '192.168.0.1'

reboot
```

~~修改windows宿主机中的vEthernet (Internal)的ip为:~~

修改windows宿主机中的vEthernet (LAN)的ip为:

```bash
192.168.0.37
255.255.255.0
192.168.0.1
```

~~LAN的IP设置为192.168.0.1，使用AP设备接到LAN端口即可。注意AP设备的ip也必须为192.168.0.x，否则不能上网：AP路由器设备的IP设置为192.168.0.2，上网方式设置为AP模式。~~

设置完成后网口必须连接网线windows宿主机才能访问192.168.0.1（如果有设置内部网络则不用）。可以先设置好路由器：
AP路由器设备的IP设置为192.168.0.2，上网方式设置为AP模式，OK后将LAN口与路由器连接起来。

WLAN用于PPPoE拨号。

访问OpenWrt设备，默认login地址为：[http://192.168.0.1](http://192.168.0.1)，密码为：koolshare

登录后设置：

网路->DHCP/DNS：不要勾选：“重绑定保护”，不然ping不同公司内部的某些域名。

这种方式不知道为什么Openconnect Client GUI不能连接，原因不明。可以使用脚本连接，参考下面的Openconnect Client中的[脚本启动](#脚本启动)。

### 网关透明代理

推荐使用，与现有的路由器一起工作，还可以使用这台安装的windows系统。如果不想用现有的路由器拨号的话，只需添加一个WAN作为拨号即可，操作方式参考[软路由](#软路由)。

在Hyper的网络设置中创建一下网络：

- 外部网络，命名: LAN(openwrt中设置桥接模式，勾选“允许管理操作系统共享此网络适配器”)

虚拟机中设置：

```bash
安全：取消启动安全启动
添加硬件：LAN
网络适配器：高级功能中勾选“启动MAC地址欺骗”
自动启动操作：始终自动启动此虚拟机
```

登录后将192.168.1.1 IP 修改为：192.168.0.10（假设路由器的IP为192.168.0.1, 必须与路由器相同网段）

```bash
vim /etc/config/network

...
        option type 'bridge'
        option ifname 'eth0'
        option proto 'static'
        option ipaddr '192.168.0.10'
        option netmask '255.255.255.0'
        option gateway '192.168.0.1'

reboot
```

login地址为：[http://192.168.0.10](http://192.168.0.10)，密码为：koolshare

在酷软中安装v2ray插件：

```bash
wget https://github.com/acgpiano/koolshare-v2ray-x64/releases/download/v4.35.1/v2ray_4.35.1.tar.gz
#ssh 或者网页打开终端运行（必要，解除系统安装限制）
sed -i 's/\tdetect_package/\t# detect_package/g' /koolshare/scripts/ks_tar_install.sh
#操作很简单，不再说明
```

其他设备采用192.168.0.10作为网关即可实现透明代理。不过这种方式当openwrt关机后就不能上网了，可以还是用192.168.0.1作为网关，通过iptables进行流量转发，主路由器为asus-merlin路由器：

/jffs/scripts/ipset.sh
```bash
#!/bin/sh

if test -z "$(ipset list -n)";
then
  echo "Ipset is not existing, recreating..."
  wget http://www.ipdeny.com/ipblocks/data/countries/cn.zone -O /jffs/scripts/cn.zone
  ipset create china_ip hash:net maxelem 1000000
  for ip in $(cat '/jffs/scripts/cn.zone'); do
    ipset add china_ip $ip
  done
  echo "Creating ipset successfully."
else
  echo "Ipset is existing, continute..."
fi
```

设置iptables:

参考：

- https://post.smzdm.com/p/a9grmrn0/
- https://blog.csdn.net/lee244868149/article/details/45113585

```bash
ip route add default gw 192.168.0.1
ip route add default via 192.168.0.3 dev br0 table ovpnc1
ip rule add fwmark 15 table ovpnc1
iptables -t mangle -A PREROUTING -i br0 -s 192.168.0.0/24 -m set ! --match-set china_ip dst -j MARK --set-mark 15
```

完整的脚本如下:

/jffs/scripts/oversea.sh

```bash
#!/bin/sh

#Checking ipset rules
/jffs/scripts/ipset.sh

#Adding ovpnc1 routing table
if test -z "$(ip route list table ovpnc1)"
then
    echo "The routing table[ovpnc1] isn't existing, adding:     $(date)"
    ip route add default gw 192.168.0.1
    ip route add default via 192.168.0.3 dev br0 table ovpnc1
else
    echo "The routing table[ovpnc1] has been existed, continute:     $(date)"
fi

#Adding the policy of routing table
if test -z "$(ip rule | grep fwmark)"
then
    echo "The policy of routing table isn't existing, adding:     $(date)"
    #The traffic marked 15 will forward according to routing table ovpnc1
    ip rule add fwmark 15 table ovpnc1
    echo "The policy of routing table is done:     $(date)"
else
    echo "The policy of routing table has been existed, continute:     $(date)"
fi

#Adding the rule of iptables
if test -z "$(iptables-save | grep 'china_ip')"
then
    echo "The rule of iptables isn't existing, recreating:     $(date)"
    #The oversea traffics marked 15 will forward to v2ray
    iptables -t mangle -A PREROUTING -i br0 -s 192.168.0.0/24 -m set ! --match-set china_ip dst -j MARK --set-mark 15
    echo "Creating the rule of iptables is done:     $(date)"
    else
    echo "The rule of iptables is existing, continute:     $(date)"
fi
```

如果在web管理界面修改配置或者重新拨号后策略路由和iptables规则会被重置删掉，解决办法是使用linux的crontab定时任务：

crontab -e

chmod +x /jffs/scripts/oversea.sh

每5分钟执行一次配置脚本:

```bash

*/5 * * * * /jffs/scripts/oversea.sh >> /var/log/oversea.log
```

nano /jffs/scripts/services-start

```bash
cru a check-oversea "*/5 * * * * /jffs/scripts/oversea.sh >> /var/log/oversea.log"

/jffs/scripts/oversea.sh > /var/log/oversea.log
```

chmod +x /jffs/scripts/services-start

### Openconnect Client

推荐：https://www.jianshu.com/p/1cb8c31319e8

#### GUI

```bash
opkg update
opkg install luci-proto-openconnect openconnect
#reboot
```

在interface中建立一个新接口，根据官方说明，最好命名为ocvpn，协议选择OpenConnect(CISCO AnyConnect):

```bash
#需要设置
IP
端口
VPN 服务器证书的 SHA1 哈希值
用户名
密码
```

VPN 服务器证书的 SHA1 哈希值，通过一些命令获取：

```bash
openssl s_client -connect vpn.example.com:443 -showcerts 2>/dev/null </dev/null \
| awk '/-----BEGIN/,/-----END/ { print $0 }' \
| openssl x509 -noout -fingerprint -sha1 \
| sed 's/Fingerprint=//' | sed 's/://g'
```

SHA1: 471FB1B45700272166B1E2DD798AC14E0E19B6E0

将以上内容输入到VPN 服务器证书的 SHA1 哈希值中

以下不用处理，仅供参考：

如果vpn后主机访问不了，可以在开机启动中加入以下路由，参考：

- https://sparkydogx.github.io/2019/01/09/openwrt-service-startup/
- https://whycan.com/t_7014.html

vim /etc/init.d/openconnect

```bash
#!/bin/sh /etc/rc.common
# Copyright (C) 2006-2011 OpenWrt.org

START=99
STOP=10

boot() {
    sleep 10
    route add -net 192.168.101.0/24 dev br-lan
}
```

在 /etc/rc.d/ 加一个 Sxx 开头的软链接才行:

```bash
chmod +x /etc/init.d/openconnect
ln -s /etc/init.d/openconnect /etc/rc.d/S99openconnect
/etc/init.d/openconnect enable
/etc/init.d/openconnect boot
```

或者：

```bash
chmod +x /etc/rc.local
vim /etc/rc.local

#不sleep的话可能vpn还没有拨上
sleep 15
route add -net 192.168.101.0/24 dev br-lan
exit 0
```

查看openconnect完整命令:

```bash
cat /proc/`ps |grep openconnect|grep vpnc|awk '{print $1}'`/cmdline
```

#### 脚本启动

也可以通过脚本启动：

```
mkdir -p /etc/vpn
cd /etc/vpn
wget http://git.infradead.org/users/dwmw2/vpnc-scripts.git/blob_plain/HEAD:/vpnc-script
chmod +x /etc/vpn/vpnc-script 

openconnect -u aaa --script=/etc/vpn/vpnc-script --no-dtls x.x.x.x:7443
# 自动登录, 将密码写入MyScript.txt文件中即可
openconnect -u dave.zhao --script=/etc/vpn/vpnc-script --no-dtls x.x.x.x:7443 \
--servercert pin-sha256:+PLuNZB2mIJy8y/Hx3Qwc3QmMhZfulMTOy1S5OakhdY= \
--passwd-on-stdin < /etc/vpn/MyScript.txt
```

完整的脚本如下：

```bash
#!/bin/bash

cd /etc/vpn

function start() {
    ping scloud.y.y.y -c 3 > /dev/null 2>&1
    if [[ $? != 0 ]]; then
        echo "Starting VPN..."
        nohup openconnect -u dave.zhao --script=/etc/vpn/vpnc-script --no-dtls x.x.x.x:7443 \
        --servercert pin-sha256:+PLuNZB2mIJy8y/Hx3Qwc3QmMhZfulMTOy1S5OakhdY= \
        --passwd-on-stdin < /etc/vpn/MyScript.txt > /dev/null 2>&1 &
    fi
    echo "Openconnect has been started."
}

start

while true
do
    #echo "Checking openconnect's status..."
    ping y.y.y.y -c 3 > /dev/null 2>&1
    if [[ $? != 0 ]]; then
        #Failed, restart
        echo "Openconnect's status is failed, restarting..."
        kill `ps |grep openconnect|grep vpnc|awk '{print $1}'` > /dev/null 2>&1
        start
    fi
    sleep 3
done
```

其中/etc/vpn/MyScript.txt为密码保存的地方。然后添加到开机启动即可：

chmod +x /etc/rc.local

vim /etc/rc.local

```bash
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.


/etc/vpn/startVPN.sh > /etc/vpn/startVPN.log &
exit 0
```

### 爱快

推荐使用，不过就只能当做路由器了。直接使用rufus写到U盘，然后从U盘启动安装即可。注意：如果是安装的硬盘的话，会清空硬盘所以数据，一定要做好数据备份。

设置好web访问地址为：[http://192.68.0.1](http://192.68.0.1)后，使用另外一台电脑访问即可。爱快没有图形界面。

最少需要两个网口。一个WLAN用于PPPoE拨号，一个LAN用于连接AP，LAN的IP设置为192.168.0.1(也就是在爱快中设置的web访问地址)，AP设备连接到LAN接口，AP路由器设备的IP设置为192.168.0.2，上网方式设置为AP模式。

#### 使用虚拟机安装openwrt

使用StarWind V2V Converter将img文件转为vmdk，并上传到爱快的文件管理中，然后在虚拟机设置中添加“新建设备”->“磁盘”->“引用磁盘”->“开启半虚拟化模式”->“磁盘路径(爱快的文件管理中vmdk文件路径)”。不能直接使用img，否则openwrt重启后数据会丢失。

设置ip为192.168.0.3，在酷软中安装v2ray并配置相关信息，然后将爱快的DHCP的网关修改为192.168.0.3就可以实现透明上网了。

#### openconnect server

参考：

- https://www.ioiox.com/archives/89.html
- https://blog.vay1314.top/archives/194.html
- https://gao4.top/293.html
- https://cndaqiang.github.io/2017/09/27/openwrt-ocserv/

安装后设备使用vpn拨号也能实现透明上网。

```bash
opkg update
opkg install ocserv luci-app-ocserv
reboot
```

通过“服务”–“OpenConnect VPN”，进到“服务器设置”的“常规设置”，相关参数如下：

```
Enable Server: 打钩表示启动服务
User Authentication: plain
端口：7443
AnyConnect client compatibility：打勾表示允许Cisco的AnyConnect client作为VPN客户端软件连接。
VPN IPv4-Network-Address：192.168.0.80
VPN-IPv4-Netmask：255.255.255.192
```

Routing table:

采取全局代理，不要添加任何路由信息。

```
全局代理 - 当客户端连接 VPN 后,客户端所有内外网访问都将通过 VPN 所在的局域网代理.删除所有Routing table即可.
内网代理 - 当客户端连接 VPN 后,客户端所有内网访问通过 VPN 所在的局域网代理,而外网访问则保持使用客户端当前网络.添加内网和VPN两个网段即可.
```

在“User Settings”中配置登录用户名与密码。

添加iptables:

网络->防火墙->自定义规则：

```
#iptables -I FORWARD -i vpns+ -s 192.168.0.0/24 -j ACCEPT

iptables -t nat -I POSTROUTING -s 192.168.0.0/24 -j MASQUERADE
iptables -I FORWARD -i vpns+ -s 192.168.0.0/24 -j ACCEPT
iptables -I INPUT -i vpns+ -s 192.168.0.0/24 -j ACCEPT
```

保持后生效。

爱快添加7443端口映射：

网络设置->端口映射：

```
内网地址：192.168.0.3
内网端口：7443
协议：tcp
映射类型：外网接口
外网地址：wan1	
外网端口：7443
备注：openconnect
```

保持后生效。

手机或电脑需要安装OpenConnect-GUI VPN client。





