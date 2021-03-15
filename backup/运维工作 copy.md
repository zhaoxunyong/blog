netsh interface portproxy add v4tov4 listenaddress=192.168.95.211 listenport=80 connectaddress=9.16.15.201 connectport=80

netsh interface portproxy show v4tov4

netsh interface portproxy delete v4tov4 listenaddress=192.168.95.211 listenport=80

admin@zerofinance.com
Xtyw3013*
192.168.95.233  端口：22   用户名：root  密码：wlt.local

今年学习计划：
1. 领域驱动设计
2. 微服务设计模式
3. Kubernetes
4. spring alibaba cloud
5. spring cloud kubernetes
6. istio
7. serverless
8. hadoop flink spark hive
9. kylin
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

VSCode开发
k8s与java
serverless
eclipse与vscode插件开发

D:\MyScript.txt:
connect 218.17.1.146
y
dave.zhao
Zero5563*!Lz

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