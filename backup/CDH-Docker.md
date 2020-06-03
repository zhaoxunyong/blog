https://blog.csdn.net/xu470438000/article/details/50512442
https://www.cnblogs.com/Jing-Wang/p/10672609.html

docker run -d \
-m 12G --cpus=4 \
--name nna \
-p 50070:50070 -p 8088:8088 -p 19888:19888 \
-v /home/dev/vagrant:/vagrant \
centos:centos7 \
/bin/bash -c "tail -n100 -f /var/log/yum.log"

docker run -d \
-m 16G --cpus=8 \
--name nns \
-p 7180:7180 -p 8889:8889 -p 50070:50070 \
centos:centos7 \
/bin/bash -c "tail -n100 -f /var/log/yum.log"

docker run -d \
-m 16G --cpus=16 \
--name dn1 \
centos:centos7 \
/bin/bash -c "tail -n100 -f /var/log/yum.log"

docker run -d \
-m 16G --cpus=16 \
--name dn2 \
centos:centos7 \
/bin/bash -c "tail -n100 -f /var/log/yum.log"

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


docker build -t dave/hadoop:base ./