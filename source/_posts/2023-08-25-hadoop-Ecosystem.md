---
title: hadoop Ecosystem
date: 2023-08-25 08:32:11
categories: ["Bigdata"]
tags: ["Bigdata"]
toc: true
---

Manage tool: Ambari+Bigtop
HDFS/YARN/MapReduce2/Tez/Hive/HBase/ZooKeeper/Spark/Zeppelin/Flink

Flink-cdc/datax/seatunnel/dolphinscheduler

<!-- more -->



## Introduction

Recommend: [heibaiying/BigData-Notes: 大数据入门指南 :star: (github.com)](https://github.com/heibaiying/BigData-Notes)

## Bigtop

Bigtop is an Apache Foundation project for Infrastructure Engineers and Data Scientists looking for comprehensive packaging, testing, and configuration of the leading open source big data components.** Bigtop supports a wide range of components/projects, including, but not limited to, Hadoop, HBase and Spark.



There are 2 ways to install bigtop:

### build package from source

***Not recommend, it's very complicate. especially in China mainland.

Prerequisite:

```bash
#Jdk
nvm install v12.22.1

cat /etc/profile.d/java.sh 
#!/bin/bash

export JAVA_HOME=/Developer/jdk1.8.0_371
export M2_HOME=/Developer/apache-maven-3.6.3
export _JAVA_OPTIONS="-Xms4g -Xmx4g -Djava.awt.headless=true"
export PATH=/root/.nvm/versions/node/v12.22.1/bin:$JAVA_HOME/bin:$M2_HOME/bin:$PATH

. /etc/profile
```

Building:

***Notice: Need a non-root to compile.***

```
sudo su - hadoop
wget https://dlcdn.apache.org/bigtop/bigtop-3.2.0/bigtop-3.2.0-project.tar.gz (use the suggested mirror from above)
tar xfvz bigtop-3.2.0-project.tar.gz
cd bigtop-3.2.0
#only for rpm packages
./gradlew bigtop-groovy-rpm bigtop-jsvc-rpm bigtop-select-rpm bigtop-utils-rpm \
flink-rpm hadoop-rpm hbase-rpm hive-rpm kafka-rpm solr-rpm spark-rpm \
tez-rpm zeppelin-rpm zookeeper-rpm -Dbuildwithdeps=true -PparentDir=/usr/bigtop -PpkgSuffix | tee -a log.txt
#it'll clean all of packages located inbuild/, be careful!
#./gradlew allclean 
```

Troubleshooting:

```
#lacking some of jars
wget https://www.zhangjc.com/images/20210817/pentaho-aggdesigner-algorithm-5.1.5-jhyde.jar
mvn install:install-file -Dfile=./pentaho-aggdesigner-algorithm-5.1.5-jhyde.jar -DgroupId=org.pentaho -DartifactId=pentaho-aggdesigner-algorithm -Dversion=5.1.5-jhyde -Dpackaging=jar

wget https://packages.confluent.io/maven/io/confluent/kafka-schema-registry-client/6.2.2/kafka-schema-registry-client-6.2.2.jar
mvn install:install-file -Dfile=./kafka-schema-registry-client-6.2.2.jar -DgroupId=io.confluent -DartifactId=kafka-schema-registry-client -Dversion=6.2.2 -Dpackaging=jar
mvn install:install-file -Dfile=./kafka-clients-2.8.1.jar -DgroupId=org.apache.kafka -DartifactId=kafka-clients -Dversion=2.8.1 -Dpackaging=jar

wget https://packages.confluent.io/maven/io/confluent/kafka-avro-serializer/6.2.2/kafka-avro-serializer-6.2.2.jar
mvn install:install-file -Dfile=./kafka-avro-serializer-6.2.2.jar -DgroupId=io.confluent -DartifactId=kafka-avro-serializer -Dversion=6.2.2 -Dpackaging=jar


cd dl/
tar zxf flink-1.15.3.tar.gz
rm -fr flink-1.15.3/flink-formats/flink-avro-confluent-registry/src/test/
rm -fr flink-1.15.3/flink-end-to-end-tests/flink-end-to-end-tests-common-kafka/src/test
rm -fr flink-1.15.3.tar.gz
tar -zcf flink-1.15.3.tar.gz flink-1.15.3
rm -fr flink-1.15.3
rm -fr /Developer/bigtop-3.2.0/build/flink/


tar zxf hadoop-3.3.4.tar.gz
vim hadoop-3.3.4-src/hadoop-yarn-project/hadoop-yarn/hadoop-yarn-applications/hadoop-yarn-applications-catalog/hadoop-yarn-applications-catalog-webapp/pom.xm
<nodejs.version>v14.0.0</nodejs.version>
rm -fr hadoop-3.3.4.tar.gz && tar -zcf hadoop-3.3.4.tar.gz hadoop-3.3.4-src && rm -fr hadoop-3.3.4-src
rm -fr /Developer/bigtop-3.2.0/build/hadoop/
```



### bigtop Repositories

It's a easy way to install, including ambari packages:

```bash
#Clone to local repository:
wget https://dlcdn.apache.org/bigtop/bigtop-3.2.1/repos/centos-7/bigtop.repo -O /etc/yum.repos.d/bigtop.repo
reposync --gpgcheck -1 --repoid=bigtop --download_path=/data/bigtop
cd /data/bigtop/bigtop
yum install createrepo
createrepo .

tree ./
.
├── bigtop
│   ├── alluxio
│   │   └── x86_64
│   │       └── alluxio-2.8.0-2.el7.x86_64.rpm
│   ├── ambari
│   │   ├── noarch
│   │   │   ├── ambari-agent-2.7.5.0-1.el7.noarch.rpm
│   │   │   └── ambari-server-2.7.5.0-1.el7.noarch.rpm
│   │   └── x86_64
│   │       ├── ambari-metrics-collector-2.7.5.0-0.x86_64.rpm
│   │       ├── ambari-metrics-grafana-2.7.5.0-0.x86_64.rpm
│   │       ├── ambari-metrics-hadoop-sink-2.7.5.0-0.x86_64.rpm
│   │       └── ambari-metrics-monitor-2.7.5.0-0.x86_64.rpm
│   ├── bigtop-ambari-mpack
│   │   └── noarch
│   │       └── bigtop-ambari-mpack-2.7.5.0-1.el7.noarch.rpm
│   ├── bigtop-groovy
│   │   └── noarch
│   │       └── bigtop-groovy-2.5.4-1.el7.noarch.rpm
│   ├── bigtop-jsvc
│   │   └── x86_64
│   │       ├── bigtop-jsvc-1.2.4-1.el7.x86_64.rpm
│   │       └── bigtop-jsvc-debuginfo-1.2.4-1.el7.x86_64.rpm
│   ├── bigtop-utils
│   │   └── noarch
│   │       └── bigtop-utils-3.2.1-1.el7.noarch.rpm
│   ├── flink
│   │   └── noarch
│   │       ├── flink-1.15.3-1.el7.noarch.rpm
│   │       ├── flink-jobmanager-1.15.3-1.el7.noarch.rpm
│   │       └── flink-taskmanager-1.15.3-1.el7.noarch.rpm
│   ├── gpdb
│   │   └── x86_64
│   │       └── gpdb-5.28.5-1.el7.x86_64.rpm
│   ├── hadoop
│   │   └── x86_64
│   │       ├── hadoop-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-client-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-conf-pseudo-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-debuginfo-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-doc-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-hdfs-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-hdfs-datanode-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-hdfs-dfsrouter-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-hdfs-fuse-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-hdfs-journalnode-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-hdfs-namenode-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-hdfs-secondarynamenode-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-hdfs-zkfc-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-httpfs-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-kms-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-libhdfs-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-libhdfs-devel-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-libhdfspp-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-libhdfspp-devel-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-mapreduce-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-mapreduce-historyserver-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-yarn-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-yarn-nodemanager-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-yarn-proxyserver-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-yarn-resourcemanager-3.3.5-1.el7.x86_64.rpm
│   │       ├── hadoop-yarn-router-3.3.5-1.el7.x86_64.rpm
│   │       └── hadoop-yarn-timelineserver-3.3.5-1.el7.x86_64.rpm
│   ├── hbase
│   │   ├── noarch
│   │   │   └── hbase-doc-2.4.13-2.el7.noarch.rpm
│   │   └── x86_64
│   │       ├── hbase-2.4.13-2.el7.x86_64.rpm
│   │       ├── hbase-master-2.4.13-2.el7.x86_64.rpm
│   │       ├── hbase-regionserver-2.4.13-2.el7.x86_64.rpm
│   │       ├── hbase-rest-2.4.13-2.el7.x86_64.rpm
│   │       ├── hbase-thrift2-2.4.13-2.el7.x86_64.rpm
│   │       └── hbase-thrift-2.4.13-2.el7.x86_64.rpm
│   ├── hive
│   │   └── noarch
│   │       ├── hive-3.1.3-1.el7.noarch.rpm
│   │       ├── hive-hbase-3.1.3-1.el7.noarch.rpm
│   │       ├── hive-hcatalog-3.1.3-1.el7.noarch.rpm
│   │       ├── hive-hcatalog-server-3.1.3-1.el7.noarch.rpm
│   │       ├── hive-jdbc-3.1.3-1.el7.noarch.rpm
│   │       ├── hive-metastore-3.1.3-1.el7.noarch.rpm
│   │       ├── hive-server2-3.1.3-1.el7.noarch.rpm
│   │       ├── hive-webhcat-3.1.3-1.el7.noarch.rpm
│   │       └── hive-webhcat-server-3.1.3-1.el7.noarch.rpm
│   ├── kafka
│   │   └── noarch
│   │       ├── kafka-2.8.1-2.el7.noarch.rpm
│   │       └── kafka-server-2.8.1-2.el7.noarch.rpm
│   ├── livy
│   │   └── noarch
│   │       └── livy-0.7.1-1.el7.noarch.rpm
│   ├── oozie
│   │   └── noarch
│   │       ├── oozie-5.2.1-2.el7.noarch.rpm
│   │       └── oozie-client-5.2.1-2.el7.noarch.rpm
│   ├── phoenix
│   │   └── noarch
│   │       └── phoenix-5.1.2-1.el7.noarch.rpm
│   ├── solr
│   │   └── noarch
│   │       ├── solr-8.11.2-1.el7.noarch.rpm
│   │       ├── solr-doc-8.11.2-1.el7.noarch.rpm
│   │       └── solr-server-8.11.2-1.el7.noarch.rpm
│   ├── spark
│   │   └── noarch
│   │       ├── spark-3.2.3-1.el7.noarch.rpm
│   │       ├── spark-core-3.2.3-1.el7.noarch.rpm
│   │       ├── spark-datanucleus-3.2.3-1.el7.noarch.rpm
│   │       ├── spark-external-3.2.3-1.el7.noarch.rpm
│   │       ├── spark-history-server-3.2.3-1.el7.noarch.rpm
│   │       ├── spark-master-3.2.3-1.el7.noarch.rpm
│   │       ├── spark-python-3.2.3-1.el7.noarch.rpm
│   │       ├── spark-sparkr-3.2.3-1.el7.noarch.rpm
│   │       ├── spark-thriftserver-3.2.3-1.el7.noarch.rpm
│   │       ├── spark-worker-3.2.3-1.el7.noarch.rpm
│   │       └── spark-yarn-shuffle-3.2.3-1.el7.noarch.rpm
│   ├── tez
│   │   └── noarch
│   │       └── tez-0.10.1-1.el7.noarch.rpm
│   ├── ycsb
│   │   └── noarch
│   │       └── ycsb-0.17.0-2.el7.noarch.rpm
│   ├── zeppelin
│   │   └── x86_64
│   │       └── zeppelin-0.10.1-1.el7.x86_64.rpm
│   └── zookeeper
│       └── x86_64
│           ├── zookeeper-3.5.9-2.el7.x86_64.rpm
│           ├── zookeeper-debuginfo-3.5.9-2.el7.x86_64.rpm
│           ├── zookeeper-native-3.5.9-2.el7.x86_64.rpm
│           ├── zookeeper-rest-3.5.9-2.el7.x86_64.rpm
│           └── zookeeper-server-3.5.9-2.el7.x86_64.rpm
```

## Ambari

The Apache Ambari project is aimed at making Hadoop management simpler by developing software for provisioning, managing, and monitoring Apache Hadoop clusters. Ambari provides an intuitive, easy-to-use Hadoop management web UI backed by its RESTful APIs.

***Notice: Bigtop repository has included all of ambari packages, you don't need to build. just need to build the latest version that bigtop not included.***

For installation, please follow this instructions: [Installation Guide for Ambari 2.8.0 - Apache Ambari - Apache Software Foundation](https://cwiki.apache.org/confluence/display/AMBARI/Installation+Guide+for+Ambari+2.8.0)

### Build  package from source

Prerequisite:

```bash
#Jdk
nvm install v12.22.1

cat /etc/profile.d/java.sh 
#!/bin/bash

export JAVA_HOME=/Developer/jdk1.8.0_371
export M2_HOME=/Developer/apache-maven-3.6.3
export _JAVA_OPTIONS="-Xms4g -Xmx4g -Djava.awt.headless=true"
export PATH=/root/.nvm/versions/node/v12.22.1/bin:$JAVA_HOME/bin:$M2_HOME/bin:$PATH

. /etc/profile

#OS environment:
#swap>=6G:
dd if=/dev/zero of=/myswap.swp bs=1k count=4194304 #The vm has been included 2g memory. 
mkswap /myswap.swp
swapon /myswap.swp
free -m
chmod +x /etc/rc.local
chmod +x /etc/rc.d/rc.local

echo "swapon /myswap.swp" >> /etc/rc.local

groupadd hadoop
useradd -m -g hadoop hadoop
passwd hadoop
chmod +w /etc/sudoers
echo "hadoop ALL=(ALL)NOPASSWD: ALL" >> /etc/sudoers
chmod -w /etc/sudoers
```

Build package from source

```
#https://cwiki.apache.org/confluence/display/AMBARI/Installation+Guide+for+Ambari+2.8.0
Centos 7.9:
yum install -y git python-devel rpm-build gcc-c++

wget https://pypi.python.org/packages/2.7/s/setuptools/setuptools-0.6c11-py2.7.egg#md5=fe1f997bc722265116870bc7919059ea
sh setuptools-0.6c11-py2.7.egg

wget https://dlcdn.apache.org/ambari/ambari-2.8.0/apache-ambari-2.8.0-src.tar.gz (use the suggested mirror from above)
tar xfvz apache-ambari-2.8.0-src.tar.gz
cd apache-ambari-2.8.0-src
mvn clean install rpm:rpm -DskipTests -Drat.skip=true
```

Build your yum repository:

See: [bigtop Section](#Bigtop)



### Installing Ambari

Performence:

| IP地址         | Role                                                         |
| -------------- | ------------------------------------------------------------ |
| 192.168.80.225 | NameNode     ResourceManager     HBase Master     MySQL     Zeppelin Server     Grafana     flume     ds-master ds-api   ds-alert     Ambari Server     Ambari Agant |
| 192.168.80.226 | SNameNode     HBase Master     JobHistory Server     Flink History Server     Spark History Server     Spark Thrift Server     Hive Metastore     HiveServer2     WebHCat Server     Datax-webui     flume     Ambari Agant |
| 192.168.80.227 | DataNode     NodeManager     Zookeeper     JournalNode     RegionServer     ds-worker     Datax worknode     Ambari Agant |
| 192.168.80.228 | DataNode     NodeManager     Zookeeper     JournalNode     RegionServer     ds-worker     Datax worknode     Ambari Agant |
| 192.168.80.229 | DataNode     NodeManager     Zookeeper     JournalNode     RegionServer     ds-worker     Datax worknode     Ambari Metrics Collectors     Ambari Agant |

HA:

| IP地址         | Role                                                         |
| -------------- | ------------------------------------------------------------ |
| 192.168.80.225 | NameNode     ResourceManager(Single)     JobHistory Server(Single)     HBase Master     Flink History Server     Spark History Server     Hive Metastore     HiveServer2     WebHCat Server(Single)     Zeppelin Server(Single)     MySQL(Single)     Grafana(Single)     flume     ds-master      ds-api      ds-alert     Ambari Metrics Collectors     Ambari Server     Ambari Agant |
| 192.168.80.226 | SNameNode     HBase Master     Flink History Server     Spark History Server     Hive Metastore     HiveServer2     ds-master     Ambari Metrics Collectors     flume     Ambari Agant |
| 192.168.80.227 | DataNode     NodeManager     Zookeeper     JournalNode     Kafka Broker     Spark Thrift Server     RegionServer     ds-worker     Datax worknode     Ambari Agant |
| 192.168.80.228 | DataNode     NodeManager     Zookeeper     JournalNode     Kafka Broker     Spark Thrift Server     RegionServer     ds-worker     Datax worknode     Ambari Agant |
| 192.168.80.229 | DataNode     NodeManager     Zookeeper     JournalNode     Kafka Broker     Spark Thrift Server     RegionServer     ds-worker     Datax worknode     Ambari Agant |

#### Vagrant Docker

##### Dockerfile.centos

```dockerfile
cd /works/tools/vagrant

cat Dockerfile.centos 
#version: 1.0.0

FROM centos:7

ENV WORK_SHELL /startup
WORKDIR /works

ADD script.sh docker-entrypoint.sh $WORK_SHELL/

RUN chmod +x $WORK_SHELL/*.sh

RUN $WORK_SHELL/script.sh

ENTRYPOINT ["/startup/docker-entrypoint.sh"]
#CMD ["bash", "-c" ,"$WORK_SHELL/init.sh"]
```



##### docker-entrypoint.sh

```bash
cat docker-entrypoint.sh 
#!/bin/bash

# run the command given as arguments from CMD
exec "$@"
```

##### script.sh

```bash
cat script.sh 
#!/bin/bash -x
#http://www.360doc.com/content/14/1125/19/7044580_428024359.shtml
#http://blog.csdn.net/54powerman/article/details/50684844
#http://c.biancheng.net/cpp/view/2739.html
echo "scripting......"

yum -y install net-tools iproute iproute-doc wget sudo

sed -i 's;SELINUX=.*;SELINUX=disabled;' /etc/selinux/config
setenforce 0
getenforce

#LANG="en_US.UTF-8"
#sed -i 's;LANG=.*;LANG="zh_CN.UTF-8";' /etc/locale.conf

cat /etc/NetworkManager/NetworkManager.conf|grep "dns=none" > /dev/null
if [[ $? != 0 ]]; then
    echo "dns=none" >> /etc/NetworkManager/NetworkManager.conf
    systemctl restart NetworkManager.service
fi

systemctl disable iptables
systemctl stop iptables
systemctl disable firewalld
systemctl stop firewalld

#ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
timedatectl set-timezone Asia/Shanghai

#logined limit
cat /etc/security/limits.conf|grep "^root" > /dev/null
if [[ $? != 0 ]]; then
                cat >> /etc/security/limits.conf  << EOF
root            -    nofile             100000
root            -    nproc              100000
*               -    nofile             100000
*               -    nproc              100000
EOF
fi

#systemd service limit
cat /etc/systemd/system.conf|egrep '^DefaultLimitNOFILE' > /dev/null
if [[ $? != 0 ]]; then
                cat >> /etc/systemd/system.conf << EOF
DefaultLimitCORE=infinity
DefaultLimitNOFILE=100000
DefaultLimitNPROC=100000
EOF
fi
#user service limit
cat /etc/systemd/user.conf|egrep '^DefaultLimitNOFILE' > /dev/null
if [[ $? != 0 ]]; then
                cat >> /etc/systemd/system.conf << EOF
DefaultLimitCORE=infinity
DefaultLimitNOFILE=100000
DefaultLimitNPROC=100000
EOF
fi

cat /etc/sysctl.conf|grep "net.ipv4.ip_local_port_range" > /dev/null
if [[ $? != 0 ]]; then
cat >> /etc/sysctl.conf  << EOF
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.ip_forward = 1
#k8s
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p
fi

su - root -c "ulimit -a"

#echo "192.168.10.6   k8s-master
#192.168.10.7   k8s-node1
#192.168.10.8   k8s-node2" >> /etc/hosts

#tee /etc/resolv.conf << EOF
#search myk8s.com
#nameserver 114.114.114.114
#nameserver 8.8.8.8
#EOF

#yum -y install gcc kernel-devel
mv -f /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
# wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel-7.repo http://mirrors.aliyun.com/repo/epel-7.repo

yum -y install epel-release

sudo mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
sudo mv /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup

cat > /etc/yum.repos.d/epel.repo  << EOF
[epel]
name=Extra Packages for Enterprise Linux 7 - \$basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/\$basearch
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - \$basearch - Debug
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/\$basearch/debug
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
[epel-source]
name=Extra Packages for Enterprise Linux 7 - \$basearch - Source
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/SRPMS
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
EOF

yum clean all
yum makecache

#yum -y install createrepo rpm-sign rng-tools yum-utils 
yum -y install htop bind-utils bridge-utils ntpdate setuptool iptables system-config-securitylevel-tui system-config-network-tui \
 ntsysv net-tools lrzsz telnet lsof vim dos2unix unix2dos zip unzip \
 lsof openssl openssh-server openssh-clients expect

sed -i 's;#PasswordAuthentication yes;PasswordAuthentication yes;g' /etc/ssh/sshd_config
sed -i 's;#PermitRootLogin yes;PermitRootLogin yes;g' /etc/ssh/sshd_config
#systemctl enable sshd
#systemctl restart sshd
```

##### buildImages.sh

```dockerfile
cat buildImages.sh 
#!/bin/bash

DOCKER_BUILDKIT=0 docker build -t "registry.zerofinance.net/library/centos:7" . -f Dockerfile.centos
```

##### Push image

```
docker login registry.zerofinance.net
admin
********

docker push registry.zerofinance.net/library/centos:7
```



##### Vagrantfile

```ruby
cat Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.hostname = "namenode01-test.zerofinance.net"
  config.vm.network "public_network", ip: "192.168.80.225", netmask: "255.255.255.0", gateway: "192.168.80.254", bridge: "em1"
  config.vm.provider "docker" do |d|
    d.image = "registry.zerofinance.net/library/centos:7"
    d.create_args = ["--hostname=namenode01-test.zerofinance.net", "--cpus=12", "--cpu-shares=12000", "-m=30g", "--memory-reservation=1g", "-v", "/etc/hosts:/etc/hosts", "-v", "/data:/data", "-v", "/sys/fs/cgroup:/sys/fs/cgroup"]
    d.privileged = true
    d.cmd = ["/usr/sbin/init"]
  end

  config.vm.provision "shell", run: "always", inline: <<-SHELL
    #yum -y install net-tools > /dev/null
    route del default gw 172.17.0.1
    route add default gw 192.168.80.254
    chmod +x /etc/rc.local
    chmod +x /etc/rc.d/rc.local
    echo "route del default gw 172.17.0.1
    route add default gw 192.168.80.254" >> /etc/rc.local
  SHELL

  #config.vm.provision "shell",
  #  run: "always",
  #  inline: "route del default gw 172.17.0.1"

  #config.vm.provision "shell" do |s|
  #  s.path = "script.sh"
  #  #s.args = ["--bip=10.1.10.1/24"]
  #end

end
```

##### Vagrant start

```bash
vagrant up
#When it's done, you need to change root passwd
#https://developer.hashicorp.com/vagrant/docs/providers/docker/commands
vagrant docker-exec -it -- /bin/bash
#Change password:
passwd

#If multiple nodes in Vagrantfile:
#node1 can be shown with command: vagrant status
#vagrant docker-exec node1 -it -- /bin/bash

#Or using nature docker command 
docker exec -it <ContainerId> /bin/bash

#shutdown
vagrant halt

#start
vagrant up

#restart
vagrant restart

#More usuage can be found: https://blog.gcalls.cn/2022/04/A-Guide-to-Vagrant.html
```

#### Initiation

##### SSH Without Password

```bash
#Working all machines:
groupadd hadoop
useradd -m -g hadoop hadoop
passwd hadoop
chmod +w /etc/sudoers
echo "hadoop ALL=(ALL)NOPASSWD: ALL" >> /etc/sudoers
chmod -w /etc/sudoers
mkdir -p ~/.ssh/

#Working on 192.168.80.225
sudo su - hadoop
ssh-keygen -t rsa
#Writing to ~/.ssh/authorized_keys：
ssh-copy-id -i ~/.ssh/id_rsa.pub hadoop@192.168.80.225
#cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
sudo chmod 700 ~/.ssh
sudo chmod 600 ~/.ssh/authorized_keys

#All machine can ssh without password: 
scp ~/.ssh/* hadoop@192.168.80.84:~/.ssh/
scp ~/.ssh/* hadoop@192.168.80.85:~/.ssh/

#Just need 80.225 can ssh without password:
#scp ~/.ssh/authorized_keys hadoop@192.168.80.226:~/.ssh/
#scp ~/.ssh/authorized_keys hadoop@192.168.80.227:~/.ssh/
#scp ~/.ssh/authorized_keys hadoop@192.168.80.228:~/.ssh/
#scp ~/.ssh/authorized_keys hadoop@192.168.80.229:~/.ssh/
```

##### Optional: Docker CentOS

```bash
#If your centos is installed on docker:
#For example: 192.168.80.225, vice versa:
route del default gw 172.17.0.1
route add default gw 192.168.80.254
chmod +x /etc/rc.local
chmod +x /etc/rc.d/rc.local
echo "ifconfig eth0 down
route del default gw 172.17.0.1
route add default gw 192.168.80.254" >> /etc/rc.local

echo "192.168.80.225   localhost localhost.localdomain localhost4 localhost4.localdomain4
#::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.80.225 namenode01-test.zerofinance.net namenode01-test
192.168.80.226 namenode02-test.zerofinance.net namenode02-test
192.168.80.227 datanode01-test.zerofinance.net datanode01-test
192.168.80.228 datanode02-test.zerofinance.net datanode02-test
192.168.80.229 datanode03-test.zerofinance.net datanode03-test" >> /etc/hosts
```

##### NTP

```bash
#https://www.cnblogs.com/Sungeek/p/10197345.html
#Working on all:
sudo yum -y install ntp
sudo timedatectl set-timezone Asia/Shanghai

192.168.80.225：
vim /etc/ntp.conf
restrict 0.0.0.0 mask 0.0.0.0 nomodify notrap
server 127.127.1.0
fudge  127.127.1.0 stratum 10

#server 0.centos.pool.ntp.org iburst
#server 1.centos.pool.ntp.org iburst
#server 2.centos.pool.ntp.org iburst
#server 3.centos.pool.ntp.org iburst
server 0.cn.pool.ntp.org iburst
server 1.cn.pool.ntp.org iburst
server 2.cn.pool.ntp.org iburst
server 3.cn.pool.ntp.org iburst

#start
systemctl enable ntpd
systemctl start ntpd

#check
ntpq -p

#NTP Client Config on：192.168.80.{226,227,228,229}
vim /etc/ntp.conf

restrict 192.168.101.83 nomodify notrap noquery

#server 0.centos.pool.ntp.org iburst
#server 1.centos.pool.ntp.org iburst
#server 2.centos.pool.ntp.org iburst
#server 3.centos.pool.ntp.org iburst
server 192.168.101.83

#start
systemctl start ntpd
systemctl enable ntpd

#check
ntpdate -u 192.168.80.225
sudo ntpstat
```

##### Environment variables 

```bash
cat /etc/profile.d/my_env.sh 
export JAVA_HOME=/works/app/jdk/jdk1.8.0_371
export HADOOP_HOME=/usr/bigtop/current/hadoop-client
export HADOOP_CONF_DIR=/usr/bigtop/current/hadoop-client/etc/hadoop/
export HADOOP_CLASSPATH=`hadoop classpath`
export SPARK_HOME=/usr/bigtop/current/spark-client
export HIVE_HOME=/usr/bigtop/current/hive-client
export FLINK_HOME=/usr/bigtop/current/flink-client
export ZOOKEEPER_HOME=/usr/bigtop/current/zookeeper-client
export PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$SPARK_HOME/bin:$HIVE_HOME/bin:$FLINK_HOME/bin:$ZOOKEEPER_HOME/bin:$PATH
```

##### Installation

###### MySQL

```bash
#install on 80.225
#https://blog.csdn.net/weixin_43967842/article/details/124515431
#https://docs.cloudera.com/HDPDocuments/Ambari-latest/administering-ambari/content/amb_using_ambari_with_mysql_or_mariadb.html
wget https://dev.mysql.com/get/mysql57-community-release-el7-10.noarch.rpm
yum -y install ./mysql57-community-release-el7-10.noarch.rpm
vim /etc/yum.repos.d/mysql-community.repo
[mysql57-community]
...
gpgcheck=0
...

yum -y install mysql-community-server

vim /etc/my.cnf
max_connections=2000

character-set-server=utf8
collation-server=utf8_general_ci
lower_case_table_names=1

systemctl enable mysqld
systemctl start mysqld

#temporary password：
grep 'temporary password' /var/log/mysqld.log

mysql -uroot -p
set global validate_password_policy=0;
alter user 'root'@'localhost' identified by 'Aa123456';
CREATE USER 'ambari'@'%' IDENTIFIED BY 'Aa123456';
GRANT ALL PRIVILEGES ON ambari.* TO 'ambari'@'%';
FLUSH PRIVILEGES;
exit
```

###### Ambari Server

```bash
#192.168.80.225 With Root:
#https://cloud.tencent.com/works/app/jdk/article/1375511

cd /vagrant
sudo yum install ./ambari-server-2.8.0.0-0.x86_64.rpm

#Troubleshooting
/usr/sbin/ambari-server: line 34: buildNumber: unbound variable

sed -i 's;${buildNumber};${VERSION};g' /usr/sbin/ambari-server
sed -i 's;${buildNumber};${VERSION};g' /etc/rc.d/init.d/ambari-server

ambari-server setup --jdbc-db=mysql --jdbc-driver=/vagrant/mysql-connector-j-8.0.31.jar

#Init MySQL
> mysql -u ambari -p
CREATE DATABASE ambari;
USE ambari;
SOURCE /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql;
exit

> mysql -uroot -p
CREATE DATABASE hive;
CREATE USER 'hive'@'%' IDENTIFIED BY 'Aa123456';
GRANT ALL PRIVILEGES ON hive.* TO 'hive'@'%';
FLUSH PRIVILEGES;
exit

> ambari-server setup
Using python  /usr/bin/python
Setup ambari-server
Checking SELinux...
WARNING: Could not run /usr/sbin/sestatus: OK
Customize user account for ambari-server daemon [y/n] (n)? y
Enter user account for ambari-server daemon (root):hadoop
Adjusting ambari-server permissions and ownership...
Checking firewall status...
Checking JDK...
[1] Oracle JDK 1.8 + Java Cryptography Extension (JCE) Policy Files 8
[2] Custom JDK
==============================================================================
Enter choice (1): 2
WARNING: JDK must be installed on all hosts and JAVA_HOME must be valid on all hosts.
WARNING: JCE Policy files are required for configuring Kerberos security. If you plan to use Kerberos,please make sure JCE Unlimited Strength Jurisdiction Policy Files are valid on all hosts.
Path to JAVA_HOME: /works/app/jdk/jdk1.8.0_371
Validating JDK on Ambari Server...done.
Check JDK version for Ambari Server...
JDK version found: 8
Minimum JDK version is 8 for Ambari. Skipping to setup different JDK for Ambari Server.
Checking GPL software agreement...
GPL License for LZO: https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html
Enable Ambari Server to download and install GPL Licensed LZO packages [y/n] (n)? y
Completing setup...
Configuring database...
Enter advanced database configuration [y/n] (n)? y
Configuring database...
==============================================================================
Choose one of the following options:
[1] - PostgreSQL (Embedded)
[2] - Oracle
[3] - MySQL / MariaDB
[4] - PostgreSQL
[5] - Microsoft SQL Server (Tech Preview)
[6] - SQL Anywhere
[7] - BDB
==============================================================================
Enter choice (1): 3
Hostname (localhost): namenode01-test.zerofinance.net
Port (3306): 
Database name (ambari): 
Username (ambari): 
Enter Database Password (bigdata): 
Re-enter password: 
Configuring ambari database...
Enter full path to custom jdbc driver: /var/lib/ambari-server/resources/mysql-connector-java.jar
Copying /var/lib/ambari-server/resources/mysql-connector-java.jar to /usr/share/java
Configuring remote database connection properties...
WARNING: Before starting Ambari Server, you must run the following DDL directly from the database shell to create the schema: /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql
Proceed with configuring remote database connection properties [y/n] (y)? y
Extracting system views...
ambari-admin-2.8.0.0.0.jar

Ambari repo file doesn't contain latest json url, skipping repoinfos modification
Adjusting ambari-server permissions and ownership...
Ambari Server 'setup' completed successfully.

#Troubleshooting
rm -fr /usr/share/java && mkdir -p /usr/share/java
cp -a /vagrant/mysql-connector-j-8.0.31.jar /usr/share/java/

#Start
systemctl enable ambari-server
systemctl start ambari-server


```

###### Ambari Agent

```
#Install ambari angent on all machines:
cd /vagrant/
yum install ./ambari-agent-2.8.0.0-0.x86_64.rpm

sed -i 's;${buildNumber};${VERSION};g' /var/lib/ambari-agent/bin/ambari-agent
systemctl enable ambari-agent.service
systemctl start ambari-agent.service 
```

###### bigtop repo

```
#bigtop repo(192.168.80.225): 
cd /vagrant/bigdatarepo
yum install createrepo
createrepo .
nohup python -m SimpleHTTPServer &
http://192.168.80.225:8000/
```

###### Install Hadoop

```bash
web portal:
http://192.168.101.83:8080/
admin/admin

#input machine informations:
namenode01-test.zerofinance.net
namenode02-test.zerofinance.net
datanode01-test.zerofinance.net
datanode02-test.zerofinance.net
datanode03-test.zerofinance.net

#Using .ssh-key to setup

#Notice:
Cluster Name : dwh
Chose the hdfs account as "hadoop" not "hdfs"

Repositories:
http://192.168.80.225:8000/
```

###### Troubleshooting

```bash
1.hive went wrong by:
Sys DB and Information Schema not created yet

#Login on specific machine：
cd /etc/hive/
touch /etc/hive/sys.db.created
#restart ambari-server
sudo systemctl restart ambari-server

#Add new component, an error was caucse:
ambari 500 status code received on POST method for API:
#https://www.jianshu.com/p/3b54ba251c9e
chown -R hadoop:hadoop /var/run/ambari-server

#Cannot create /var/run/ambari-server/stack-recommendations:
chown -R hadoop:hadoop /var/run/ambari-server

#Web Portal：
HDFS--->CONFIGS: 
search for hive, changed hadoop.proxyuser.hive.hosts to *

#mkdir: Permission denied: user=root, access=WRITE, inode="/":hdfs:hdfs:drwxr-xr-x
https://blog.csdn.net/gdkyxy2013/article/details/105254907

#zeppelin cannot ran flink 1.15.3：
cd /usr/bigtop/current/flink-client/lib
mv flink-dist-1.15.3.jar flink-dist_2.12-1.15.3.jar
#zeppelin does not support with flink 1.15.3, see: 
#https://github.com/apache/zeppelin/blob/v0.10.1/flink/flink-shims/src/main/java/org/apache/zeppelin/flink/FlinkShims.java

#zeppelin open job function:
Ambari--->Zeppelin--->Custom zeppelin-site:
zeppelin.jobmanager.enable: true
#reboot zeppelin.

#Troubleshooting ambari metric
#https://cwiki.apache.org/confluence/display/AMBARI/Cleaning+up+Ambari+Metrics+System+Data
#https://www.jianshu.com/p/3fa7a23818a1
#https://xieshaohu.wordpress.com/2021/06/15/ambari-metrics%E5%90%AF%E5%8A%A8%E5%90%8E%E8%87%AA%E5%8A%A8%E5%81%9C%E6%AD%A2/

CONFIG:
hbase.tmp.dir--->/var/lib/ambari-metrics-collector/hbase-tmp

zkCli.sh
deleteall /ams-hbase-unsecure /ambari-metrics-cluster

sudo -u hadoop hadoop fs -mv /user/ams/hbase /user/ams/hbase.bak
sudo -u hadoop hadoop fs -mkdir /user/ams/hbase
rm -fr /var/lib/ambari-metrics-collector/*
rm -fr  /vagrant/var/
#restart Ambari Metrics on web ui.

#Ambari Metrics Grafana password creation failed. PUT request status: 401 Unauthorized
ambari-metrics-monitor status
ambari-metrics-collector status
mv /var/lib/ambari-metrics-grafana/grafana.db /tmp/
or:
#https://blog.csdn.net/qq_37865420/article/details/104040970
#https://cloud.tencent.com/developer/ask/sof/114883574
sqlite3 /var/lib/ambari-metrics-grafana/grafana.db

sqlite> update user set password = '59acf18b94d7eb0694c61e60ce44c110c7a683ac6a8f09580d626f90f4a242000746579358d77dd9e570e83fa24faa88a8a6', salt = 'F3FAxVm33R' where login = 'admin';

sqlite> .exit
```

## dolphinscheduler

```bash
#https://dolphinscheduler.apache.org/zh-cn/docs/3.1.8/guide/installation/pseudo-cluster
#Must install with hadoop account:
sudo su - hadoop
#docker env: need to shutdown eth0 or cannot register the actual ip to zokeeper: 
ifconfig eth0 down

#https://blog.csdn.net/Keyuchen_01/article/details/128653687
mysql -uroot -p
set global validate_password_policy=0;
CREATE DATABASE dolphinscheduler DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE USER 'ds'@'%' IDENTIFIED BY 'Aa123456';
GRANT ALL PRIVILEGES ON dolphinscheduler.* TO 'ds'@'%';
FLUSH PRIVILEGES;

#mkdir lib
#cp mysql-connector-j-8.0.31.jar ./apache-dolphinscheduler-3.1.2-bin/lib/
cp mysql-connector-j-8.0.31.jar ./apache-dolphinscheduler-3.1.2-bin/api-server/libs/
cp mysql-connector-j-8.0.31.jar ./apache-dolphinscheduler-3.1.2-bin/alert-server/libs/
cp mysql-connector-j-8.0.31.jar ./apache-dolphinscheduler-3.1.2-bin/master-server/libs/
cp mysql-connector-j-8.0.31.jar ./apache-dolphinscheduler-3.1.2-bin/worker-server/libs/
cp mysql-connector-j-8.0.31.jar ./apache-dolphinscheduler-3.1.2-bin/tools/libs/

vim bin/env/install_env.sh
ips=${ips:-"namenode01-test.zerofinance.net,namenode02-test.zerofinance.net,datanode01-test.zerofinance.net,datanode02-test.zerofinance.net,datanode03-test.zerofinance.net"}
masters=${masters:-"namenode01-test.zerofinance.net,namenode02-test.zerofinance.net"}
workers=${workers:-"datanode01-test.zerofinance.net:default,datanode02-test.zerofinance.net:default,datanode03-test.zerofinance.net:default"}
alertServer=${alertServer:-"namenode01-test.zerofinance.net"}
apiServers=${apiServers:-"namenode01-test.zerofinance.net"}
deployUser=${deployUser:-"hadoop"}
installPath=${installPath:-"/works/app/dolphinscheduler"}

vim bin/env/dolphinscheduler_env.sh
export JAVA_HOME=${JAVA_HOME:-/works/app/jdk/jdk1.8.0_371}
export DATABASE=${DATABASE:-mysql}
export SPRING_PROFILES_ACTIVE=${DATABASE}
export SPRING_DATASOURCE_URL=jdbc:mysql://192.168.80.225:3306/dolphinscheduler?useUnicode=true&characterEncoding=UTF-8&useSSL=false
export SPRING_DATASOURCE_USERNAME=ds
export SPRING_DATASOURCE_PASSWORD=Aa123456

export REGISTRY_ZOOKEEPER_CONNECT_STRING=${REGISTRY_ZOOKEEPER_CONNECT_STRING:-datanode01-test.zerofinance.net:2181,datanode02-test.zerofinance.net:2181,datanode03-test.zerofinanc
e.net:2181}

export HADOOP_HOME=${HADOOP_HOME:-/usr/bigtop/current/hadoop-client}
export HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-/usr/bigtop/current/hadoop-client/etc/hadoop/}
export SPARK_HOME1=${SPARK_HOME1:-/usr/bigtop/current/spark-client}
#export SPARK_HOME2=${SPARK_HOME2:-/opt/soft/spark2}
export PYTHON_HOME=${PYTHON_HOME:-/usr}
export HIVE_HOME=${HIVE_HOME:-/usr/bigtop/current/hive-client}
export FLINK_HOME=${FLINK_HOME:-/usr/bigtop/current/flink-client}
export DATAX_HOME=${DATAX_HOME:-/opt/soft/datax}
export SEATUNNEL_HOME=${SEATUNNEL_HOME:-/opt/soft/seatunnel}
export CHUNJUN_HOME=${CHUNJUN_HOME:-/opt/soft/chunjun}

cd /vagrant/apache-dolphinscheduler-3.1.2-bin
bash tools/bin/upgrade-schema.sh
sh bin/install.sh

Web Portal:
http://namenode01-test.zerofinance.net:12345/dolphinscheduler/ui
```

## Summary

```
Components:                  
  HDFS/YARN/MapReduce2/Tez/Hive/Hbase/ZooKeeper/Spark/Zeppelin/Flink/Datax/Dolphinscheduler/Flume
Compoments path:        
  /usr/bigtop/current/{hadoop-client,spark-client,hive-client,flink-client}
Vagrant root folder:      
  /works/tools/vagrant

Ambari UI:                       
  http://namenode01-test.zerofinance.net:8080/                      
  admin/admin
Dolphinescheduler UI:   
  http://namenode01-test.zerofinance.net:12345/dolphinscheduler/ui                 
  admin/dolphinscheduler123
Kafka Brokers:                
  192.168.65.107:9092,192.168.65.108:9092,192.168.66.110:9092
Kafka UI:                          
  https://kafka-ui-test.zerofinance.net/     admin/admin
```



## Hadoop

The Apache™ Hadoop® project develops open-source software for reliable, scalable, distributed computing.

The Apache Hadoop software library is a framework that allows for the distributed processing of large data sets across clusters of computers using simple programming models. It is designed to scale up from single servers to thousands of machines, each offering local computation and storage. Rather than rely on hardware to deliver high-availability, the library itself is designed to detect and handle failures at the application layer, so delivering a highly-available service on top of a cluster of computers, each of which may be prone to failures.



Introduction: [BigData-Notes/notes/Hadoop-HDFS.md at master · heibaiying/BigData-Notes (github.com)](https://github.com/heibaiying/BigData-Notes/blob/master/notes/Hadoop-HDFS.md)

Shell: [BigData-Notes/notes/HDFS常用Shell命令.md at master · heibaiying/BigData-Notes (github.com)](https://github.com/heibaiying/BigData-Notes/blob/master/notes/HDFS常用Shell命令.md)

​           [FileSystemShell](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/FileSystemShell.html)

HDFS: [BigData-Notes/notes/Hadoop-HDFS.md at master · heibaiying/BigData-Notes (github.com)](https://github.com/heibaiying/BigData-Notes/blob/master/notes/Hadoop-HDFS.md)

MapReduce2: [BigData-Notes/notes/Hadoop-MapReduce.md at master · heibaiying/BigData-Notes (github.com)](https://github.com/heibaiying/BigData-Notes/blob/master/notes/Hadoop-MapReduce.md)

YARN: [BigData-Notes/notes/Hadoop-YARN.md at master · heibaiying/BigData-Notes (github.com)](https://github.com/heibaiying/BigData-Notes/blob/master/notes/Hadoop-YARN.md)

JavaAPI: [BigData-Notes/notes/HDFS-Java-API.md at master · heibaiying/BigData-Notes (github.com)](https://github.com/heibaiying/BigData-Notes/blob/master/notes/HDFS-Java-API.md)

### Windows Client

```bash
git clone https://gitcode.net/mirrors/cdarlint/winutils
cp -a winutils/hadoop-3.3.5 /Developer/
#Set variable in environment:
set HADOOP_HOME=D:\Developer\hadoop-3.3.5
Add PATH as: %HADOOP_HOME%\bin
```

### Configuation

Put core-site.xml and hdfs-site.xml to resources folder of your java project:

#### core-site.xml

```xml
  <configuration  xmlns:xi="http://www.w3.org/2001/XInclude">

    <property>
      <name>fs.defaultFS</name>
      <value>hdfs://mycluster</value>
    </property>
    
  </configuration>
```

#### hdfs-site.xml

```xml
<configuration xmlns:xi="http://www.w3.org/2001/XInclude">

    <property>
        <name>dfs.nameservices</name>
        <value>mycluster</value>
    </property>

    <property>
        <name>dfs.internal.nameservices</name>
        <value>mycluster</value>
    </property>

    <property>
        <name>dfs.ha.namenodes.mycluster</name>
        <value>nn1,nn2</value>
    </property>

    <property>
        <name>dfs.namenode.http-address.mycluster.nn1</name>
        <value>namenode01-test.zerofinance.net:50070</value>
    </property>

    <property>
        <name>dfs.namenode.http-address.mycluster.nn2</name>
        <value>namenode02-test.zerofinance.net:50070</value>
    </property>

    <property>
        <name>dfs.namenode.https-address.mycluster.nn1</name>
        <value>namenode01-test.zerofinance.net:50470</value>
    </property>

    <property>
        <name>dfs.namenode.https-address.mycluster.nn2</name>
        <value>namenode02-test.zerofinance.net:50470</value>
    </property>

    <property>
        <name>dfs.namenode.rpc-address.mycluster.nn1</name>
        <value>namenode01-test.zerofinance.net:8020</value>
    </property>

    <property>
        <name>dfs.namenode.rpc-address.mycluster.nn2</name>
        <value>namenode02-test.zerofinance.net:8020</value>
    </property>

    <property>
        <name>dfs.client.failover.proxy.provider.mycluster</name>
        <value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
    </property>

</configuration>
```



## Hive

The Apache Hive ™ is a distributed, fault-tolerant data warehouse system that enables analytics at a massive scale and facilitates reading, writing, and managing petabytes of data residing in distributed storage using SQL.

[GettingStarted](https://cwiki.apache.org/confluence/display/Hive/GettingStarted)

### internal table

If table has beed deleted, all data will be delete accordingly, including meta data and file data.

```
#https://cwiki.apache.org/confluence/display/Hive/LanguageManual+DML
#LOAD DATA [LOCAL] INPATH 'filepath' [OVERWRITE] INTO TABLE tablename [PARTITION (partcol1=val1, partcol2=val2 ...)]
#filepath can be:
#a relative path, such as project/data1
#an absolute path, such as /user/hive/project/data1
#a full URI with scheme and (optionally) an authority, such as hdfs://namenode:9000/user/hive/project/data1
The keyword 'OVERWRITE' signifies that existing data in the table is deleted. If the 'OVERWRITE' keyword is omitted, data files are appended to existing data sets.

#default as internal table: 
CREATE TABLE pokes (foo INT, bar STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' STORED AS TEXTFILE;

sudo -u hive hadoop fs -put -f /tmp/kv1.txt /user/hive/demo/
LOAD DATA INPATH './demo/kv1.txt' OVERWRITE INTO TABLE pokes;
#When it's done, the file located in hdfs will be deleted.
select * from pokes;

```

### external table

If table has beed deleted, just meta data will be deleted. once you create table again, the data will be restored, no need load again.

```
#sudo -u hdfs hadoop fs -chown -R hive:hive /works/test/
#sudo -u hive hadoop fs -cp  /user/hive/demo/kv1.txt /works/test/
sudo -u hive hadoop fs -put -f /tmp/kv1.txt /works/demo/
create external table mytest ( id int, myfields string ) ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' STORED AS TEXTFILE location '/works/test/';
LOAD DATA INPATH '/works/demo/kv1.txt' OVERWRITE INTO TABLE mytest;
describe formatted mytest;
```

### Partition

```
CREATE TABLE invites (foo INT, bar STRING) PARTITIONED BY (ds STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' STORED AS TEXTFILE;
#sudo -u hive hadoop fs -put -f /tmp/kv1.txt /user/hive/demo/
LOAD DATA INPATH './demo/kv1.txt' OVERWRITE INTO TABLE invites PARTITION (ds='2008-08-15');
select * from invites;
SELECT a.foo FROM invites a WHERE a.ds='2008-08-15';
```

### Insert Directory

```
#selects all rows from partition ds=2008-08-15 of the invites table into an HDFS directory. The result data is in files (depending on the number of mappers) in that directory.
NOTE: partition columns if any are selected by the use of *. They can also be specified in the projection clauses.

INSERT OVERWRITE DIRECTORY '/tmp/hdfs_out' SELECT a.* FROM invites a WHERE a.ds='2008-08-15';
#local dirctory located on the same node of hiveserver2.
INSERT OVERWRITE LOCAL DIRECTORY '/tmp/local_out' SELECT a.* FROM pokes a;
```

### Insert Table

```
CREATE TABLE events (foo INT, bar STRING) ROW FORMAT DELIMITED FIELDS TERMINATED BY ' ' STORED AS TEXTFILE;
INSERT OVERWRITE TABLE events SELECT a.* FROM pokes a;
FROM invites a INSERT OVERWRITE TABLE events SELECT a.bar, count(*) WHERE a.foo > 0 GROUP BY a.bar;
INSERT OVERWRITE TABLE events SELECT a.bar, count(*) FROM invites a WHERE a.foo > 0 GROUP BY a.bar;
```



### Date Type

[Hive 数据类型 | Hive 教程 (hadoopdoc.com)](https://hadoopdoc.com/hive/hive-data-type)

A complex demo for data type.

```sql
CREATE TABLE students(
 name     STRING,   -- 姓名
 age       INT,      -- 年龄
 subject   ARRAY<STRING>,   --学科
 score     MAP<STRING,FLOAT>,  --各个学科考试成绩
 address   STRUCT<houseNumber:int, street:STRING, city:STRING, province:STRING>  --家庭居住地址
) ROW FORMAT DELIMITED FIELDS TERMINATED BY "\t" 
STORED AS TEXTFILE;
```



#### STRUCT

```
CREATE TABLE IF NOT EXISTS person_1 (id int,info struct<name:string,country:string>)  
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
COLLECTION ITEMS TERMINATED BY ':' 
STORED AS TEXTFILE;

//创建一个文本文件test_struct.txt
1,'dd':'jp'
2,'ee':'cn'
3,'gg':'jp'
4,'ff':'cn'
5,'tt':'jp'

sudo -u hive hadoop fs -put /works/test/test_struct.txt /user/hive/demo/
LOAD DATA INPATH './demo/test_struct.txt' OVERWRITE INTO TABLE person_1;

select * from person_1;
+--------------+-----------------------------------+
| person_1.id  |           person_1.info           |
+--------------+-----------------------------------+
| 1            | {"name":"'dd'","country":"'jp'"}  |
| 2            | {"name":"'ee'","country":"'cn'"}  |
| 3            | {"name":"'gg'","country":"'jp'"}  |
| 4            | {"name":"'ff'","country":"'cn'"}  |
| 5            | {"name":"'tt'","country":"'jp'"}  |
+--------------+------------------------

select id,info.name,info.country from person_1 where info.name='\'dd\'';
+-----+-------+----------+
| id  | name  | country  |
+-----+-------+----------+
| 1   | 'dd'  | 'jp'     |
+-----+-------+----------+
1 row selected (0.316 seconds)
```

#### ARRAY

```
CREATE TABLE IF NOT EXISTS array_1 (id int,name array<STRING>)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
COLLECTION ITEMS TERMINATED BY ':' 
STORED AS TEXTFILE;
//导入数据
sudo -u hive hadoop fs -put /works/test/test_struct.txt /user/hive/demo/test_array.txt
LOAD DATA INPATH './demo/test_array.txt' OVERWRITE INTO TABLE array_1;
//查询数据
hive> select * from array_1;
OK
1   ["dd","jp"]
2   ["ee","cn"]
3   ["gg","jp"]
4   ["ff","cn"]
5   ["tt","jp"]
Time taken: 0.041 seconds, Fetched: 5 row(s)
hive> select id,name[0],name[1] from array_1 where name[1]='\'cn\'';
+-----+-------+-------+
| id  |  _c1  |  _c2  |
+-----+-------+-------+
| 2   | 'ee'  | 'cn'  |
| 4   | 'ff'  | 'cn'  |
+-----+-------+-------+
2 rows selected (0.317 seconds)
```

#### MAP

```
CREATE TABLE IF NOT EXISTS map_1 (id int,name map<STRING,STRING>)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '|' 
COLLECTION ITEMS TERMINATED BY ',' 
MAP KEYS TERMINATED BY ':'
STORED AS TEXTFILE;

cat test_map.txt    
1|'name':'jp','country':'cn'
2|'name':'jp','country':'cn'

sudo -u hive hadoop fs -put /works/test/test_map.txt /user/hive/demo/test_map.txt
//加载数据
LOAD DATA INPATH './demo/test_map.txt' OVERWRITE INTO TABLE map_1;

//查询数据
hive> select * from map_1;
+-----------+---------------------------------------+
| map_1.id  |              map_1.name               |
+-----------+---------------------------------------+
| 1         | {"'name'":"'jp'","'country'":"'cn'"}  |
| 2         | {"'name'":"'jp'","'country'":"'cn'"}  |
+-----------+-----------------------------------
hive> select id,name["'name'"],name["'country'"] from map_1;
+-----+-------+-------+
| id  |  _c1  |  _c2  |
+-----+-------+-------+
| 1   | 'jp'  | 'cn'  |
| 2   | 'jp'  | 'cn'  |
+-----+-------+-------+
hive> select * from map_1 where name["'country'"]='\'cn\'';
+-----------+---------------------------------------+
| map_1.id  |              map_1.name               |
+-----------+---------------------------------------+
| 1         | {"'name'":"'jp'","'country'":"'cn'"}  |
| 2         | {"'name'":"'jp'","'country'":"'cn'"}  |
+-----------+---------------------------------------+
2 rows selected (0.287 seconds)

hive> insert into map_1(id,name)values(1, str_to_map("name:jp1,country:cn1")),(2, str_to_map("name:jp2,country:cn2"));
No rows affected (11.664 seconds)
hive> select * from map_1;
+-----------+---------------------------------------+
| map_1.id  |              map_1.name               |
+-----------+---------------------------------------+
| 1         | {"name":"jp1","country":"cn1"}        |
| 2         | {"name":"jp2","country":"cn2"}        |
+-----------+---------------------------------------+
4 rows selected (0.482 seconds)
```

UINON

```
//创建DUAL表，插入一条记录，用于生成数据
create table dual(d string);
insert into dual values('X');
//创建UNION表
CREATE TABLE IF NOT EXISTS uniontype_1 
(
id int,
info map<STRING,array<int>>
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ',' 
COLLECTION ITEMS TERMINATED BY '-'
MAP KEYS TERMINATED BY ':'
STORED AS TEXTFILE;

//Insert
insert overwrite table uniontype_1
select 1 as id,map('english',array(99,21,33)) as info from dual
union all
select 2 as id,map('english',array(44,33,76)) as info from dual
union all
select 3 as id,map('english',array(76,88,66)) as info from dual;

select * from uniontype_1;
+-----------------+-------------------------+
| uniontype_1.id  |    uniontype_1.info     |
+-----------------+-------------------------+
| 1               | {"english":[99,21,33]}  |
| 2               | {"english":[44,33,76]}  |
| 3               | {"english":[76,88,66]}  |
+-----------------+-------------------------+
3 rows selected (0.432 seconds)

select * from uniontype_1 where info['english'][2]>30;
+-----------------+-------------------------+
| uniontype_1.id  |    uniontype_1.info     |
+-----------------+-------------------------+
| 1               | {"english":[99,21,33]}  |
| 2               | {"english":[44,33,76]}  |
| 3               | {"english":[76,88,66]}  |
+-----------------+-------------------------+
```

## Seatunnel

```bash
cat /etc/profile.d/hadoop.sh    
export HADOOP_HOME=/usr/bigtop/current/hadoop-client
export HADOOP_CONF_DIR=/usr/bigtop/current/hadoop-client/etc/hadoop/
export SPARK_HOME=/usr/bigtop/current/spark-client
export PYTHON_HOME=/usr
export HIVE_HOME=/usr/bigtop/current/hive-client
export FLINK_HOME=/usr/bigtop/current/flink-client
export SEATUNNEL_HOME=/works/app/apache-seatunnel-2.3.3
export ZOOKEEPER_HOME=/usr/bigtop/current/zookeeper-client
export PATH=$HADOOP_HOME/bin:$SPARK_HOME/bin:$HIVE_HOME/bin:$FLINK_HOME/bin:$SEATUNNEL_HOME/bin:$ZOOKEEPER_HOME/bin:$PATH
```

## Flink

[BigData-Notes/notes/Flink核心概念综述.md at master · heibaiying/BigData-Notes (github.com)](https://github.com/heibaiying/BigData-Notes/blob/master/notes/Flink核心概念综述.md)

### Deployment Modes

See this Overview to understand: [deployment-modes](https://nightlies.apache.org/flink/flink-docs-release-1.15/docs/deployment/overview/#deployment-modes)

#### Standalone

https://nightlies.apache.org/flink/flink-docs-release-1.15/docs/deployment/resource-providers/standalone/overview/

##### Session Mode

```
# we assume to be in the root directory of the unzipped Flink distribution

# (1) Start Cluster
$ ./bin/start-cluster.sh

# (2) You can now access the Flink Web Interface on http://localhost:8081

# (3) Submit example job
$ ./bin/flink run ./examples/streaming/TopSpeedWindowing.jar

# (4) Stop the cluster again
$ ./bin/stop-cluster.sh
```

In step `(1)`, we’ve started 2 processes: A JVM for the JobManager, and a JVM for the TaskManager. The JobManager is serving the web interface accessible at [localhost:8081](http://localhost:8081/). In step `(3)`, we are starting a Flink Client (a short-lived JVM process) that submits an application to the JobManager.

```
#Troubleshooting: 8081 can be visited only for localhost
cat /etc/hosts
192.168.80.225   localhost
```

##### Application Mode

```bash
To start a Flink JobManager with an embedded application, we use the bin/standalone-job.sh script. We demonstrate this mode by locally starting the TopSpeedWindowing.jar example, running on a single TaskManager.

The application jar file needs to be available in the classpath. The easiest approach to achieve that is putting the jar into the lib/ folder:

$ cp ./examples/streaming/TopSpeedWindowing.jar lib/
Then, we can launch the JobManager:

$ ./bin/standalone-job.sh start --job-classname org.apache.flink.streaming.examples.windowing.TopSpeedWindowing
The web interface is now available at localhost:8081. However, the application won’t be able to start, because there are no TaskManagers running yet:

$ ./bin/taskmanager.sh start
Note: You can start multiple TaskManagers, if your application needs more resources.

Stopping the services is also supported via the scripts. Call them multiple times if you want to stop multiple instances, or use stop-all:

$ ./bin/taskmanager.sh stop
$ ./bin/standalone-job.sh stop
```

#### YARN

https://nightlies.apache.org/flink/flink-docs-release-1.15/docs/deployment/resource-providers/yarn/

##### Session Mode

[starting-a-flink-session-on-yarn](https://nightlies.apache.org/flink/flink-docs-release-1.15/docs/deployment/resource-providers/yarn/#starting-a-flink-session-on-yarn)

```bash
export HADOOP_CLASSPATH=`hadoop classpath`
# we assume to be in the root directory of 
# the unzipped Flink distribution

# (0) export HADOOP_CLASSPATH
export HADOOP_CLASSPATH=`hadoop classpath`

# (1) Start YARN Session
./bin/yarn-session.sh --detached

# (2) You can now access the Flink Web Interface through the
# URL printed in the last lines of the command output, or through
# the YARN ResourceManager web UI.

# (3) Submit example job
./bin/flink run ./examples/streaming/TopSpeedWindowing.jar

# (4) Stop YARN session (replace the application id based 
# on the output of the yarn-session.sh command)
echo "stop" | ./bin/yarn-session.sh -id application_XXXXX_XXX
```

Congratulations! You have successfully run a Flink application by deploying Flink on YARN.

We describe deployment with the Session Mode in the [Getting Started](https://nightlies.apache.org/flink/flink-docs-release-1.15/docs/deployment/resource-providers/yarn/#getting-started) guide at the top of the page.

The Session Mode has two operation modes:

- **attached mode** (default): The `yarn-session.sh` client submits the Flink cluster to YARN, but the client keeps running, tracking the state of the cluster. If the cluster fails, the client will show the error. If the client gets terminated, it will signal the cluster to shut down as well.
- **detached mode** (`-d` or `--detached`): The `yarn-session.sh` client submits the Flink cluster to YARN, then the client returns. Another invocation of the client, or YARN tools is needed to stop the Flink cluster.

The session mode will create a hidden YARN properties file in `/tmp/.yarn-properties-<username>`, which will be picked up for cluster discovery by the command line interface when submitting a job.

You can also **manually specify the target YARN cluster** in the command line interface when submitting a Flink job. Here’s an example:

```bash
./bin/flink run -t yarn-session \
  -Dyarn.application.id=application_XXXX_YY \
  ./examples/streaming/TopSpeedWindowing.jar
```

You can **re-attach to a YARN session** using the following command:

```
./bin/yarn-session.sh -id application_XXXX_YY
```

Besides passing [configuration](https://nightlies.apache.org/flink/flink-docs-release-1.15/docs/deployment/config/) via the `conf/flink-conf.yaml` file, you can also pass any configuration at submission time to the `./bin/yarn-session.sh` client using `-Dkey=value` arguments.

The YARN session client also has a few “shortcut arguments” for commonly used settings. They can be listed with `./bin/yarn-session.sh -h`.

##### Application Mode

```bash
Application Mode will launch a Flink cluster on YARN, where the main() method of the application jar gets executed on the JobManager in YARN. The cluster will shut down as soon as the application has finished. You can manually stop the cluster using yarn application -kill <ApplicationId> or by cancelling the Flink job.

./bin/flink run-application -t yarn-application ./examples/streaming/TopSpeedWindowing.jar

Once an Application Mode cluster is deployed, you can interact with it for operations like cancelling or taking a savepoint.

# List running job on the cluster
./bin/flink list -t yarn-application -Dyarn.application.id=application_XXXX_YY

# Cancel running job
./bin/flink cancel -t yarn-application -Dyarn.application.id=application_XXXX_YY <jobId>

Note that cancelling your job on an Application Cluster will stop the cluster.

To unlock the full potential of the application mode, consider using it with the yarn.provided.lib.dirs configuration option and pre-upload your application jar to a location accessible by all nodes in your cluster. In this case, the command could look like:

./bin/flink run-application -t yarn-application \
	-Dyarn.provided.lib.dirs="hdfs://myhdfs/my-remote-flink-dist-dir" \
	hdfs://myhdfs/jars/my-application.jar
	
The above will allow the job submission to be extra lightweight as the needed Flink jars and the application jar are going to be picked up by the specified remote locations rather than be shipped to the cluster by the client.
```

#### Sql Client

[Flink 使用之 SQL Client - 简书 (jianshu.com)](https://www.jianshu.com/p/266449b9a0f4)

##### Standalone

```
start-cluster.sh

sql-client.sh embedded
```



##### On yarn Session

[SQL-Client On Yarn Session](https://blog.csdn.net/lsr40/article/details/113398830)

[Configuring SQL Client for session mode | CDP Private Cloud (cloudera.com)](https://docs.cloudera.com/csa/1.2.0/sql-client/topics/csa-sql-client-session-config.html)

```sql
#Start a yarn session
#提交yarn session和启动sql client需要使用同一个用户，否则会找不到yarn session对应的application id。
sudo su - hadoop
#yarn-session.sh -d
yarn-session.sh -jm 2048MB -tm 2048MB -nm flink-sql-test -d

cat /works/demo.csv 
1,a,11
2,b,22
3,c,33
4,d,44

sudo -u hdfs hadoop fs -put /works/demo.csv /works/test/demo.csv

sql-client.sh embedded -s yarn-session

# 在专门的界面展示，使用分页table格式。可按照界面下方说明，使用快捷键前后翻页和退出到SQL命令行
SET sql-client.execution.result-mode = table;

# changelog格式展示，可展示数据增(I)删(D)改(U)
SET sql-client.execution.result-mode = changelog;

# 接近传统数据库的展示方式，不使用专门界面
SET sql-client.execution.result-mode = tableau;

Flink SQL> CREATE TABLE MyTable(
  a INT,
  b STRING,
  c STRING
) WITH (
  'connector' = 'filesystem',
  'path' = 'hdfs:///works/test/demo.csv',
  'format' = 'csv'
);

Flink SQL> select * from MyTable;

#Kill an existing yarn-session
yarn application -list
echo "stop" | yarn-session.sh -id <application_id>

#kafka Connector:
wget https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/1.15.3/flink-sql-connector-kafka-1.15.3.jar
wget https://repo1.maven.org/maven2/org/apache/flink/flink-connector-jdbc/1.15.3/flink-connector-jdbc-1.15.3.jar
scp flink-sql-connector-kafka-1.15.3.jar flink-connector-jdbc-1.15.3.jar mysql-connector-j-8.0.31.jar root@192.168.80.226:/usr/bigtop/current/flink-client/lib/
scp flink-sql-connector-kafka-1.15.3.jar flink-connector-jdbc-1.15.3.jar mysql-connector-j-8.0.31.jar root@192.168.80.227:/usr/bigtop/current/flink-client/lib/
scp flink-sql-connector-kafka-1.15.3.jar flink-connector-jdbc-1.15.3.jar mysql-connector-j-8.0.31.jar root@192.168.80.228:/usr/bigtop/current/flink-client/lib/
scp flink-sql-connector-kafka-1.15.3.jar flink-connector-jdbc-1.15.3.jar mysql-connector-j-8.0.31.jar root@192.168.80.229:/usr/bigtop/current/flink-client/lib/

Hive Connector:
wget https://repo1.maven.org/maven2/org/antlr/antlr-runtime/3.5.2/antlr-runtime-3.5.2.jar
wget https://repo1.maven.org/maven2/org/apache/flink/flink-connector-hive_2.12/1.15.3/flink-connector-hive_2.12-1.15.3.jar
wget https://repo1.maven.org/maven2/org/apache/hive/hive-exec/2.3.4/hive-exec-2.3.4.jar
scp antlr-runtime-3.5.2.jar flink-connector-hive_2.12-1.15.3.jar hive-exec-2.3.4.jar root@192.168.80.226:/usr/bigtop/current/flink-client/lib/
scp antlr-runtime-3.5.2.jar flink-connector-hive_2.12-1.15.3.jar hive-exec-2.3.4.jar root@192.168.80.227:/usr/bigtop/current/flink-client/lib/
scp antlr-runtime-3.5.2.jar flink-connector-hive_2.12-1.15.3.jar hive-exec-2.3.4.jar root@192.168.80.228:/usr/bigtop/current/flink-client/lib/
scp antlr-runtime-3.5.2.jar flink-connector-hive_2.12-1.15.3.jar hive-exec-2.3.4.jar root@192.168.80.229:/usr/bigtop/current/flink-client/lib/

scp /usr/bigtop/current/flink-client/conf/flink-conf.yaml root@192.168.80.226:/usr/bigtop/current/flink-client/conf/
scp /usr/bigtop/current/flink-client/conf/flink-conf.yaml root@192.168.80.227:/usr/bigtop/current/flink-client/conf/
scp /usr/bigtop/current/flink-client/conf/flink-conf.yaml root@192.168.80.228:/usr/bigtop/current/flink-client/conf/
scp /usr/bigtop/current/flink-client/conf/flink-conf.yaml root@192.168.80.229:/usr/bigtop/current/flink-client/conf/


#java.lang.ClassNotFoundException: org.apache.flink.connector.jdbc.table.JdbcRowDataInputFormat
#Has to reboot flink-cluster
stop-cluster.sh
start-cluster.sh
```

##### Connectors

```sql
#https://www.jianshu.com/p/266449b9a0f4
#Create table in mysql
create database demo_db character set utf8mb4;
use demo_db;
create table fludesc (
    id varchar(32),
    use_rname varchar(32),
    age int,
    gender varchar(32),
    goods_no varchar(32),
    goods_price Float,
    store_id int,
    shopping_type varchar(32),
    tel varchar(32),
    email varchar(32),
    shopping_date date
);

#Create in flinksql
Flink SQL> create table kafka_source (
    id STRING,
    use_rname STRING,
    age integer,
    gender STRING,
    goods_no STRING,
    goods_price Float,
    store_id integer,
    shopping_type STRING,
    tel STRING,
    email STRING,
    shopping_date Date
) with (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'datanode01-test.zerofinance.net:9092,datanode01-test.zerofinance.net:9092,datanode01-test.zerofinance.net:9092',
    'topic' = 'fludesc',
    'properties.group.id' = 'testGroup',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'csv',
    'csv.ignore-parse-errors' = 'true'
);

Flink SQL> CREATE TABLE mysql_sink (
    id STRING,
    use_rname STRING,
    age integer,
    gender STRING,
    goods_no STRING,
    goods_price Float,
    store_id integer,
    shopping_type STRING,
    tel STRING,
    email STRING,
    shopping_date Date
) WITH (
   'connector' = 'jdbc',
   'url' = 'jdbc:mysql://192.168.80.225:3306/demo_db',
   'table-name' = 'fludesc',
   'username' = 'root',
   'password' = 'Aa123#@!'
);

Flink SQL> insert into mysql_sink select * from kafka_source;

#Mock data from kafka:
kafka-console-producer.sh --broker-list datanode01-test.zerofinance.net:9092,datanode01-test.zerofinance.net:9092,datanode01-test.zerofinance.net:9092 --topic fludesc
>511653962048,Zomfq,53,woman,532120,534.61,313020,cart,15926130785,UyxghCpKMD@huawei.com,2019-08-03
>751653962048,Qvtil,27,man,532120,655.7,313023,cart,13257423096,cJfbNhRYow@163.com,2019-08-05
>121653962048,Spdwh,35,woman,480071,97.35,313018,cart,18825789463,LkVYmpcWXC@qq.com,2019-08-05
>871653962048,Fdhpc,18,man,650012,439.40,313012,cart,15059872140,sfzuPWvNEe@qq.com,2019-08-06
>841653962048,Iqoyh,51,woman,152121,705.6,313012,buy,13646513897,jISbcYdxZO@126.com,2019-08-04
>761653962048,Xgzhy,29,woman,480071,329.60,313013,cart,15069315824,NtTDRlAdeZ@qq.com,2019-08-04

#kafka-console-consumer.sh --topic fludesc --bootstrap-server datanode01-test.zerofinance.net:9092,datanode01-test.zerofinance.net:9092,datanode01-test.zerofinance.net:9092 --from-beginning
```

##### Hive Catalog

```sql
#https://nightlies.apache.org/flink/flink-docs-release-1.15/zh/docs/connectors/table/hive/hive_catalog/
CREATE CATALOG myhive WITH (
  'type' = 'hive',
  'hive-conf-dir' = '/usr/bigtop/current/hive-client/conf'
);
show catalogs;
use catalog myhive;
show databases;

create table mykafka (
    id STRING,
    use_rname STRING,
    age integer,
    gender STRING,
    goods_no STRING,
    goods_price Float,
    store_id integer,
    shopping_type STRING,
    tel STRING,
    email STRING,
    shopping_date Date
) with (
    'connector' = 'kafka',
    'properties.bootstrap.servers' = 'datanode01-test.zerofinance.net:9092,datanode01-test.zerofinance.net:9092,datanode01-test.zerofinance.net:9092',
    'topic' = 'fludesc',
    'scan.startup.mode' = 'earliest-offset',
    'format' = 'csv',
    'csv.ignore-parse-errors' = 'true'
);

DESCRIBE mykafka;

select * from mykafka;
```

### High-Availability

Recommend working on Yarn

[High-Availability on YARN](https://nightlies.apache.org/flink/flink-docs-release-1.15/docs/deployment/resource-providers/yarn/#high-availability-on-yarn)

High-Availability on YARN is achieved through a combination of YARN and a [high availability service](https://nightlies.apache.org/flink/flink-docs-release-1.15/docs/deployment/ha/overview/).

Once a HA service is configured, it will persist JobManager metadata and perform leader elections.

YARN is taking care of restarting failed JobManagers. The maximum number of JobManager restarts is defined through two configuration parameters. First Flink’s [yarn.application-attempts](https://nightlies.apache.org/flink/flink-docs-release-1.15/docs/deployment/config/#yarn-application-attempts) configuration will default 2. This value is limited by YARN’s [yarn.resourcemanager.am.max-attempts](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-common/yarn-default.xml), which also defaults to 2.

Note that Flink is managing the `high-availability.cluster-id` configuration parameter when deploying on YARN. Flink sets it per default to the YARN application id. **You should not overwrite this parameter when deploying an HA cluster on YARN**. The cluster ID is used to distinguish multiple HA clusters in the HA backend (for example Zookeeper). Overwriting this configuration parameter can lead to multiple YARN clusters affecting each other.

[ZooKeeper HA Services](https://nightlies.apache.org/flink/flink-docs-release-1.15/docs/deployment/ha/zookeeper_ha/)

Configure high availability mode and ZooKeeper quorum in `conf/flink-conf.yaml`:

```
high-availability: zookeeper
high-availability.zookeeper.quorum: datanode03-test.zerofinance.net:2181,datanode01-test.zerofinance.net:2181,datanode02-test.zerofinance.net:2181
high-availability.zookeeper.path.root: /flink
high-availability.storageDir: hdfs:///flink/ha/
```

### Histroy Server

[History Server | Apache Flink](https://nightlies.apache.org/flink/flink-docs-release-1.15/docs/deployment/advanced/historyserver/)

Flink has a history server that can be used to query the statistics of completed jobs after the corresponding Flink cluster has been shut down.

By default, this server binds to `localhost` and listens at port `8082`.

