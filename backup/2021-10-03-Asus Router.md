---
title: Asus Router
date: 2021-10-03 20:04:19
categories: ["Linux"]
tags: ["Linux"]
toc: true
---

为什么要设置代理，大家都懂的...

<!-- more -->

## Clash

### 安装与配置

```bash
#下载 Country.mmdb
wget https://github.com/Dreamacro/maxmind-geoip/releases/download/20220712/Country.mmdb
#下载最新的 Clash for arm, clash 还是只能运行 armv5
#https://github.com/Dreamacro/clash
wget https://github.com/Dreamacro/clash/releases/download/v1.11.4/clash-linux-armv5-v1.11.4.gz

mkdir /tmp/mnt/sda5/clash/
chmod +x /tmp/mnt/sda5/clash/clash-linux-armv5

#Clash Web
#https://www.modb.pro/db/399645
#https://github.com/Dreamacro/clash-dashboard
git clone -b gh-pages --depth 1 https://github.com/Dreamacro/clash-dashboard /tmp/mnt/sda5/clash/clash-dashboard
#修改config.yaml文件
external-ui: /tmp/mnt/sda5/clash/clash-dashboard
secret: '123456'

#启动clash
nohup /tmp/mnt/sda5/clash/clash-linux-armv5 -d /tmp/mnt/sda5/clash/ > /tmp/mnt/sda5/clash/clash.log &
用-f指定文件启动会出现以下的信息，建议用-d指定目录：
INFO[0000] Can't find MMDB, start download

#访问地址为:http://ip:9090/ui
#外部控制设置为：192.168.3.1:9090
```

### 订阅转换

```bash
#将订阅转换为clash格式
#https://www.10101.io/2020/02/12/use-clash-proxy-provider-with-subconverter
#https://github.com/tindy2013/subconverter
wget https://github.com/tindy2013/subconverter/releases/download/v0.7.2/subconverter_armv7.tar.gz

#启动web服务：
/tmp/mnt/sda5/clash/subconverter/subconverter &

#参数：
#https://github.com/tindy2013/subconverter/blob/master/README-cn.md#%E7%AE%80%E6%98%93%E7%94%A8%E6%B3%95
sub?target=%TARGET%&url=%URL%&config=%CONFIG%
target=clash
url=encode后的订阅地址
config不用传
类似于：http://192.168.3.1:25500/sub?target=clash&url=https%3A%2F%2Fxxx.xxx%2Fapi%2Fv1%2Fclient%2Fsubscribe%3Ftoken%223343
```

### 透明代理

修改config.yaml文件

```bash
...
redir-port: 7892
...
dns:
  enable: true
  ipv6: false
  listen: 0.0.0.0:5354
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  nameserver:
    - 192.168.3.1

#重启clash

#iptables:
#https://gist.github.com/dcb9/f10df2a8451ee53be22f12b18296f70a
iptables -t nat -N Clash
iptables -t nat -A Clash -d 192.168.0.0/16 -j RETURN
iptables -t nat -A Clash -p tcp -j REDIRECT --to-ports 7892
iptables -t nat -A PREROUTING -p tcp -j Clash
#iptables -t nat -A PREROUTING -p tcp -j REDIRECT --to-ports 7892

#透明代理后google.com不能访问(google.com.hk可以)，修改路由器dns：
外部网络(WAN)->互联网连接：
自动接上DNS服务器：否
DNS服务器1：223.5.5.5
DNS服务器2：8.8.8.8
```

### 完整脚本

subscribe.sh:

```bash
#!/bin/sh

wget -O /tmp/mnt/sda5/clash/config.yaml \
"http://192.168.3.1:25500/sub?target=clash&url=encode后的订阅URL地址"

if [ $? -eq 0 ]; then
  sed -i 's;7890;1082;g' /tmp/mnt/sda5/clash/config.yaml
  sed -i 's;7891;1080;g' /tmp/mnt/sda5/clash/config.yaml
  sed -i "3aredir-port: 7892" /tmp/mnt/sda5/clash/config.yaml
  sed -i "7aexternal-ui: /tmp/mnt/sda5/clash/clash-dashboard" /tmp/mnt/sda5/clash/config.yaml
  sed -i "8asecret: 'Aa123456'" /tmp/mnt/sda5/clash/config.yaml

sed -i '9a\
dns:\
  enable: true\
  ipv6: false\
  listen: 0.0.0.0:5354\
  enhanced-mode: fake-ip\
  fake-ip-range: 198.18.0.1/16\
  nameserver:\
    - '192.168.3.1'
' /tmp/mnt/sda5/clash/config.yaml

  kill `pidof clash-linux-armv5` > /dev/null 2>&1
  nohup /tmp/mnt/sda5/clash/clash-linux-armv5 -d /tmp/mnt/sda5/clash/ > /tmp/mnt/sda5/clash/clash.log &
  echo "Clash has been restarted."
fi
```

clash-iptables.sh:

```bash
#!/bin/sh

#iptables -nL INPUT|grep 1080 > /dev/null 2>&1
iptables -t nat -nL CLASH > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "iptables wasn't existing, starting:     $(date)"
    #/jffs/scripts/ipset.sh
    #新建一个名为 CLASH 的链
    iptables -t nat -N CLASH
    #内部流量不转发给CLASH直通
    iptables -t nat -A CLASH -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A CLASH -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A CLASH -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A CLASH -d 169.254.0.0/16 -j RETURN
    iptables -t nat -A CLASH -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A CLASH -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A CLASH -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A CLASH -d 240.0.0.0/4 -j RETURN
    #Chinese IPs
    #iptables -t nat -A CLASH -p tcp -m set --match-set china_ip dst -j RETURN
    # 直连 SO_MARK为 0xff 的流量(0xff 是 16 进制数，数值上等同与上面的 255)，此规则目的是避免代理本机(网关)流量出现回环问题
    iptables -t nat -A CLASH -p tcp -j RETURN -m mark --mark 0xff
    
    # 其余流量转发到 12345 端口（即 V2Ray）
    iptables -t nat -A CLASH -p tcp -j REDIRECT --to-ports 7892
    
    # 对局域网其他设备进行透明代理
    #iptables -t nat -A PREROUTING -s 192.168.0.0/16 -p tcp -j CLASH

    #Desktop Computer
    iptables -t nat -A PREROUTING -s 192.168.3.35 -p tcp -j CLASH

    #For ocserv client ip
    #iptables -t nat -A PREROUTING -s 192.168.3.110 -p tcp -j CLASH
    
    # 对本机进行透明代理(不开启不影响路由器其他设备访问)
    #iptables -t nat -A OUTPUT -p tcp -j CLASH
fi
```

清除iptables:

```bash
sudo iptables -t nat -D OUTPUT -p tcp -j CLASH
sudo iptables -t nat -F CLASH
sudo iptables -t nat -X CLASH
```

clash-check.sh:

```bash
#! /bin/sh
case "$(pidof clash-linux-armv5 | wc -w)" in
0)  echo "Restarting clash:     $(date)"
    nohup /tmp/mnt/sda5/clash/clash-linux-armv5 -d /tmp/mnt/sda5/clash/ >> /tmp/mnt/sda5/clash/clash.log &
    #iptables
    #/tmp/mnt/sda5/clash/clash-iptables.sh
    ;;
1)  # all ok
    #iptables
    #/tmp/mnt/sda5/clash/clash-iptables.sh
    ;;
*)  echo "Removed double clash: $(date)"
    kill $(pidof clash-linux-armv5 | awk '{print $1}')
    ;;
esac
```

subconverter-check.sh:

```bash
#! /bin/sh
case "$(pidof subconverter | wc -w)" in
0)  echo "Restarting subconverter:     $(date)"
    nohup /tmp/mnt/sda5/clash/subconverter/subconverter >> /tmp/mnt/sda5/clash/clash.log &
    ;;
1)  # all ok
    #iptables
    ;;
*)  echo "Removed double subconverter: $(date)"
    kill $(pidof subconverter | awk '{print $1}')
    ;;
esac
```

clash-daemon.sh:

```bash
#!/bin/bash

while true
do
  /tmp/mnt/sda5/clash/subconverter-check.sh
  /tmp/mnt/sda5/clash/clash-check.sh
  sleep 5
done
```

/jffs/scripts/wan-event:

(wan-event只适用于merlin系统，原版固件统一放在/jffs/scripts/services-start中)

```bash
#!/bin/sh

if test $2 = "connected"; then
  #sleep 5
  #/tmp/mnt/sda5/vpn/startVPN.sh > /tmp/mnt/sda5/vpn/startVPN.log &

  sleep 5
  /tmp/mnt/sda5/clash/subconverter/subconverter &

  sleep 5
  #/tmp/mnt/sda5/clash/subscribe.sh
  /tmp/mnt/sda5/clash/clash-daemon.sh >> /tmp/mnt/sda5/clash/clash.log &
fi
```

/jffs/scripts/services-start:

```bash
#!/bin/sh

#cru a clash-subscribe "0 0 * * *  /tmp/mnt/sda5/clash/subscribe.sh"
#cru a clash-iptables "*/1 * * * *  /tmp/mnt/sda5/clash/clash-iptables.sh"
```

自动更新订阅地址:

```bash
port: 1082
socks-port: 1080
allow-lan: true
redir-port: 7892
mode: Rule
log-level: info
external-controller: :9090
external-ui: /tmp/mnt/sda5/clash/clash-dashboard
secret: 'Aa123456'
dns:
  enable: true
  ipv6: false
  listen: 0.0.0.0:5354
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  nameserver:
    - 192.168.3.1

proxy-providers:
  TW:
    type: http
    url: "http://192.168.3.1:25500/sub?target=clash&url=https%3A%2F%2Fzhaoxy.xyz%2Fapi%2Fv1%2Fclient%2Fsubscribe%3Ftoken%3D4f17968855a2667e07e7699f046d0eb6&include=%28TW%7C%E5%8F%B0%E6%B9%BE%7C%E5%8F%B0%E7%81%A3%29&list=true"
    interval: 3600
    path: ./TW.yaml
    health-check:
      enable: true
      interval: 600
      # lazy: true
      url: http://www.gstatic.com/generate_204
  HK:
    type: http
    url: "http://192.168.3.1:25500/sub?target=clash&url=https%3A%2F%2Fzhaoxy.xyz%2Fapi%2Fv1%2Fclient%2Fsubscribe%3Ftoken%3D4f17968855a2667e07e7699f046d0eb6&include=%28USA%7C%E9%A6%99%E6%B8%AF%29&list=true"
    interval: 3600
    path: ./HK.yaml
    health-check:
      enable: true
      interval: 600
      # lazy: true
      url: http://www.gstatic.com/generate_204
  SG:
    type: http
    url: "http://192.168.3.1:25500/sub?target=clash&url=https%3A%2F%2Fzhaoxy.xyz%2Fapi%2Fv1%2Fclient%2Fsubscribe%3Ftoken%3D4f17968855a2667e07e7699f046d0eb6&include=%28%E6%96%B0%E5%8A%A0%E5%9D%A1%29&list=true"
    interval: 3600
    path: ./SG.yaml
    health-check:
      enable: true
      interval: 600
      # lazy: true
      url: http://www.gstatic.com/generate_204
  USA:
    type: http
    url: "http://192.168.3.1:25500/sub?target=clash&url=https%3A%2F%2Fzhaoxy.xyz%2Fapi%2Fv1%2Fclient%2Fsubscribe%3Ftoken%3D4f17968855a2667e07e7699f046d0eb6&include=%28USA%7C%E7%BE%8E%E5%9B%BD%7C%E7%BE%8E%E5%9C%8B%29&list=true"
    interval: 3600
    path: ./USA.yaml
    health-check:
      enable: true
      interval: 600
      # lazy: true
      url: http://www.gstatic.com/generate_204
  JP:
    type: http
    url: "http://192.168.3.1:25500/sub?target=clash&url=https%3A%2F%2Fzhaoxy.xyz%2Fapi%2Fv1%2Fclient%2Fsubscribe%3Ftoken%3D4f17968855a2667e07e7699f046d0eb6&include=%28JP%7C%E6%97%A5%E6%9C%AC%29&list=true"
    interval: 3600
    path: ./JP.yaml
    health-check:
      enable: true
      interval: 600
      # lazy: true
      url: http://www.gstatic.com/generate_204
  KR:
    type: http
    url: "http://192.168.3.1:25500/sub?target=clash&url=https%3A%2F%2Fzhaoxy.xyz%2Fapi%2Fv1%2Fclient%2Fsubscribe%3Ftoken%3D4f17968855a2667e07e7699f046d0eb6&include=%28KR%7C%E9%9F%A9%E5%9B%BD%7C%E9%9F%93%E5%9C%8B%29&list=true"
    interval: 3600
    path: ./KR.yaml
    health-check:
      enable: true
      interval: 600
      # lazy: true
      url: http://www.gstatic.com/generate_204
  NETFLIX:             
    type: http    
    url: "http://192.168.3.1:25500/sub?target=clash&url=https%3A%2F%2Fzhaoxy.xyz%2Fapi%2Fv1%2Fclient%2Fsubscribe%3Ftoken%3D4f17968855a2667e07e7699f046d0eb6&include=%28NF%29&list=true"
    interval: 3600
    path: ./NETFLIX.yaml      
    health-check: 
      enable: true
      interval: 600      
      # lazy: true
      url: http://www.gstatic.com/generate_204
  ALL:
    type: http
    url: "http://192.168.3.1:25500/sub?target=clash&url=https%3A%2F%2Fzhaoxy.xyz%2Fapi%2Fv1%2Fclient%2Fsubscribe%3Ftoken%3D4f17968855a2667e07e7699f046d0eb6&list=true"
    interval: 3600
    path: ./ALL.yaml
    health-check:
      enable: true
      interval: 600
      # lazy: true
      url: http://www.gstatic.com/generate_204
  

proxy-groups:
  - name: PROXY
    type: select
    proxies:
      - PROXY-KIDS
      - PROXY-NF
      - PROXY-TW
      - PROXY-HK
      - PROXY-SG
      - PROXY-USA
      - PROXY-JP
      - PROXY-KR
      - PROXY-ALL

  - name: PROXY-TW 
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 300
    use:          
      - TW

  - name: PROXY-HK
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 300
    use:
      - HK
          
  - name: PROXY-SG
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 300
    use:
      - SG
          
  - name: PROXY-USA
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 300
    use:
      - USA
        
  - name: PROXY-JP
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 300
    use:          
      - JP
        
  - name: PROXY-KR
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 300
    use:
      - KR

  - name: PROXY-NF
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 300
    use:
      - NETFLIX

  - name: PROXY-KIDS
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 300
    use:
      - USA
      - SG

  - name: PROXY-ALL                         
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 300
    use:
      - ALL

rules:
  - DOMAIN-SUFFIX,local,DIRECT
  - IP-CIDR,192.168.0.0/16,DIRECT,no-resolve
  - IP-CIDR,10.0.0.0/8,DIRECT,no-resolve
  - IP-CIDR,172.16.0.0/12,DIRECT,no-resolve
  - IP-CIDR,127.0.0.0/8,DIRECT,no-resolve
  - IP-CIDR,100.64.0.0/10,DIRECT,no-resolve
  - DOMAIN-SUFFIX,google.com,PROXY
  - DOMAIN-KEYWORD,google,PROXY
  - DOMAIN,google.com,PROXY
  - DOMAIN-SUFFIX,youtubekids.com,PROXY-KIDS
  - DOMAIN-SUFFIX,ad.com,REJECT
  - GEOIP,CN,DIRECT
  - SRC-PORT,7777,DIRECT
  - DST-PORT,80,DIRECT
  - MATCH,PROXY
```

### Clash Premium

Premium下载地址：https://github.com/Dreamacro/clash/releases/tag/premium

```bash
#https://www.izhaong.com/pages/0dc79d/
#https://github.com/Dreamacro/clash/wiki/configuration
port: 1082
socks-port: 1080
allow-lan: true
redir-port: 7892
mode: Rule
log-level: info
external-controller: :9090
external-ui: /tmp/mnt/sda5/clash/clash-dashboard
secret: 'Aa123456'
dns:
  enable: true
  ipv6: false
  listen: 0.0.0.0:5354
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
  nameserver:
    - 192.168.3.1
  fallback:
    - 8.8.8.8

proxy-providers:
  provider1:
    type: http
    url: "http://192.168.3.1:25500/sub?target=clash&url=encode后的订阅地址&list=true"
    interval: 3600
    path: ./nodes.yaml
    health-check:
      enable: true
      interval: 600
      # lazy: true
      url: http://www.gstatic.com/generate_204

proxy-groups:
  - name: PROXY
    type: select
    use:
      - provider1
    proxies:
      - AUTO
      - DIRECT

  - name: AUTO
    type: url-test
    url: http://www.gstatic.com/generate_204
    interval: 300
    use:
      - provider1

rule-providers:
  reject:
    type: http
    behavior: domain
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/reject.txt"
    path: ./ruleset/reject.yaml
    interval: 86400

  icloud:
    type: http
    behavior: domain
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/icloud.txt"
    path: ./ruleset/icloud.yaml
    interval: 86400

  apple:
    type: http
    behavior: domain
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/apple.txt"
    path: ./ruleset/apple.yaml
    interval: 86400

  google:
    type: http
    behavior: domain
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/google.txt"
    path: ./ruleset/google.yaml
    interval: 86400

  proxy:
    type: http
    behavior: domain
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/proxy.txt"
    path: ./ruleset/proxy.yaml
    interval: 86400

  direct:
    type: http
    behavior: domain
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/direct.txt"
    path: ./ruleset/direct.yaml
    interval: 86400

  private:
    type: http
    behavior: domain
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/private.txt"
    path: ./ruleset/private.yaml
    interval: 86400

  gfw:
    type: http
    behavior: domain
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/gfw.txt"
    path: ./ruleset/gfw.yaml
    interval: 86400

  greatfire:
    type: http
    behavior: domain
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/greatfire.txt"
    path: ./ruleset/greatfire.yaml
    interval: 86400

  tld-not-cn:
    type: http
    behavior: domain
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/tld-not-cn.txt"
    path: ./ruleset/tld-not-cn.yaml
    interval: 86400

  telegramcidr:
    type: http
    behavior: ipcidr
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/telegramcidr.txt"
    path: ./ruleset/telegramcidr.yaml
    interval: 86400

  cncidr:
    type: http
    behavior: ipcidr
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/cncidr.txt"
    path: ./ruleset/cncidr.yaml
    interval: 86400

  lancidr:
    type: http
    behavior: ipcidr
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/lancidr.txt"
    path: ./ruleset/lancidr.yaml
    interval: 86400

  applications:
    type: http
    behavior: classical
    url: "https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/applications.txt"
    path: ./ruleset/applications.yaml
    interval: 86400


rules:
  - RULE-SET,applications,DIRECT
  - DOMAIN,clash.razord.top,DIRECT
  - DOMAIN,yacd.haishan.me,DIRECT
  - RULE-SET,private,DIRECT
  - RULE-SET,reject,REJECT
  - RULE-SET,icloud,DIRECT
  - RULE-SET,apple,DIRECT
  - RULE-SET,google,DIRECT
  - RULE-SET,proxy,PROXY
  - RULE-SET,direct,DIRECT
  - RULE-SET,lancidr,DIRECT
  - RULE-SET,cncidr,DIRECT
  - RULE-SET,telegramcidr,PROXY
  - GEOIP,,DIRECT
  - GEOIP,CN,DIRECT
  - MATCH,PROXY
```

启动:

```bash
/tmp/mnt/sda5/clash/clash-linux-armv5 -f /tmp/mnt/sda5/clash/config.yaml
```

用在路由器不太合适：因为在启动时需要系统时间为当前时间，否则会报错：
```bash
FATA[0000] Initial configuration directory error: can't initial MMDB: can't download MMDB: Get "https://cdn.jsdelivr.net/gh/Dreamacro/maxmind-geoip@release/Country.mmdb": x509: certificate has expired or is not yet valid: current time 2018-05-05T13:07:47+08:00 is before 2022-03-21T10:50:15Z
```

## Xray

### 安装与配置

```bash
mkdir -p /tmp/mnt/sda5/xray
cd /tmp/mnt/sda5/xray
wget https://github.com/XTLS/Xray-core/releases/download/v1.5.9/Xray-linux-arm32-v5.zip
unzip Xray-linux-arm32-v5.zip
chmod +x xray
#Downloading rule files from https://github.com/Loyalsoldier/v2ray-rules-dat:
#curl -oL /tmp/mnt/sda5/xray/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
#curl -oL /tmp/mnt/sda5/xray/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
#Copying config.json
#scp /d/config.json admin@192.168.0.1:/tmp/mnt/sda5/xray/config.json
#Starting
/tmp/mnt/sda5/xray/xray -c /tmp/mnt/sda5/xray/config.json
```

### 完整脚本

xray-check.sh:

```bash
#! /bin/sh
case "$(pidof xray | wc -w)" in
0)  echo "Restarting xray:     $(date)"
    nohup /tmp/mnt/sda5/xray/xray -c /tmp/mnt/sda5/xray/config.json > /tmp/mnt/sda5/xray/xray-access.log 2>&1 &
    #iptables
    /tmp/mnt/sda5/xray/xray-iptables.sh
    ;;
1)  # all ok
    #iptables
    /tmp/mnt/sda5/xray/xray-iptables.sh
    ;;
*)  echo "Removed double xray: $(date)"
    kill $(pidof xray | awk '{print $1}')
    ;;
esac
```

xray-daemon.sh:

```bash
#!/bin/bash

while true
do
  /tmp/mnt/sda5/xray/xray-check.sh
  sleep 5
done
```

xray-iptables.sh:

```bash
#!/bin/sh

#iptables -nL INPUT|grep 1080 > /dev/null 2>&1
iptables -t nat -nL XRAY > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "iptables wasn't existing, starting:     $(date)"
    /tmp/mnt/sda5/xray/ipset.sh
    #新建一个名为 XRAY 的链
    iptables -t nat -N XRAY
    #内部流量不转发给XRAY直通
    iptables -t nat -A XRAY -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A XRAY -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A XRAY -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A XRAY -d 169.254.0.0/16 -j RETURN
    iptables -t nat -A XRAY -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A XRAY -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A XRAY -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A XRAY -d 240.0.0.0/4 -j RETURN
    #Chinese IPs
    iptables -t nat -A XRAY -p tcp -m set --match-set china_ip dst -j RETURN
    # 直连 SO_MARK为 0xff 的流量(0xff 是 16 进制数，数值上等同与上面的 255)，此规则目的是避免代理本机(网关)流量出现回环问题
    iptables -t nat -A XRAY -p tcp -j RETURN -m mark --mark 0xff
    
    # 其余流量转发到 12345 端口（即 V2Ray）
    iptables -t nat -A XRAY -p tcp -j REDIRECT --to-ports 12345
    
    # 对局域网其他设备进行透明代理
    #iptables -t nat -A PREROUTING -s 192.168.0.0/16 -p tcp -j XRAY

    #Desktop Computer
    iptables -t nat -A PREROUTING -s 192.168.3.35 -p tcp -j XRAY

    #For ocserv client ip
    #iptables -t nat -A PREROUTING -s 192.168.3.110 -p tcp -j XRAY
    
    # 对本机进行透明代理(不开启不影响路由器其他设备访问)
    #iptables -t nat -A OUTPUT -p tcp -j XRAY
fi
```

清除iptables:

```bash
sudo iptables -t nat -D OUTPUT -p tcp -j XRAY
sudo iptables -t nat -F XRAY
sudo iptables -t nat -X XRAY
```

xray-kill.sh:

```bash
#! /bin/sh

echo "Killing xray: $(date)"
kill $(pidof xray | awk '{print $1}')
```

ipset.sh:

```bash
#!/bin/sh

if test -z "$(ipset list -n)";
then
  echo "Ipset is not existing, recreating..."
  [[ ! -f /tmp/mnt/sda5/xray/cn.zone ]] && wget http://www.ipdeny.com/ipblocks/data/countries/cn.zone -O /tmp/mnt/sda5/xray/cn.zone
  ipset create china_ip hash:net maxelem 1000000
  for ip in $(cat '/tmp/mnt/sda5/xray/cn.zone'); do
    ipset add china_ip $ip
  done
  echo "Creating ipset successfully."
else
  echo "Ipset is existing, continute..."
fi
```

chinaips_update.sh:

```bash
#!/bin/sh

echo "Updating china ips repositories...     $(date)"
wget http://www.ipdeny.com/ipblocks/data/countries/cn.zone -O /tmp/mnt/sda5/xray/cn.zone
echo "Updating china ips is done.     $(date)"
```

geodat-update.sh:

```bash
#!/bin/sh

#curl -x http://192.168.3.1:1082 -L -o /tmp/mnt/sda5/xray/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
curl -L -o /tmp/mnt/sda5/xray/geoip.dat https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geoip.dat

#curl -x http://192.168.3.1:1082 -L -o /tmp/mnt/sda5/xray/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat
curl -L -o /tmp/mnt/sda5/xray/geosite.dat https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat

```

services-start:

```bash
#!/bin/sh

#swap on
sleep 5
swapon /tmp/mnt/sda5/myswap.swp

#kill xray pid on 05:00 every day, it'll be started by xray-daemon.sh
cru a xray-kill "0 5 * * *  /tmp/mnt/sda5/xray/xray-kill.sh  >> /tmp/mnt/sda5/xray/xray.log"

#check geoip and geosite on 01:00 of every day
cru a geodat-update "0 1 * * * /tmp/mnt/sda5/xray/geodat-update.sh >> /tmp/mnt/sda5/xray/xray.log"

#check chinaip on 02:00 of every day
cru a chinaip-update "0 2 * * * /tmp/mnt/sda5/xray/chinaips_update.sh >> /tmp/mnt/sda5/xray/xray.log"

nohup /tmp/mnt/sda5/xray/xray-daemon.sh >> /tmp/mnt/sda5/xray/xray.log &
```

## 原版固件开机启动

### 安装

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

### SWAP

```bash
dd if=/dev/zero of=/tmp/mnt/sda1/myswap.swp bs=1k count=2097152
mkswap /tmp/mnt/sda1/myswap.swp
swapon /tmp/mnt/sda1/myswap.swp
free
```

Adding this file to the services-start file:

vim /jffs/scripts/services-start

```bash
#!/bin/sh

sleep 5
#swap on
swapon /tmp/mnt/sda1/myswap.swp
```

赋权限:

```
chmod a+rx /jffs/scripts/services-start
```
