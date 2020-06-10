https://blog.csdn.net/xu470438000/article/details/50512442
https://www.cnblogs.com/Jing-Wang/p/10672609.html


<!-- 192.168.100.100    root    wlt.local   32G/8Core
192.168.108.100    root    wlt.local   32G/8Core
192.168.100.31     root    wlt.local   64G/16Core -->
192.168.80.196     root    64G/48Core  10G/8C 

192.168.80.94      root    32G/8Core   8G/4C(master1) 24G/4C(utility/mysql)
192.168.80.97      root    32G/8Core   8G/4C(master2)  8G/4C(gateway1)
192.168.80.99      root    32G/8Core   8G/4C(master3)  24G/4C(kylin)

<!-- #192.168.80.201     root    64G/48Core  10G/8C node1/node2/node3/node4/node5/node6 -->
192.168.80.201     root    64G/48Core  20G/14C node1/node2/node3
192.168.80.98      root    64G/16Core  20G/14C node4


80.94
---------------------------
master1:
docker run -d \
-m 8G --cpus=4 \
-h master1 --name master1 \
-p 8088:8088 -p 19888:19888 -p 50070:50070 \
-v /home/dev/cdh:/cdh \
--privileged=true \
dave/cdh:base /sbin/init

utility:
docker run -d \
-m 24G --cpus=4 \
-h utility --name utility \
-p 7180:7180 -p 8889:8889 \
-v /home/dev/cdh:/cdh \
--privileged=true \
dave/cdh:base /sbin/init

80.97
---------------------------
master2:
docker run -d \
-m 8G --cpus=4 \
-h master2 --name master2 \
-v /home/dev/cdh:/cdh \
-p 8088:8088 -p 19888:19888 -p 50070:50070 \
--privileged=true \
dave/cdh:base /sbin/init

gateway1:
docker run -d \
-m 8G --cpus=4 \
-h gateway1 --name gateway1 \
-v /home/dev/cdh:/cdh \
-p 8888:8888 -p 8889:8889 \
--privileged=true \
dave/cdh:base /sbin/init

https://blog.csdn.net/lsziri/article/details/69396990
iptables -t nat -A PREROUTING  -p tcp -m tcp --dport 8889 -j DNAT --to-destination  10.244.93.3:8889
iptables-save

80.99
---------------------------
master3:
docker run -d \
-m 8G --cpus=4 \
-h master3 --name master3 \
-v /home/dev/cdh:/cdh \
-p 8088:8088 -p 19888:19888 -p 50070:50070 \
--privileged=true \
dave/cdh:base /sbin/init

kylin:
docker run -d \
-m 24G --cpus=4 \
-h kylin --name kylin \
-p 7070:7070 \
-v /home/dev/cdh:/cdh \
--privileged=true \
dave/cdh:base /sbin/init

80.201
---------------------------
dn1:
sudo mkdir -p /kylin/cdh/dn1
docker run -d \
-m 20G --cpus=14 \
-h dn1 --name dn1 \
-v /home/dev/cdh:/cdh \
-v /kylin/cdh/dn1:/kylin/cdh \
--privileged=true \
dave/cdh:base /sbin/init
docker update --memory 20480m dn2

dn2:
sudo mkdir -p /kylin/cdh/dn2
docker run -d \
-m 20G --cpus=14 \
-h dn2 --name dn2 \
-v /home/dev/cdh:/cdh \
-v /kylin/cdh/dn2:/kylin/cdh \
--privileged=true \
dave/cdh:base /sbin/init

dn3:
sudo mkdir -p /kylin/cdh/dn3
docker run -d \
-m 20G --cpus=14 \
-h dn3 --name dn3 \
-v /home/dev/cdh:/cdh \
-v /kylin/cdh/dn3:/kylin/cdh \
--privileged=true \
dave/cdh:base /sbin/init

80.98
---------------------------
dn4:
sudo mkdir -p /kylin/cdh/dn4
docker run -d \
-m 20G --cpus=14 \
-h dn4 --name dn4 \
-v /home/dev/cdh:/cdh \
-v /kylin/cdh/dn4:/kylin/cdh \
--privileged=true \
dave/cdh:base /sbin/init

<!-- echo "10.244.61.2 dn1
10.244.61.3 dn2
10.244.61.4 dn3
10.244.61.5 dn4
10.244.61.6 dn5
10.244.61.7 dn6

10.244.93.3 gateway1
10.244.5.3 kylin
10.244.32.2 master1
10.244.93.2 master2
10.244.5.2 master3
10.244.32.3 utility" >> /etc/hosts
 -->

 80.94：
 docker start  master1
 docker start  utility

 80.97：
 docker start master2
 docker start gateway1

 80.99：
 docker start master3
 docker start kylin

 80.201：
 docker start dn1
 docker start dn2
 docker start dn3

 80.98：
 docker start dn4


echo '10.244.32.2 master1
10.244.32.3   utility

10.244.93.2   master2
10.244.93.3   gateway1

10.244.5.2   master3
10.244.5.3   kylin

10.244.61.2   dn1
10.244.61.3   dn2
10.244.61.4   dn3

10.244.47.2   dn4' >> /etc/hosts

http://192.168.80.94:7180/cmf/
http://192.168.80.99:7070/kylin/

kylin.hbase.region.count.min 2
kylin.hbase.region.count.max 100
kylin.hbase.region.cut 3


cm-server:7180
kylin:7070
hue:8889
namenode:50070
nna:8088(proxy yarnmanager)
jobhistory all nodes:19888
#hiveServer:10002

docker build -t dave/cdh:base ./

test:
docker run -it --rm --name centos dave/cdh:base bash
进入bash后，ip addr查看各自ip，互相ping一下对方的ip，如果可以ping通，表示安装正常，否则请检查相关的安装步骤。
https://blog.csdn.net/baidu_38558076/article/details/103890319

cat Dockerfile 
# Version: 1.0.0
FROM centos:centos7 
MAINTAINER dave.zhao@zerofinance.com

VOLUME [ "/data", "/works" ]
RUN mkdir -p /works/shell
COPY script.sh /works/shell/ 

WORKDIR /works/shell/
RUN bash script.sh

#ENTRYPOINT [ "redis-server", "--protected-mode", "no", "--logfile", "/var/log/redis/redis-server.log" ]
#ENTRYPOINT [ "tail" ]
#CMD ["-f", "no", "/var/log/yum.log"]

#EXPOSE 6379


https://archive.cloudera.com/cm6/6.1.1/

yum install -y openssh-server openssh-clients initscripts rpcbind
systemctl enable rpcbind ; systemctl start rpcbind

流量再从flannel出去，其他host上看到的source ip就是flannel的网关ip
https://www.cnblogs.com/wjoyxt/p/9970837.html
https://github.com/coreos/flannel/issues/117
/usr/lib/systemd/system/docker.service
ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTIONS --ip-masq=false

python -c "import base64; print base64.standard_b64encode('ADMIN:KYLIN')"        
QURNSU46S1lMSU4=

curl -c ~/cookie.txt -X POST -H "Authorization: Basic QURNSU46S1lMSU4=" -H 'Content-Type: application/json' http://192.168.80.99:7070/kylin/api/user/authentication
{"userDetails":{"username":"ADMIN","password":"$2a$10$o3ktIWsGYxXNuUWQiYlZXOW5hWcqyNAFQsSSCSEWoC/BRVMAUjL32","authorities":[{"authority":"ROLE_ADMIN"},{"authority":"ROLE_ANALYST"},{"authority":"ROLE_MODELER"},{"authority":"ALL_USERS"}],"disabled":false,"defaultPassword":false,"locked":false,"lockedTime":0,"wrongTime":0,"uuid":"2218e5ca-5b7e-066d-ef30-487e83852233","last_modified":1591674148561,"version":"3.0.0.20500"}}

curl -b ~/cookie.txt -X POST -H "Authorization: Basic QURNSU46S1lMSU4=" -H 'Content-Type: application/json' http://192.168.80.99:7070/kylin/api/user/authentication/api/cubes?cubeName=cube_name&limit=15&offset=0

curl -X PUT --user ADMIN:KYLIN -H "Content-Type: application/json;charset=utf-8" -d '{ "startTime": 820454400000, "endTime": 821318400000, "buildType": "BUILD"}' http://192.168.80.99:7070/kylin/api/cubes/kylin_sales/build


dh -d --hostname=quickstart.cloudera --privileged=true -t -i -p 8888:8888 -p 8020:8020 -p 8022:8022 -p 7180:7180 -p 21050:21050 -p 50070:50070 -p 50075:50075 -p 50010:50010 -p 50020:50020 -p 8890:8890 -p 60010:60010 -p 10002:10002 -p 25010:25010 -p 25020:25020 -p 18088:18088 -p 8088:8088 -p 19888:19888 -p 7187:7187 -p 11000:11000 cloudera/quickstart /usr/bin/docker-quickstart

docker run --name cdh --hostname=quickstart.cloudera --privileged=true -t -i -p 8888:8888 -p 8020:8020 -p 8022:8022 -p 7180:7180 -p 21050:21050 -p 50070:50070 -p 50075:50075 -p 50010:50010 -p 50020:50020 -p 8890:8890 -p 60010:60010 -p 10002:10002 -p 25010:25010 -p 25020:25020 -p 18088:18088 -p 8088:8088 -p 19888:19888 -p 7187:7187 -p 11000:11000 cloudera/quickstart /bin/bash -c '/usr/bin/docker-quickstart && /home/cloudera/cloudera-manager --express && service ntpd start'


clusterdock_run ./bin/start_cluster cdh \
--include-service-types=HDFS,ZOOKEEPER,HBASE,YARN,HIVE,SPARK,SQOOP,HUE,OOZIE

root     21396  0.0  0.0 113320  1600 ?        S    Jun09   0:00 /bin/sh /works/app/mysql/bin/mysqld_safe --datadir=/works/data/mydata --pid-file=/works/app/mysql/mysql.pid
mysql    21907  3.6 21.5 16722256 14125472 ?   Sl   Jun09  53:49 /works/app/mysql/bin/mysqld --basedir=/works/app/mysql --datadir=/works/data/mydata --plugin-dir=/works/app/mysql/lib/plugin --user=mysql --log-error=sz-cos-80-98.err --pid-file=/works/app/mysql/mysql.pid --socket=/works/app/mysql/mysql.sock --port=3306

mysqladmin  -uroot -p -S /works/app/mysql/mysql.sock shutdown
/works/app/mysql/bin/mysqld_safe --datadir=/works/data/mydata &

BUILD CUBE - dwh_cube - 20200401000000_20200501000000 - CST 2020-06-10 14:34:04