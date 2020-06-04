https://blog.csdn.net/xu470438000/article/details/50512442
https://www.cnblogs.com/Jing-Wang/p/10672609.html

sudo mkdir -p /cdh

80.201:64G/48Core
------------------------
10.244.62.2
docker run -d \
-m 8G --cpus=4 \
-h master1 --name master1 \
-p 50070:50070 -p 8088:8088 -p 19888:19888 \
-v /home/dev/vagrant:/vagrant \
--privileged=true \
dave/cdh:base /sbin/init

10.244.62.3
docker run -d \
-m 16G --cpus=12 \
-h dn1 --name dn1 \
-v /home/dev/vagrant:/vagrant \
-v /cdh:/cdh \
--privileged=true \
dave/cdh:base /sbin/init

10.244.62.4
docker run -d \
-m 16G --cpus=12 \
-h dn2 --name dn2 \
-v /home/dev/vagrant:/vagrant \
-v /cdh:/cdh \
--privileged=true \
dave/cdh:base /sbin/init

10.244.62.5
docker run -d \
-m 16G --cpus=12 \
-h dn3 --name dn3 \
-v /home/dev/vagrant:/vagrant \
-v /cdh:/cdh \
--privileged=true \
dave/cdh:base /sbin/init

80.196:64G/48Core
-------------
10.244.54.2
docker run -d \
-m 8G --cpus=4 \
-h master2 --name master2 \
-v /home/dev/vagrant:/vagrant \
-p 7180:7180 -p 8889:8889 -p 50070:50070 \
--privileged=true \
dave/cdh:base /sbin/init

10.244.54.3
docker run -d \
-m 16G --cpus=12 \
-h dn4 --name dn4 \
-v /home/dev/vagrant:/vagrant \
-v /cdh:/cdh \
--privileged=true \
dave/cdh:base /sbin/init

10.244.54.4
docker run -d \
-m 16G --cpus=12 \
-h dn5 --name dn5 \
-v /home/dev/vagrant:/vagrant \
-v /cdh:/cdh \
--privileged=true \
dave/cdh:base /sbin/init

10.244.54.5
docker run -d \
-m 16G --cpus=12 \
-h dn6 --name dn6 \
-v /home/dev/vagrant:/vagrant \
-v /cdh:/cdh \
--privileged=true \
dave/cdh:base /sbin/init

89.94:32G/8Core
-------------
10.244.46.2
docker run -d \
-m 16G --cpus=4 \
-h master3 --name master3 \
-v /home/dev/vagrant:/vagrant \
-p 7180:7180 -p 8889:8889 -p 50070:50070 \
--privileged=true \
dave/cdh:base /sbin/init

10.244.46.3
docker run -d \
-m 16G --cpus=4 \
-h kylin --name kylin \
-v /home/dev/vagrant:/vagrant \
-p 7070:7070 \
--privileged=true \
dave/cdh:base /sbin/init


cm-server:7180
kylin:7070
hue:8889
namenode:50070
nna:8088(proxy yarnmanager)
jobhistory all nodes:19888
#hiveServer:10002

-p 8020:8020 -p 8022:8022 -p 7180:7180 -p 21050:21050 -p 50070:50070 -p 50075:50075 -p 50010:50010 -p 50020:50020 -p 8890:8890 -p 60010:60010 -p 10002:10002 -p 25010:25010 -p 25020:25020 -p 18088:18088 -p 8088:8088 -p 19888:19888 -p 7187:7187 -p 11000:11000


nna:  12G/4C
nns:  16G/8C
dn1:  16G/16C
dn2:  16G/16C
dn3:  16G/16C
dn4:  16G/16C
kylin: 16G/8C


docker build -t dave/cdh:base ./

test:
docker run -it --rm --name centos centos bash
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