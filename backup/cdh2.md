https://blog.csdn.net/xu470438000/article/details/50512442
https://www.cnblogs.com/Jing-Wang/p/10672609.html


192.168.80.196     root    64G/48Core  10G/8C

192.168.80.94      root    32G/8Core   node1
192.168.80.97      root    32G/8Core   node2
192.168.80.99      root    32G/8Core   node3

192.168.80.201     root    64G/48Core  8G/4C master  24G/4C cmserver  16G/4C kylin
192.168.80.98      root    64G/16Core  node4/node5

10.244.96.2  master
10.244.96.3  cmserver
10.244.96.4  kylin
10.244.23.2  dn1
10.244.60.2  dn2
10.244.88.2  dn3
10.244.47.2  dn4
10.244.47.3  dn5


80.201
master:10.244.96.2
docker run -d \
-m 8G --cpus=4 \
-h master --name master \
-p 8088:8088 -p 19888:19888 -p 50070:50070 \
-v /etc/hosts:/etc/hosts \
-v /home/dev/cdh:/cdh \
--privileged=true \
192.168.100.87:5000/cdh:base /sbin/init

cmserver:10.244.96.3
docker run -d \
-m 24G --cpus=4 \
-h cmserver --name cmserver \
-p 7180:7180 -p 8889:8889 \
-v /etc/hosts:/etc/hosts \
-v /home/dev/cdh:/cdh \
--privileged=true \
192.168.100.87:5000/cdh:base /sbin/init

kylin:10.244.96.4
docker run -d \
-m 16G --cpus=4 \
-h kylin --name kylin \
-v /home/dev/cdh:/cdh \
-p 7070:7070 \
-v /etc/hosts:/etc/hosts \
--privileged=true \
192.168.100.87:5000/cdh:base /sbin/init

80.94
dn1:10.244.23.2
sudo mkdir -p /kylin/cdh/dn1
docker run -d \
-m 32G --cpus=8 \
-h dn1 --name dn1 \
-v /etc/hosts:/etc/hosts \
-v /home/dev/cdh:/cdh \
-v /kylin/cdh/dn1:/kylin/cdh \
--privileged=true \
192.168.100.87:5000/cdh:base /sbin/init

80.97
dn2:10.244.60.2
sudo mkdir -p /kylin/cdh/dn2
docker run -d \
-m 32G --cpus=8 \
-h dn2 --name dn2 \
-v /etc/hosts:/etc/hosts \
-v /home/dev/cdh:/cdh \
-v /kylin/cdh/dn2:/kylin/cdh \
--privileged=true \
192.168.100.87:5000/cdh:base /sbin/init

80.99
dn3:10.244.88.2
sudo mkdir -p /kylin/cdh/dn3
docker run -d \
-m 32G --cpus=8 \
-h dn3 --name dn3 \
-v /etc/hosts:/etc/hosts \
-v /home/dev/cdh:/cdh \
-v /kylin/cdh/dn3:/kylin/cdh \
--privileged=true \
192.168.100.87:5000/cdh:base /sbin/init

80.98
dn4:10.244.47.2
sudo mkdir -p /kylin/cdh/dn4
docker run -d \
-m 32G --cpus=8 \
-h dn4 --name dn4 \
-v /etc/hosts:/etc/hosts \
-v /home/dev/cdh:/cdh \
-v /kylin/cdh/dn4:/kylin/cdh \
--privileged=true \
192.168.100.87:5000/cdh:base /sbin/init

80.98
dn5:10.244.47.3
sudo mkdir -p /kylin/cdh/dn5
docker run -d \
-m 32G --cpus=8 \
-h dn5 --name dn5 \
-v /etc/hosts:/etc/hosts \
-v /home/dev/cdh:/cdh \
-v /kylin/cdh/dn5:/kylin/cdh \
--privileged=true \
192.168.100.87:5000/cdh:base /sbin/init
