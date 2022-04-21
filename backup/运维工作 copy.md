----------------------------------------------------
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



Dave开发调研部分：
日志异常收集规范
审核平台改为事务性队列
审批平台修改地址后旧的数据不能访问的问题
时区的统一与培训


联通方案邮件出来说明 
联通方案：
城域网光纤：20M, 24000/年
拨号光纤：200M，2600元/年


4. 租户管理中心(mc)
http://192.168.101.158:8090
user: admin
password:  Kdadmin001

5. 苍穹开发平台
http://192.168.101.158:8080/ierp
user: administrator
password:  1234567
user:  17092963696
password:  123321qQ@

https://dev.kingdee.com/index/docsNew/2c91ddac-02f7-4ba6-a7bb-e81589681624
user: 17092963696
密码： Z^cC#Fj7eQ~8

https://www.cnblogs.com/xwgblog/p/13265593.html
https://mp.baomidou.com/guide/interceptor-tenant-line.html#tenantlineinnerinterceptor
https://cloud.tencent.com/developer/article/1497712



