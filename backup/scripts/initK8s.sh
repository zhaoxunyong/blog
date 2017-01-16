#!/bin/sh
docker start `docker ps -a |grep 'index.alauda.cn/georce/router'|awk '{print $1}'`
#route add -net 10.1.20.0 netmask 255.255.255.0 gw 172.28.3.97
#route add -net 10.1.30.0 netmask 255.255.255.0 gw 172.28.3.98

