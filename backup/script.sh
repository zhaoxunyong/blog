#!/bin/bash

#http://www.360doc.com/content/14/1125/19/7044580_428024359.shtml
#http://blog.csdn.net/54powerman/article/details/50684844
#http://c.biancheng.net/cpp/view/2739.html
echo "scripting......"

filepath=/vagrant
bip=$1
hostname=$2

if [[ "$hostname" != "" ]]; then
  hostnamectl --static set-hostname $hostname
  sysctl kernel.hostname=$hostname
fi

#关闭内核安全(如果是vagrant方式，第一次完成后需要重启vagrant才能生效。)
sed -i 's;SELINUX=.*;SELINUX=disabled;' /etc/selinux/config
setenforce 0
getenforce

cat /etc/NetworkManager/NetworkManager.conf|grep "dns=none" > /dev/null
if [[ $? != 0 ]]; then
  echo "dns=none" >> /etc/NetworkManager/NetworkManager.conf
  systemctl restart NetworkManager.service
fi

systemctl disable iptables
systemctl stop iptables
systemctl disable firewalld
systemctl stop firewalld

ln -sf /usr/share/zoneinfo/Asia/Chongqing /etc/localtime

#logined limit
cat /etc/security/limits.conf|grep 100000 > /dev/null
if [[ $? != 0 ]]; then
cat >> /etc/security/limits.conf  << EOF
*               soft    nofile             100000
*               hard    nofile             100000
*               soft    nproc              100000
*               hard    nproc              100000
EOF
fi

sed -i 's;4096;100000;g' /etc/security/limits.d/20-nproc.conf

#systemd service limit
cat /etc/systemd/system.conf|egrep '^DefaultLimitCORE' > /dev/null
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
EOF
sysctl -p
fi

su - root -c "ulimit -a"

#echo '192.168.10.6 k8s-master
#192.168.10.7   k8s-node1
#192.168.10.8   k8s-node2' >> /etc/hosts

##sed -i 's;en_GB;zh_CN;' /etc/sysconfig/i18n

yum -y install gcc kernel-devel
mv -f /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
#wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo

yum -y install epel-release

yum clean all
yum makecache

#yum -y install createrepo rpm-sign rng-tools yum-utils 
yum -y install bind-utils bridge-utils ntpdate setuptool iptables system-config-securitylevel-tui system-config-network-tui \
ntsysv net-tools lrzsz bridge-utils \
htop telnet lsof vim dos2unix unix2dos zip unzip lsof
yum install psmisc -y
sudo systemctl enable ssh

# mkdir -p /works/soft
# cd /works/soft
# cp -a /vagrant/soft /works/
# tar zxvf jdk-8u241-linux-x64.tar.gz 
# cat > /etc/profile.d/java.sh << EOF
# export JAVA_HOME=/works/soft/jdk1.8.0_241
# export PATH=\$JAVA_HOME/bin:\$PATH
# EOF

# . /etc/profile

useradd hadoop
passwd hadoop
chmod +w /etc/sudoers

vim /etc/sudoers
#在 sudoers 文件中添加以下内容
echo "hadoop ALL=(root)NOPASSWD: ALL" >> /etc/sudoers
#最后保存内容后退出,并取消 sudoers 文件的写权限
chmod -w /etc/sudoers

cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.80.190 nna
192.168.80.191 nns
192.168.80.192 dn1
192.168.80.193 dn2
192.168.80.194 dn3
EOF


su - hadoop
ssh-keygen -t rsa
#只在nna
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
将其他机器中的~/.ssh/id_rsa.pub内容追加到~/.ssh/authorized_keys中
scp ~/.ssh/authorized_keys hadoop@nns:~/.ssh
scp ~/.ssh/authorized_keys hadoop@ds1:~/.ssh
scp ~/.ssh/authorized_keys hadoop@ds2:~/.ssh
scp ~/.ssh/authorized_keys hadoop@ds3:~/.ssh

#所有
su - hadoop
sudo chown hadoop -R /works

#zookeeper, just only on dn1/dn2/dn3
mkdir -p /works/zkdata
#cp -a zookeeper-3.4.6/conf/zoo_sample.cfg zookeeper-3.4.6/conf/zoo.cfg
#vim zookeeper-3.4.6/conf/zoo.cfg
cat > zookeeper-3.4.6/conf/zoo.cfg << EOF
# The number of milliseconds of each tick
tickTime=2000
# The number of ticks that the initial 
# synchronization phase can take
initLimit=10
# The number of ticks that can pass between 
# sending a request and getting an acknowledgement
syncLimit=5
# the directory where the snapshot is stored.
# do not use /tmp for storage, /tmp here is just 
# example sakes.
dataDir=/works/zkdata
# the port at which the clients will connect
clientPort=2181
# the maximum number of client connections.
# increase this if you need to handle more clients
#maxClientCnxns=60
#Each of nodes
server.1=dn1:2888:3888
server.2=dn2:2888:3888
server.3=dn3:2888:3888
EOF

#dn1
echo 1 > /works/zkdata/myid
#dn2
echo 2 > /works/zkdata/myid
#dn3
echo 3 > /works/zkdata/myid

#sudo vim /etc/profile
su -
cat > /etc/profile.d/zookeeper.sh << EOF
export ZK_HOME=/works/soft/zookeeper-3.4.6
export PATH=\$PATH:\$ZK_HOME/bin
EOF

exit
. /etc/profile

cd $ZK_HOME/bin/
zkServer.sh start
zkServer.sh status
#Having some of errors, reexcute:
zkServer.sh start-foreground
jps -lmv

#Working on nna
su - hadoop
cd /works/soft
tar zxvf hadoop-2.7.7.tar.gz

cd /works/soft/hadoop-2.7.7/etc/hadoop

core-site.xml
hdfs-site.xml
mapred-site.xml
yarn-site.xml
fair-scheduler.xml

echo "export HADOOP_HOME=/works/soft/hadoop-2.7.7" >> hadoop-env.sh
echo "export HADOOP_HOME=/works/soft/hadoop-2.7.7" >> yarn-env.sh
#修 改 slaves 文件 ( 存放 Data Node 节点的文件 )
cat > /works/soft/hadoop-2.7.7/etc/hadoop/slaves << EOF
dn1
dn2
dn3
EOF

scp -r /works/soft/hadoop-2.7.7 hadoop@nns:/works/soft/
scp -r /works/soft/hadoop-2.7.7 hadoop@dn1:/works/soft/
scp -r /works/soft/hadoop-2.7.7 hadoop@dn2:/works/soft/
scp -r /works/soft/hadoop-2.7.7 hadoop@dn3:/works/soft/

#Working on all nodes
su -
cat > /etc/profile.d/hadoop.sh << EOF
export HADOOP_HOME=/works/soft/hadoop-2.7.7
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
EOF
exit
. /etc/profile
echo $HADOOP_HOME

#Working on nns
cd /works/soft/hadoop-2.7.7/etc/hadoop/
vim yarn-site.xml
  <property>
    <name>yarn.resourcemanager.ha.id</name>
    <value>rm2</value>
  </property>

#Working on all of nodes
mkdir -p /works/hadoop/tmp
mkdir -p /works/hadoop/tmp/journal
mkdir -p /works/hadoop/tmp/journal
mkdir -p /works/hadoop/dfs/name
mkdir -p /works/hadoop/dfs/data
mkdir -p /works/hadoop/yarn/local
mkdir -p /works/hadoop/log/yarn
mkdir -p  /works/soft/hadoop-2.7.7/logs

cd /works/soft/hadoop-2.7.7/sbin
#在任意一台 Name Node 节点上启动 JournalNode 进程
#Working on nna
hadoop-daemons.sh start journalnode
#on dn1/dn2/dn3 jps: you will see JournalNode process
#在初次启动 Hadoop 集群时,需要格式化 NameNode 节点,具体操作命令如下 :
#格式化 NameNode 节点
hdfs namenode -format
#向 Zoo keeper 注册
hdfs zkfc -formatZK

#启动分布式文件系统( HDFS)
start-dfs.sh
#启动 YARN 服务进程
start-yarn.sh


在当前节点的终端上输入 jps 命 令查看相关的服务进程,其 中包含 
DFSZKFailoverController 、 NameNode 和 ResomceManager 服务进程。

#同步 nna 节点元数据信息到 nns 节点
hdfs namenode -bootstrapStandby

#Working on nns
切换到 nns 节 点上并输入 j ps 命令查看相关的启动进程。如果发现只有 DFSZK
ailoverontroller 服务进程,可以手动启动 nns 节点上的 NameNode 和 ResourceManager 服务
进程, 具 体操作命令如下:
#启动 NameNode 进程
cd /works/soft/hadoop-2.7.7/sbin
hadoop-daemon.sh start namenode -bootstrapStandby
#启动 ResourceManager 进程
yarn-daemon.sh start resourcemanager -bootstrapStandby

#Working on nna
yarn-daemon.sh start proxyserver
mr-jobhistory-daemon.sh start historyserver

# Hadoop 访问地址
http://nna:50070/
#YARN (资源管理调度)访问地址
http://nna:8188/

https://www.jianshu.com/p/c44495a10043
找到hadoop安装目录下 hadoop-2.4.1/data/dfs/data里面的current文件夹删除
然后从新执行一下 hadoop namenode -format
再使用start-dfs.sh和start-yarn.sh 重启一下hadoop
用jps命令看一下就可以看见datanode已经启动了
rm -fr /works/hadoop/dfs/data/current
stop-all.sh
hadoop-daemons.sh start journalnode
#格式化 NameNode 节点
hdfs namenode -format
#向 Zoo keeper 注册
hdfs zkfc -formatZK
start-dfs.sh
start-yarn.sh
yarn-daemon.sh start proxyserver
mr-jobhistory-daemon.sh start historyserver


hadoop namenode -format
echo "xxx" > hello.txt
#上传本地文件到分布式文件系统中的 tmp 目录
hdfs dfs -mkdir /works/
hdfs dfs -ls /works/
hdfs dfs -put hello.txt /works/abc.txt
#下载分布式文件系统中 tmp 目录下的 hello.txt 文件本地当前目录
hdfs dfs -get /works/abc.txt ./
#删除分布式文件系统中 tmp 目录下的 hello.txt 文f~:
hdfs dfs -rm -r /works/abc.txt


#手动切换服务状态
nna>
hdfs haadmin -failover --forcefence --forceactive nna nns
hdfs haadmin -getServiceState nns

-----------------------------------------
#Starting all of the servers
#Working on all
sudo route del default gw 10.0.2.2

#Working on dn1/dn2/dn3
su - hadoop
zkServer.sh start

#Working on nna
#hadoop-daemons.sh start journalnode
start-dfs.sh
start-yarn.sh
#https://www.cnblogs.com/honeybee/p/8276984.html
# hadoop-daemon.sh start namenode
# yarn-daemon.sh start resourcemanager
#https://www.hemingliang.site/169.html
hadoop namenode -recover
yarn-daemon.sh start proxyserver
mr-jobhistory-daemon.sh start historyserver

#dn1/dn2/dn3
1440 QuorumPeerMain
1766 NodeManager
1528 JournalNode
1612 DataNode
#nns
1905 ResourceManager
1794 DFSZKFailoverController
1683 NameNode
#nna
1907 NameNode
2348 ResourceManager
2221 DFSZKFailoverController
2672 WebAppProxyServer
2740 JobHistoryServer
lsof -i:50070
lsof -i:8188

hdfs haadmin -getServiceState nna
hdfs haadmin -getServiceState nns

EditLogInputException: Error replaying edit log at offset 0.  Expected transaction ID was 45:
hadoop namenode -recover

HDFS双NameNode发生故障后HA无法切换的问题
https://stanzhai.site/blog/post/stanzhai/HDFS%E5%8F%8CNameNode%E5%8F%91%E7%94%9F%E6%95%85%E9%9A%9C%E5%90%8EHA%E6%97%A0%E6%B3%95%E5%88%87%E6%8D%A2%E7%9A%84%E9%97%AE%E9%A2%98
dfs.ha.fencing.methods配置的是sshfence，SshFenceByTcpPort处理时会用到fuser这个命令。
给两个NameNode节点装上fuser命令就可以了。
sudo yum install psmisc -y

Incompatible namespaceID for journal Storage Directory
https://blog.csdn.net/shifenglov/article/details/38583971
调整/works/hadoop/dfs/name/current/VERSION中的记录

------------------------------
hdfs dfsadmin -report
hdfs version
hdfs dfs -put hello.txt /works/
hdfs dfs -cat /works/hello.txt
hdfs dfs -zcat /works/hello.gz
hdfs dfs -rm -r /works/hello.txt


hdfs dfs -put ~/test/hello.txt /works/
cd /works/soft/hadoop-2.7.7/share/hadoop/mapreduce
hadoop jar hadoop-mapreduce-examples-2.7.7.jar wordcount /works/hello.txt /works/result
hdfs dfs -ls /works/result

Permission denied: user=root, access=WRITE, inode="/":hadoopuser:supergroup:drwxr-xr-x
https://www.cnblogs.com/hunttown/p/5470848.html
hdfs dfs -chown -R dave /works/

cp -r dave@192.168.102.136:/Developer/Kylin/Drivers/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz .
tar zxvf sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz
mv sqoop-1.4.7.bin__hadoop-2.6.0 sqoop-1.4.7
scp -r dave@192.168.102.136:/Developer/Kylin/Drivers/mysql-connector-java-5.1.48-bin.jar $SQOOP_HOME/lib/
su -
cat > /etc/profile.d/sqoop.sh << EOF
export SQOOP_HOME=/works/soft/sqoop-1.4.7
export PATH=\$PATH:\$SQOOP_HOME/bin
EOF
exit
. /etc/profile
echo $SQOOP_HOME

cd /works/soft/sqoop-1.4.7/conf
cp -a sqoop-env-template.sh sqoop-env.sh
#在sqoop-env.sh脚本 中 找到 以下变量
export HADOOP_COMMON_HOME=/data/soft/new/hadoop
export HADOOP_MAPRED_HOME=/data/soft/new/hadoop

#Testing
sqoop list-databases --connect jdbc:mysql://192.168.80.196:3306 \
--username root --password Gk97TU6coSsvtipC9SB2

sqoop import --connect jdbc:mysql://192.168.80.196:3306/dwh \
--username root --password Gk97TU6coSsvtipC9SB2 \
--table dim_client \
--fields-terminated-by ',' \
--null-string '**' \
--m 1 \
--append --target-dir '/works/sqoop/dwh.db'

sqoop export -D sqoop.export.records.per.statement=100 \
 --connect jdbc:mysql://192.168.80.196:3306/dwh \
 --username root --password Gk97TU6coSsvtipC9SB2 \
--table dim_client_copy \
--fields-terminated-by ',' \
--export-dir "/works/sqoop/dwh.db/part-m-00000" \
--batch --update-key uid --update-mode allowinsert

-------------------------------------------
hbase:
cd /works/soft
scp -r dave@192.168.102.136:/Developer/Kylin/hbase-1.2.7-bin.tar.gz .
cd hbase-1.2.7
vim ./conf/hbase-env.sh
export JAVA_HOME=/works/soft/jdk1.8.0_241

vim conf/regionservers
dn1
dn2
dn3

su -
cat > /etc/profile.d/hbase.sh << EOF
export HBASE_HOME=/works/soft/hbase-1.2.7
export PATH=\$PATH:\$HBASE_HOME/bin
EOF
exit
. /etc/profile
echo $HBASE_HOME

scp -r dave@192.168.102.136:/Developer/Kylin/hbase/hbase-site.xml /works/soft/hbase-1.2.7/conf/

scp -r /works/soft/hbase-1.2.7 hadoop@nns:/works/soft/
scp -r /works/soft/hbase-1.2.7 hadoop@dn1:/works/soft/
scp -r /works/soft/hbase-1.2.7 hadoop@dn2:/works/soft/
scp -r /works/soft/hbase-1.2.7 hadoop@dn3:/works/soft/

mkdir -p /works/hbase/zk

同步所有机器的时间
sudo yum install rdate
sudo rdate -s time-b.nist.gov

#Working on nna
start-hbase.sh
jps:
HMaster

#Working on nns
hbase-daemon.sh start master
jps:
HMaster

#dn1/dn2/dn3
jps:
HRegionServer

#Web
http://nna:16010/


org.apache.hadoop.hbase.util.FSUtils: Waiting for dfs to exit safe mode...
https://www.cnblogs.com/luxh/archive/2013/04/13/3018701.html
hadoop dfsadmin -safemode leave

hbase shell
create 'game_x_tmp', '_x'
put 'game_x_tmp', 'rowkey1', '_x', 'v1'
scan 'game_x_tmp'
disable 'game_x_tmp'
drop 'game_x_tmp'

org.apache.hadoop.hbase.util.FileSystemVersionException
https://blog.csdn.net/u010199356/article/details/87523630
hadoop fs -rm -r /hbase
hdfs dfs -mkdir /hbase
restart to take affect


--------------------------------------------
spark:
#Working on dn1
cd /works/soft/
cp dave@192.168.102.136:/Developer/Kylin/spark/spark-2.4.5-bin-hadoop2.7.tgz .
tar zxvf spark-2.4.5-bin-hadoop2.7.tgz
mv spark-2.4.5-bin-hadoop2.7 spark-2.4.5

su -
cat > /etc/profile.d/spark.sh << EOF
export SPARK_HOME=/works/soft/spark-2.4.5
export PATH=\$PATH:\$SPARK_HOME/bin
EOF
exit
. /etc/profile
echo $SPARK_HOME

cd spark-2.4.5/conf/
cp -a spark-env.sh.template spark-env.sh
vim spark-env.sh
export JAVA_HOME=/works/soft/jdk1.8.0_241
export SCALA_HOME=/works/scala
export HADOOP_HOME=/works/soft/hadoop-2.7.7
export HADOOP_CONF_DIR=/works/soft/hadoop-2.7.7/etc/hadoop
#Spark集群master节点的ip地址
export SPARK_MASER_IP=dn1
#每个worker节点能够最大分配给exectors的内存大小
export SPARK_WORKER_MEMORY=2g
#每个worker节点所占有的cpu核数
export SPARK_WORKER_CORES=1
#每个节点上初始化的worker的个数
export SPARK_WORKER_INSTANCES=1

cp -a slaves.template slaves
vim slaves


scp -r /works/soft/spark-2.4.5 hadoop@dn2:/works/soft/
scp -r /works/soft/spark-2.4.5 hadoop@dn3:/works/soft/
#Starting
$SPARK_HOME/sbin/start-all.sh

jps:
#dn1: Master
#dn2/dn3:  Worker

#Web: http://dn1:8080

>spark-shell
#var lines=sc.textFile("/works/hello.txt")
var lines=sc.textFile("/works/sqoop/dwh.db/part-m-00000")

lines.count()

No live nodes contain current block Block locations: Dead nodes

#Working on dn1/dn2/dn3
putting zookeeper.service to "/usr/lib/systemd/system"
sudo scp dave@192.168.102.136:/Developer/Kylin/zookeeper.service /usr/lib/systemd/system/
sudo chmod +x /usr/lib/systemd/system/zookeeper.service 
sudo systemctl enable zookeeper
sudo systemctl start zookeeper

----------------------------------------------
hive:
#Working on nna/nns
sudo yum -y install gcc*
sudo yum -y install openssl-devel pcre-devel
scp -r dave@192.168.102.136:/Developer/Kylin/hive/haproxy-1.9.8.tar.gz /tmp
cd /tmp
tar zxvf haproxy-1.9.8.tar.gz
cd haproxy-1.9.8
make TARGET=linux2628 USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 USE_CRYPT_H=1 USE_LIBCRYPT=1
sudo make install
haproxy -vv

#Working on nna
mkdir -p works/soft/haproxy-1.9.8/
#vim /works/soft/haproxy-1.9.8/config.cfg
scp -r haproxy hadoop@nns:/works/


#Working on dn1
scp -r dave@192.168.102.136:/Developer/Kylin/hive/apache-hive-2.3.7-bin.tar.gz .
tar zxvf apache-hive-2.3.7-bin.tar.gz
mv apache-hive-2.3.7-bin apache-hive-2.3.7
cd apache-hive-2.3.7
scp -r dave@192.168.102.136:/Developer/Kylin/Drivers/mysql-connector-java-5.1.48-bin.jar /works/soft/apache-hive-2.3.7/lib

在Hadoop 分布式文件系统上创建数据仓库（ Hive ）的路径地址
hdfs dfs -mkdir -p /works/hive/warehouse
hdfs dfs -mkdir -p /works/tmp/hive/
hdfs dfs -chmod 777 /works/hive/warehouse
hdfs dfs -chmod 777 /works/tmp/hive

#local on dn1/dn2/dn3
mkdir -p /works/hive/

#Working on dn1/dn2/dn3
su -
cat > /etc/profile.d/hive.sh << EOF
export HIVE_HOME=/works/soft/apache-hive-2.3.7
export PATH=\$PATH:\$HIVE_HOME/bin
EOF
exit
. /etc/profile
echo $HIVE_HOME

#Working on dn1
cd $HIVE_HOME/conf
cp -a hive-env.sh.template hive-env.sh
vim hive-env.sh
＃配置 HADOOP HOME 环境变量路径地址
HADOOP_HOME=/works/soft/hadoop-2.7.7
cp -a hive-log4j2.properties.template hive-log4j2.properties
vim $HIVE_HOME/conf/hive-log4j2.properties 
#修改
property.hive.log.dir = /works/soft/apache-hive-2.3.7/logs
property.hive.log.file = hive.log

MySQL创建hive用户
sqoop import --connect jdbc:mysql://192.168.80.196:3306/dwh \
--username root --password Gk97TU6coSsvtipC9SB2 \

mysql -uroot -h192.168.80.196 -pGk97TU6coSsvtipC9SB2
grant all privileges on *.* to hive@'%' identified by 'Aa654321';

mysqladmin  -uroot -p -S /data/mydata/mysql.sock shutdown
/works/app/mysql/bin/mysqld_safe --defaults-file=/etc/my.cnf --user=mysql --basedir=/works/app/mysql --datadir=/data/mydata &

cd $HIVE_HOME/bin
./schematool -initSchema -dbType mysql
hive -e "show tables;"

#Working on dn1
scp -r /works/soft/apache-hive-2.3.7 hadoop@dn2:/works/soft/
scp -r /works/soft/apache-hive-2.3.7 hadoop@dn3:/works/soft/

#Working on dn1/dn2/dn3
hive --service hiveserver2 & 
#https://my.oschina.net/zss1993/blog/1607208
http://dn1:10002
#Working on nna/nns
haproxy -f /works/haproxy/config.cfg
http://nna:1090/
admin/123456

hive>
＃在创建数据库时添加判断，防止因创建的数据库己存在而抛出异常
CREATE DATABASE IF NOT EXISTS game; 
#hdfs dfs -ls /works/hive/warehouse/game.db/
#CASCADE表示强制删除所有的数据，不加的话，必须先删除所有的表才能删除数据库
DROP DATABASE IF EXISTS game CASCADE;
USE game;
＃创建表时添加判断，防止因创建的表己存在而抛出异常
CREATE TABLE IF NOT EXISTS IP_LOGIN_TEXT( 
  `stm`  string  comment    '时间戳', 
  `uid`  string   comment    '平台id', 
  `ip`   string  comment    '登录IP',
  `plat` string  comment    '平台号'
) ROW FORMAT SERDE "org.apache.hive.hcatalog.data.JsonSerDe" STORED AS TEXTFILE; 
 desc IP_LOGIN_TEXT;
＃清空表数据
TRUNCATE TABLE IP_LOGIN_TEXT; 
DROP TABLE IF EXISTS IP_LOGIN_TEXT; 

#分区存储
＃按天分区 ORCFILE 格式进行存储
CREATE TABLE IF NOT EXISTS IP_LOGIN( 
  `stm`  string  comment    '时间戳', 
  `uid`  string   comment    '平台id', 
  `ip`   string  comment    '登录IP',
  `plat` string  comment    '平台号'
) PARTITIONED BY (tm int comment '分区日期(格式yyyyMMdd:20171101)')
CLUSTERED BY (`uid`) SORTED BY (`uid`) INTO 2 BUCKETS STORED AS ORC;

#https://www.cnblogs.com/frankdeng/p/9403942.html
create table student(
  id int, 
  name string, 
  sex string, 
  age int, 
  department string
) row format delimited fields terminated by ",";
load data local inpath "/home/hadoop/student.txt" into table student;
select * from student;
desc student;

CREATE TABLE alerts ( id int, msg string ) 
partitioned by (continent string, country string) 
clustered by (id) into 5 buckets 
stored as orc tblproperties ("transactional"= "true"); 

#-------------------------
yarn:
yarn application


Kylin:
#http://kylin.apache.org/cn/docs/install/index.html
4 core CPU，16 GB 内存和 100 GB 磁盘
su - hadoop
确保有以下客户端环境：Hive，HBase，HDFS
#Working on kylin1
scp dave@192.168.102.136:/Developer/Kylin/soft/sources/apache-kylin-3.0.1-bin-hbase1x.tar.gz /works/soft/
mv apache-kylin-3.0.1-bin-hbase1x apache-kylin-3.0.1
sudo chown -R hadoop:hadoop /works/soft/apache-kylin-3.0.1
su -
cat > /etc/profile.d/kylin.sh << EOF
export KYLIN_HOME=/works/soft/apache-kylin-3.0.1
export PATH=\$PATH:\$KYLIN_HOME/bin
EOF
exit
. /etc/profile

# scp -r hadoop@dn1:/works/soft/apache-hive-2.3.7 /works/soft/
# su -
# cat > /etc/profile.d/hive.sh << EOF
# export HIVE_HOME=/works/soft/apache-hive-2.3.7
# export PATH=\$PATH:\$HIVE_HOME/bin
# EOF
# exit
# . /etc/profile
# echo $HIVE_HOME

# scp -r hadoop@dn1:/works/soft/spark-2.4.5 /works/soft/
# su -
# cat > /etc/profile.d/spark.sh << EOF
# export SPARK_HOME=/works/soft/spark-2.4.5
# export PATH=\$PATH:\$SPARK_HOME/bin
# EOF
# exit
# . /etc/profile
# echo $SPARK_HOME
vim $KYLIN_HOME/conf/kylin.properties
scp -r apache-kylin-3.0.1 hadoop@kylin2:/works/soft/

$KYLIN_HOME/bin/check-env.sh
$KYLIN_HOME/bin/kylin.sh start

kylin UnknownHostException: dn1:2181: invalid IPv6 address
端口号2181在zk connectString里写了两遍 
hbase-site.xml的hbase.zookeeper.quorum，该项只需配置Host不需要配置端口号Port。
tail -n100 -f $KYLIN_HOME/logs/kylin.log
hdfs dfs -ls /kylin/

http://kylin1:7070/kylin
http://nna:50070/dfshealth.html#tab-overview
http://nna:8188/cluster
http://nna:16010/master-status

http://dn1:8080
http://nna:1090/


-----------------------------------------
#Starting all of the servers
#Working on all
sudo route del default gw 10.0.2.2

#Working on dn1/dn2/dn3
#su - hadoop
#zkServer.sh start

#Working on nna
#hadoop-daemons.sh start journalnode
start-dfs.sh
start-yarn.sh
:8090
yarn-daemon.sh start proxyserver
#https://www.cnblogs.com/honeybee/p/8276984.html
# hadoop-daemon.sh start namenode
#Working on nns
yarn-daemon.sh start resourcemanager
#https://www.hemingliang.site/169.html
#hadoop namenode -recover

#Working on all nodes, including all of the kylin nodes
:10020 :19888
mr-jobhistory-daemon.sh start historyserver

# Hadoop 访问地址
http://nna:50070/
#YARN (资源管理调度)访问地址
http://nna:8188/

#hdfs dfs -cat /works/hello.txt

#habse 
#Working on nna
#hadoop dfsadmin -safemode leave
start-hbase.sh
#Working on nns
hbase-daemon.sh start master

#Web
http://nna:16010/

#Starting dn1
$SPARK_HOME/sbin/start-all.sh

#Web: http://dn1:8080

#hive
#Working on dn1/dn2/dn3
hive --service hiveserver2 & 

#Working on nna/nns
haproxy -f /works/soft/haproxy-1.9.8/config.cfg
http://nna:1090/
admin/123456


Hadoop:
nna: NameNode Active  2G/2c   DFSZKFailoverController HMaster
nns: NameNode Standby 2G/2c   DFSZKFailoverController HMaster
dn1: DateNode         1G/1c   QuorumPeerMain          HRegionServer
dn2: DataNode         1G/1c   QuorumPeerMain          HRegionServer
dn3: DataNode         1G/1c   QuorumPeerMain          HRegionServer

HBase:
nna: HMaster          2G/2c   
nns: HMaster          2G/2c
dn1: HMaster          1G/1c
dn2: HMaster          1G/1c
dn3: HMaster          1G/1c

Spark:
dn1: Master           1G/1c
dn2: Worker           1G/1c
dn3: Worker           1G/1c

Hive:
nna: HAProxy/MySQL    2G/2c 
nns: HAProxy          2G/2c
dn1: Hive             1G/1c
dn2: Hive             1G/1c
dn3: Hive             1G/1c

