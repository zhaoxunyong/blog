学习计划：
serverless/istio
rocketmq/seata
hadoop/flink/spark/hive
GraphQL
DDD
React(icejs/antd)

Kubernetes---ok
spring cloud kubernetes---ok
spring alibaba cloud---xxx
kylin---ok

书籍学习：
支付平台架构
精通以太坊
超大系统分布式流量解决方案
云原生应用管理
istio服务网格技术解析与实践
领域驱动设计
微服务设计模式

其他学习：
已经购买的一些学习视频（极客）
微信公众号学习：
Java架构师之路
架构师之路
高可用架构
Java后端技术
程序员DD
阿里技术
云时代架构
51CTO技术栈
淘系技术
大数据云技术

-------------------------------------------------


培训计划：
VSCode开发
k8s与java：http://blog.gcalls.cn/blog/2020/12/Kubernetes-Development-Environment.html
Kylin
serverless
eclipse与vscode插件开发

运维相关培训:
mysql基础培训
docker基础培训
hadoop培训

Kubernetes 容器服务的落地与实践
Kubernetes 和istio 技术讲解和实践
Linux shell脚本编写和实践
Linux 系统常用知识讲解和实践

linux入门基础     
电脑硬件及软件基础常识

D:\MyScript.txt:
connect 218.17.1.146
y
dave.zhao
xxx

For Current User:
"C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe" -s < D:\Developer\Proxy\MyScript.txt
"C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\vpncli.exe" disconnect

reg import D:\Developer\Proxy\EnableProxy.reg
reg import D:\Developer\Proxy\DisableProxy.reg

#https://devopscube.com/setup-and-configure-proxy-server/
curl -x http://192.168.80.201:3128 ipinfo.io
curl ipinfo.io
sudo yum -y install squid
sudo systemctl start squid
sudo systemctl enable squid
#/etc/squid/squid.conf
/usr/sbin/squid -f /etc/squid/squid.conf
sudo systemctl restart squid

ssh -q -N -f -D 0.0.0.0:8899 dave@172.26.163.70

netsh interface portproxy add v4tov4 listenaddress=192.168.95.211 listenport=80 connectaddress=9.16.15.201 connectport=80

netsh interface portproxy show v4tov4

netsh interface portproxy delete v4tov4 listenaddress=192.168.95.211 listenport=80


