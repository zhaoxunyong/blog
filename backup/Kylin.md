## Docker
http://192.168.80.196:7070/kylin
http://192.168.80.196:50070/dfshealth.html#tab-overview
http://192.168.80.196:8088/cluster
http://192.168.80.196:16010/master-status

默认的系统管理员 ADMIN 的密码为 KYLIN

http://kylin.apache.org/cn/docs/tutorial/create_cube.html
https://juejin.im/post/5bd81eafe51d457b26679917
https://juejin.im/post/5bc34a246fb9a05cfd27fe54
https://www.jianshu.com/p/4f4417ef790a
https://blog.csdn.net/qq_43147136/article/details/89189759

MySQL: 
mysql -uroot -h192.168.80.196 -pGk97TU6coSsvtipC9SB2

/works/soft/sqoop-1.4.7/bin/sqoop list-databases --connect jdbc:mysql://192.168.80.196:3306 --username root --password Gk97TU6coSsvtipC9SB2

https://www.cnblogs.com/chushiyaoyue/p/5707683.html


https://blog.csdn.net/qq_31598113/article/details/82387952
https://www.cnblogs.com/chwilliam85/p/9693276.html
#https://www.cnblogs.com/scw2901/p/4331682.html
https://blog.csdn.net/dai451954706/article/details/50464036/
https://blog.csdn.net/zhouyan8603/article/details/47398245
docker run -d \
-m 50G --name kylin \
-p 7070:7070 \
-p 8088:8088 \
-p 50070:50070 \
-p 8032:8032 \
-p 8042:8042 \
-p 16010:16010 \
apachekylin/apache-kylin-standalone:3.0.2
docker cp /etc/localtime kylin:/etc/localtime
docker restart kylin
docker exec -it kylin /bin/bash

https://www.cnblogs.com/tianphone/p/10763385.html
yum install epel-release vim openssh-server -y
yum -y install htop
/etc/init.d/sshd start
chkconfig sshd on

https://www.jianshu.com/p/20935b0d1940
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys

scp -r dave@192.168.102.136:/Developer/Kylin/Drivers .
tar zxvf Drivers/sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz -C /home/admin/
mv sqoop-1.4.7.bin__hadoop-2.6.0 sqoop-1.4.7

vim /etc/profile
export SQOOP_HOME=/works/soft/sqoop-1.4.7
export PATH=$SQOOP_HOME/bin:$PATH
. /etc/profile

vim ./hadoop-2.7.0/etc/hadoop/hadoop-env.sh
export JAVA_HOME=/home/admin/jdk1.8.0_141

cp -a Drivers/mysql-connector-java-5.1.48-bin.jar $KYLIN_HOME/ext
cp -a Drivers/mysql-connector-java-5.1.48-bin.jar $SQOOP_HOME/lib



vim $KYLIN_HOME/conf/kylin.properties:
kylin.source.default=8
kylin.source.jdbc.connection-url=jdbc:mysql://192.168.80.196:3306/dwh?dontTrackOpenResources=true&defaultFetchSize=1000&useCursorFetch=true
kylin.source.jdbc.driver=com.mysql.jdbc.Driver
kylin.source.jdbc.dialect=mysql
kylin.source.jdbc.user=root
kylin.source.jdbc.pass=Gk97TU6coSsvtipC9SB2
kylin.source.jdbc.sqoop-home=/works/soft/sqoop-1.4.7
kylin.source.jdbc.filed-delimiter=|
注意：修改以上jdbc配置，job需要删除并重新创建才能生效

vim hadoop-2.7.0/etc/hadoop/mapred-site.xml
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>0.0.0.0:10020</value>
    <description>MapReduce JobHistory Server IPC host:port</description>
    </property>

    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>0.0.0.0:19888</value>
    <description>MapReduce JobHistory Server Web UI host:port</description>
    </property>

     <!--每个Map Task需要的物理内存量-->
    <property>
        <name>mapreduce.map.memory.mb</name>
        <!--修改前<value>2048</value>-->
        <value>3072</value>
    </property>
    <!--每个Reduce Task需要的物理内存量-->
    <property>
        <name>mapreduce.reduce.memory.mb</name>
        <!--修改前<value>3072</value>-->
    <value>5120</value>
    </property>
    <property>
        <name>mapreduce.map.java.opts</name>
        <!--须小于mapreduce.map.memory.mb的值,一般设置为0.75倍的memory.mb，因为需要为java code等预留些空间-->
        <value>-Xmx2560m</value>
    </property>
    <property>
        <name>mapreduce.reduce.java.opts</name>
        <!--须小于mapreduce.reduce.memory.mb的值,一般设置为0.75倍的memory.mb，因为需要为java code等预留些空间-->
        <value>-Xmx4608m</value>
    </property>

https://stackoverflow.com/questions/50129537/why-does-hadoop-on-windows-trying-to-connect-0-0-0-010020-unsuccessfully
mapred historyserver
lsof -i:10020
#./hadoop-2.7.0/sbin/stop-all.sh
#./hadoop-2.7.0/sbin/start-all.sh
tail -n100 -f /home/admin/apache-kylin-3.0.1-bin-hbase1x/logs/kylin.log

解决Extract Fact Table Distinct Columns卡死的问题：
vim hadoop-2.7.0/etc/hadoop/yarn-site.xml
    <!--<property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>6144</value>
    </property>-->
    <!-- 设置每个节点的可用内存，单位MB。合理设置该参数，将影响到DataNode的运行情况 -->
    <property>
       <name>yarn.nodemanager.resource.memory-mb</name>
       <value>40960</value>
    </property>
    <!-- 单个任务可申请的最小内存，默认1024MB -->
    <property>
       <name>yarn.scheduler.minimum-allocation-mb</name>
       <value>2048</value>
    </property>
    <!-- 单个任务可申请的最大内存，默认8192MB
    <property>
       <name>yarn.scheduler.maximum-allocation-mb</name>
       <value>8192</value>
    </property> -->
    <property>
        <name>yarn.nodemanager.vmem-pmem-ratio</name>
        <value>2.1</value>
    </property>
    <!-- 设置每个节点虚拟cpu内核数 -->
     <property>
        <name>yarn.nodemanager.resource.cpu-vcores</name>
        <value>62</value>
    </property>

docker restart kylin


dwh.dws_fin_loan_account_d,dwh.dim_account_age,dwh.dim_client,dwh.dim_collection_status,dwh.dim_contract,dwh.dim_date,dwh.dim_loan_account,dwh.dim_loan_account_process_status,dwh.dim_loan_account_status,dwh.dim_loan_account_type,dwh.dim_loan_bill,dwh.dim_loan_product,dwh.dim_loan_type,dwh.dim_repay_amount_type,dwh.dim_source_system,dwh.dim_trading_summary,dwh.dim_virtual_center,dwh.dws_fin_exempt

performance:
4-5 core less than 30G RAM
21,475,144: 4.6h
2,145,539: 48min

https://www.jianshu.com/p/57178dce12de

SELECT dws_fin_loan_account_d.fin_loan_account_d_id as DWS_FIN_LOAN_ACCOUNT_D_FIN_LOAN_ACCOUNT_D_ID ,dws_fin_loan_account_d.snap_date_key ,dws_fin_loan_account_d.loan_bill_id as DWS_FIN_LOAN_ACCOUNT_D_LOAN_BILL_ID ,dws_fin_loan_account_d.loan_client_id as DWS_FIN_LOAN_ACCOUNT_D_LOAN_CLIENT_ID ,dws_fin_loan_account_d.loan_account_id as DWS_FIN_LOAN_ACCOUNT_D_LOAN_ACCOUNT_ID ,dim_date.date_key as DIM_DATE_DATE_KEY ,dws_fin_loan_account_d.principal_balance_repay_amount as DWS_FIN_LOAN_ACCOUNT_D_PRINCIPAL_BALANCE_REPAY_AMOUNT ,dws_fin_loan_account_d.principal_balance_repay_irr_amount as DWS_FIN_LOAN_ACCOUNT_D_PRINCIPAL_BALANCE_REPAY_IRR_AMOUNT ,dws_fin_loan_account_d.principal_balance_process_amount as DWS_FIN_LOAN_ACCOUNT_D_PRINCIPAL_BALANCE_PROCESS_AMOUNT ,dws_fin_loan_account_d.principal_balance_process_irr_amount as DWS_FIN_LOAN_ACCOUNT_D_PRINCIPAL_BALANCE_PROCESS_IRR_AMOUNT  FROM dwh.dws_fin_loan_account_d dws_fin_loan_account_d INNER JOIN dwh.dim_date dim_date ON dws_fin_loan_account_d.snap_date_key = dim_date.date_key WHERE 1=1 AND (dws_fin_loan_account_d.snap_date_key >= '2020-01-01' AND dws_fin_loan_account_d.snap_date_key < '2020-04-30')


SELECT min(snap_date_key), max(snap_date_key) FROM dwh.dws_fin_loan_account_d  WHERE dws_fin_loan_account_d.snap_date_key >= '2020-01-01' AND dws_fin_loan_account_d.snap_date_key < '2020-04-30'

SELECT dws_fin_loan_account_d.snap_date_key as SNAP_DATE_KEY, 
sum(DWS_FIN_LOAN_ACCOUNT_D.PRINCIPAL_BALANCE_REPAY_AMOUNT) as PRINCIPAL_BALANCE_REPAY_AMOUNT, 
sum(DWS_FIN_LOAN_ACCOUNT_D.PRINCIPAL_BALANCE_REPAY_IRR_AMOUNT) as PRINCIPAL_BALANCE_REPAY_IRR_AMOUNT, 
sum(DWS_FIN_LOAN_ACCOUNT_D.PRINCIPAL_BALANCE_PROCESS_AMOUNT) as PRINCIPAL_BALANCE_PROCESS_AMOUNT,
sum(DWS_FIN_LOAN_ACCOUNT_D.PRINCIPAL_BALANCE_PROCESS_IRR_AMOUNT) as PRINCIPAL_BALANCE_PROCESS_IRR_AMOUNT
FROM dwh.dws_fin_loan_account_d  
WHERE dws_fin_loan_account_d.snap_date_key >= '2013-01-01' 
AND dws_fin_loan_account_d.snap_date_key < '2020-04-30' 
GROUP BY dws_fin_loan_account_d.snap_date_key

SELECT dws_fin_loan_account_d.snap_date_key as SNAP_DATE_KEY, 
sum(DWS_FIN_LOAN_ACCOUNT_D.PRINCIPAL_BALANCE_REPAY_AMOUNT) as PRINCIPAL_BALANCE_REPAY_AMOUNT, 
sum(DWS_FIN_LOAN_ACCOUNT_D.PRINCIPAL_BALANCE_REPAY_IRR_AMOUNT) as PRINCIPAL_BALANCE_REPAY_IRR_AMOUNT, 
sum(DWS_FIN_LOAN_ACCOUNT_D.PRINCIPAL_BALANCE_PROCESS_AMOUNT) as PRINCIPAL_BALANCE_PROCESS_AMOUNT,
sum(DWS_FIN_LOAN_ACCOUNT_D.PRINCIPAL_BALANCE_PROCESS_IRR_AMOUNT) as PRINCIPAL_BALANCE_PROCESS_IRR_AMOUNT
FROM dwh.dws_fin_loan_account_d dws_fin_loan_account_d 
INNER JOIN dwh.dim_date dim_date ON dws_fin_loan_account_d.snap_date_key = dim_date.date_key 
WHERE 1=1 
AND (dws_fin_loan_account_d.snap_date_key >= '2013-01-01' 
AND dws_fin_loan_account_d.snap_date_key < '2020-04-30')
GROUP BY dws_fin_loan_account_d.snap_date_key

## Cluster

Hadoop: 2.7+, 3.1+ (since v2.5)            hadoop-2.7.7
Hive: 0.13 - 1.2.1+                        apache-hive-2.3.7
HBase: 1.1+, 2.0 (since v2.5)              hbase-1.2.7
Spark (可选) 2.3.0+                         spark-2.4.5
Kafka (可选) 1.0.0+ (since v2.5)            
JDK: 1.8+ (since v2.5)                     jdk-8u241
OS:                                        CentOS Linux release 7.7.1908

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
192.168.80.187 kylin1
192.168.80.188 kylin2
192.168.80.189 kylin3
192.168.80.190 nna
192.168.80.191 nns
192.168.80.192 dn1
192.168.80.193 dn2
192.168.80.194 dn3
EOF


#Working on all nodes
sudo su - hadoop
ssh-keygen -t rsa
#直接写入到nna的~/.ssh/authorized_keys中：
ssh-copy-id -i ~/.ssh/id_rsa.pub hadoop@nna
sudo chmod 700 ~/.ssh
sudo chmod 600 ~/.ssh/authorized_keys
#只在nna
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
将其他机器中的~/.ssh/id_rsa.pub内容追加到~/.ssh/authorized_keys中,并复制到所有机器
scp ~/.ssh/authorized_keys hadoop@nns:~/.ssh/
scp ~/.ssh/authorized_keys hadoop@dn1:~/.ssh/
scp ~/.ssh/authorized_keys hadoop@dn2:~/.ssh/
scp ~/.ssh/authorized_keys hadoop@dn3:~/.ssh/
scp ~/.ssh/authorized_keys hadoop@kylin1:~/.ssh/

---------------------------------------------------
#所有
su - hadoop
ssh hadoop@nna "sudo chown hadoop -R /works"
ssh hadoop@nns "sudo chown hadoop -R /works"
ssh hadoop@dn1 "sudo chown hadoop -R /works"
ssh hadoop@dn2 "sudo chown hadoop -R /works"
ssh hadoop@dn3 "sudo chown hadoop -R /works"

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

ssh hadoop@dn1 "echo 1 > /works/zkdata/myid"
ssh hadoop@dn2 "echo 2 > /works/zkdata/myid"
ssh hadoop@dn3 "echo 3 > /works/zkdata/myid"

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
rm -fr /works/hadoop/tmp
rm -fr /works/hadoop/tmp/journal
rm -fr /works/hadoop/tmp/journal
rm -fr /works/hadoop/dfs/name
rm -fr /works/hadoop/dfs/data
rm -fr /works/hadoop/yarn/local
rm -fr /works/hadoop/log/yarn
rm -fr /works/soft/hadoop-2.7.7/logs

mkdir -p /works/hadoop/tmp
mkdir -p /works/hadoop/tmp/journal
mkdir -p /works/hadoop/tmp/journal
mkdir -p /works/hadoop/dfs/name
mkdir -p /works/hadoop/dfs/data
mkdir -p /works/hadoop/yarn/local
mkdir -p /works/hadoop/log/yarn
mkdir -p /works/soft/hadoop-2.7.7/logs

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

#Working on nns:
#同步 nna 节点元数据信息到 nns 节点
#hdfs namenode -bootstrapStandby


#Working on nns
切换到 nns 节 点上并输入 j ps 命令查看相关的启动进程。如果发现只有 DFSZK
ailoverontroller 服务进程,可以手动启动 nns 节点上的 NameNode 和 ResourceManager 服务
进程, 具 体操作命令如下:
#启动 NameNode 进程
cd /works/soft/hadoop-2.7.7/sbin
hadoop-daemon.sh start namenode
#启动 ResourceManager 进程
yarn-daemon.sh start resourcemanager

#Working on nna
yarn-daemon.sh start proxyserver
mr-jobhistory-daemon.sh start historyserver

在当前节点的终端上输入 jps 命 令查看相关的服务进程,其 中包含 
DFSZKFailoverController 、 NameNode 和 ResomceManager 服务进程。


# Hadoop 访问地址
http://nna:50070/
http://nns:50070/
#YARN (资源管理调度)访问地址
http://nna:8188/
http://nns:8188/

https://www.jianshu.com/p/c44495a1004
找到hadoop安装目录下 /works/hadoop/dfs/name/current里面的current文件夹删除
然后从新执行一下 hadoop namenode -format
再使用start-dfs.sh和start-yarn.sh 重启一下hadoop
用jps命令看一下就可以看见datanode已经启动了
#dn1/dn2/dn3
ssh hadoop@nna "rm -fr /works/hadoop/dfs/data/current"
ssh hadoop@nns "rm -fr /works/hadoop/dfs/data/current"
ssh hadoop@dn1 "rm -fr /works/hadoop/dfs/data/current"
ssh hadoop@dn2 "rm -fr /works/hadoop/dfs/data/current"
ssh hadoop@dn3 "rm -fr /works/hadoop/dfs/data/current"
stop-all.sh
start-all.sh
#hadoop-daemons.sh start journalnode
#格式化 NameNode 节点
hdfs namenode -format
#向 Zoo keeper 注册
# zkfc -formatZK
start-dfs.sh
start-yarn.sh
yarn-daemon.sh start proxyserver
mr-jobhistory-daemon.sh start historyserver

Initialization failed for Block pool BP-759442594-192.168.80.191-1588834760484 (Datanode Uuid b0f6ca98-4b67-46b8-8121-baf29d34afed) service to nna/192.168.80.190:9000 Blockpool ID mismatch: previously connected to Blockpool ID BP-759442594-192.168.80.191-1588834760484 but now connected to Blockpool ID BP-695244506-192.168.80.190-1588835193647
https://blog.csdn.net/sunggff/article/details/72885187
修改namenode的/works/hadoop/dfs/name/current/VERSION 
的blockpoolID=BP-695244506-192.168.80.190-1588835193647

Incompatible namespaceID for journal Storage Directory /home/rimi/bigData/hadoop-2.2.0/tmp/journal/cluster1: NameNode has nsId 2006559846 but storage has nsId 1781480752
https://blog.csdn.net/shifenglov/article/details/38583971
修改dn1/dn2/dn3的以下内容与namenode保持一致
vim /works/hadoop/dfs/data/current/VERSION
vim /works/hadoop/tmp/journal/cluster1/current/VERSION


echo "xxx" > hello.txt
#上传本地文件到分布式文件系统中的 tmp 目录
hdfs dfs -mkdir /works/
hdfs dfs -ls /works/
hdfs dfs -put hello.txt /works/abc.txt
hdfs dfs -cat /works/abc.txt
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
#Working on all nodes:
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

#Working on dn1
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

<!-- #Working on dn1/dn2/dn3
putting zookeeper.service to "/usr/lib/systemd/system"
sudo scp dave@192.168.102.136:/Developer/Kylin/zookeeper.service /usr/lib/systemd/system/
sudo chmod +x /usr/lib/systemd/system/zookeeper.service 
sudo systemctl enable zookeeper
sudo systemctl start zookeeper -->

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
mkdir -p /works/soft/haproxy-1.9.8/
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

<!-- #local on dn1/dn2/dn3
ssh hadoop@dn1 "rm -fr /works/hive/"
ssh hadoop@dn2 "rm -fr /works/hive/"
ssh hadoop@dn3 "rm -fr /works/hive/"

ssh hadoop@dn1 "mkdir -p /works/hive/"
ssh hadoop@dn2 "mkdir -p /works/hive/"
ssh hadoop@dn3 "mkdir -p /works/hive/" -->


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
<!-- sqoop import --connect jdbc:mysql://192.168.80.196:3306/dwh \
--username root --password Gk97TU6coSsvtipC9SB2 \ -->

>mysql -uroot -h192.168.80.196 -pGk97TU6coSsvtipC9SB2
grant all privileges on *.* to hive@'%' identified by 'Aa654321';

<!-- mysqladmin  -uroot -p -S /data/mydata/mysql.sock shutdown
/works/app/mysql/bin/mysqld_safe --defaults-file=/etc/my.cnf --user=mysql --basedir=/works/app/mysql --datadir=/data/mydata & -->

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

Failed to find metadata store by url: kylin_metadata@hbase
https://www.cnblogs.com/harrymore/p/10882090.html
zkCli.sh
rmr /kylin/kylin_metadata
rmr /hbase/table/kylin_metadata

http://kylin1:7070/kylin
http://nna:50070/dfshealth.html#tab-overview
http://nna:8188/cluster
http://nna:16010/master-status

http://dn1:8080
http://nna:1090/


https://dongkelun.com/2018/05/06/sparkSubmitException/
DatastoreDriverNotFoundException:
解决方案 
kylin1:
cp -a /works/soft/apache-kylin-3.0.2/ext/mysql-connector-java-5.1.48-bin.jar $SPARK_HOME/jars/


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
http://nns:50070/
#YARN (资源管理调度)访问地址
http://nna:8188/

hdfs dfs -cat /works/abc.txt

#habse 
#Working on nna
#hadoop dfsadmin -safemode leave
start-hbase.sh
#Working on nns
hbase-daemon.sh start master
#Web
http://nna:16010/
http://nns:16010/

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

/works/hadoop/dfs/name
/works/hadoop/dfs/data

#Working on dn1/dn2/dn3

#Working on all of nodes
rm -fr /works/hadoop/tmp
rm -fr /works/hadoop/tmp/journal
rm -fr /works/hadoop/tmp/journal
rm -fr /works/hadoop/dfs/name
rm -fr /works/hadoop/dfs/data
rm -fr /works/hadoop/yarn/local
rm -fr /works/hadoop/log/yarn
rm -fr /works/soft/hadoop-2.7.7/logs

mkdir -p /works/hadoop/tmp
mkdir -p /works/hadoop/tmp/journal
mkdir -p /works/hadoop/tmp/journal
mkdir -p /works/hadoop/dfs/name
mkdir -p /works/hadoop/dfs/data
mkdir -p /works/hadoop/yarn/local
mkdir -p /works/hadoop/log/yarn
mkdir -p /works/soft/hadoop-2.7.7/logs

Hive:
hdfs dfs -mkdir -p /works/hive/warehouse
hdfs dfs -mkdir -p /works/tmp/hive/
hdfs dfs -chmod 777 /works/hive/warehouse
hdfs dfs -chmod 777 /works/tmp/hive

#local on dn1/dn2/dn3
ssh hadoop@dn1 "rm -fr /works/hive/"
ssh hadoop@dn2 "rm -fr /works/hive/"
ssh hadoop@dn3 "rm -fr /works/hive/"

ssh hadoop@dn1 "mkdir -p /works/hive/"
ssh hadoop@dn2 "mkdir -p /works/hive/"
ssh hadoop@dn3 "mkdir -p /works/hive/"


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


zkServer.sh start
dn1/dn2/dn3
QuorumPeerMain  Port: 2181
netstat -anp | grep 6176

start-dfs.sh
nna/nns
9030 DFSZKFailoverController  Port: 8019
8712 NameNode  Port: 9000/50070
dn1/dn2/dn3
6465 JournalNode  Port: 8480/8485
6355 DataNode  Port: 50010/50075/8800/50020

start-yarn.sh
nna
9243 ResourceManager  Port: 8188/8033/8130/8131/8131
nns
yarn-daemon.sh start resourcemanager
9243 ResourceManager  Port: 8188/8033/8130/8131/8131
dn1/dn2/dn3
6260 NodeManager Port: 13562/23078/8040/8042

yarn-daemon.sh start proxyserver
dna
9578 WebAppProxyServer Port: 8090

start-hbase.sh
nna
9895 HMaster  Port: 16000/16010
nns
hbase-daemon.sh start master
9895 HMaster  Port: 16000/16010
dn1/dn2/dn3
6974 HRegionServer Port: 16030/16020

$SPARK_HOME/sbin/start-all.sh
dn1
7266 Master  Port: 7077/8080
dn2/dn3
6927 Worker  Port: 8081

Hive
dn1/dn2/dn3
7587 RunJar Port: 10000/10002

Haproxy
nna/nns
Port: 1090/10001

mr-jobhistory-daemon.sh start historyserver
nna/nns/dn1/dn2/dn3
10381 JobHistoryServer Port: 10020/10020/10033

kylin.sh start
kylin1
5781 RunJar  Port: 7070/9009
http://kylin1:7070/kylin

yarn application -list 
yarn application -kill application_1588257935302_0002
#Deleting all
yarn application -list|grep "UNDEFINED"|awk '{print $1}'|sed 's;^;yarn application -kill ;'|sh +x


--------------------------------------------
CDH
https://docs.cloudera.com/documentation/enterprise/5/latest/topics/cm_ig_host_allocations.html#concept_f43_j4y_dw__section_icy_mgj_ndb
https://docs.cloudera.com/documentation/enterprise/release-notes/topics/hardware_requirements_guide.html
https://docs.cloudera.com/documentation/enterprise/release-notes/topics/cdh_vd_cdh_package_tarball.html
https://docs.cloudera.com/documentation/enterprise/release-notes/topics/cdh_vd_cdh_package_tarball_516.html

#Working on all
sudo vim /etc/resolv.conf
nameserver 114.114.114.114 
nameserver 8.8.8.8

sudo su -
echo "vm.swappiness = 10" >> /etc/sysctl.conf
sysctl -p

echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled"  >> /etc/rc.local
 

sudo yum localinstall *.rpm
#Working on nns
sudo mkdir -p /opt/cloudera/parcel-repo
#mv CDH-5.16.2-1.cdh5.16.2.p0.8-el7.parcel.sha.1 CDH-5.16.2-1.cdh5.16.2.p0.8-el7.parcel.sha
cp -a CDH-5.16.2-1.cdh5.16.2.p0.8-el7.parcel* manifest.json /opt/cloudera/parcel-repo/
sudo mv /etc/cloudera-scm-server/db.properties /etc/cloudera-scm-server/db.properties.bak
chmod u+x cloudera-manager-installer.bin
sudo ./cloudera-manager-installer.bin

scp -r dave@192.168.102.172:/Developer/Kylin/Drivers/mysql-connector-java-5.1.48-bin.jar /opt/cloudera/parcels/CDH-5.16.2-1.cdh5.16.2.p0.8/lib/sqoop/lib/

hbase-site.xml

Standalone HBase
https://hbase.apache.org/book.html#quickstart
sudo mkdir -p /data/hbase
sudo mkdir -p /Kylin
sudo chown -R hadoop:hadoop /data/hbase
sudo chown -R hdfs:hdfs /kylin
<!-- mkdir -p /var/lib/hive/
chown -R hdfs:hdfs /var/lib/hive/ -->
start-hbase.sh 

https://blog.csdn.net/u014235646/article/details/100928291#53_jdbc_265
Hive:
sudo scp -r dave@192.168.102.195:/Developer/Kylin/Drivers/*.jar /opt/cloudera/parcels/CDH/lib/hive/lib/
jdbc driver
将mysql驱动放置在组件所部署机器上的/usr/share/java/目录下，没有目录则创建目录。并将驱动更名为mysql-connector-java.jar
-- hive数据库 
create database hive DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
-- 集群监控数据库
create database amon DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
-- hue数据库
create database hue DEFAULT CHARSET utf8 COLLATE utf8_general_ci;
-- oozie数据库
create database oozie DEFAULT CHARSET utf8 COLLATE utf8_general_ci;

Hive Gateway需要安装在kylin中

hbase shell
create 'game_x_tmp', '_x'
put 'game_x_tmp', 'rowkey1', '_x', 'v1'
scan 'game_x_tmp'
disable 'game_x_tmp'
drop 'game_x_tmp'

kylin.engine.spark.rdd-partition-cut-mb=500


Dimensions：
1	DWS_FIN_LOAN_ACCOUNT_D	
["FIN_LOAN_ACCOUNT_D_ID","SID","SOURCE_SYSTEM_ID","LOAN_BILL_ID","LOAN_CLIENT_ID","LOAN_ACCOUNT_ID","CONTRACT_ID","LOAN_PRODUCT_ID","VIRTUAL_CENTER_ID","SNAP_DATE_KEY"]
2	DIM_DATE	
["DATE_KEY","MONTH","YEAR","QUARTER","SEASON"]

Measures：
1	DWS_FIN_LOAN_ACCOUNT_D.PRINCIPAL_BALANCE_REPAY_AMOUNT
2	DWS_FIN_LOAN_ACCOUNT_D.PRINCIPAL_BALANCE_REPAY_IRR_AMOUNT
3	DWS_FIN_LOAN_ACCOUNT_D.PRINCIPAL_BALANCE_PROCESS_AMOUNT
4	DWS_FIN_LOAN_ACCOUNT_D.PRINCIPAL_BALANCE_PROCESS_IRR_AMOUNT
5	DWS_FIN_LOAN_ACCOUNT_D.RECEIVE_INCOME_REPAY_AMOUNT
6	DWS_FIN_LOAN_ACCOUNT_D.RECEIVE_INCOME_PROCESS_AMOUNT
7	DWS_FIN_LOAN_ACCOUNT_D.RECEIVE_INCOME_REPAY_DEADLINE_AMOUNT
8	DWS_FIN_LOAN_ACCOUNT_D.RECEIVE_INCOME_PROCESS_DEADLINE_AMOUNT

13.03 mins

