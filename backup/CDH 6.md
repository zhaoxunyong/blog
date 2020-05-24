CDH 6
准备环境：
https://www.staroon.dev/2017/11/05/SetEnv/
https://blog.csdn.net/LCYong_/article/details/82385668

sudo mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
sudo mv /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup

sudo vim /etc/yum.repos.d/epel.repo
[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/$basearch
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - $basearch - Debug
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/$basearch/debug
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 7 - $basearch - Source
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/SRPMS
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

sudo yum install -y htop

资源配置：
https://docs.cloudera.com/documentation/enterprise/6/latest/topics/cm_ig_host_allocations.html#concept_f43_j4y_dw__section_icy_mgj_ndb
https://docs.cloudera.com/documentation/enterprise/release-notes/topics/hardware_requirements_guide.html
https://docs.cloudera.com/cdpdc/7.0/release-guide/topics/cdpdc-hardware-requirements.html

#Working all
sudo su -
echo "vm.swappiness = 10" >> /etc/sysctl.conf
sysctl -p

echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo never > /sys/kernel/mm/transparent_hugepage/enabled

echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled"  >> /etc/rc.local

#Working on all nodes
sudo su - hadoop
ssh-keygen -t rsa
#直接写入到nna的~/.ssh/authorized_keys中：
ssh-copy-id -i ~/.ssh/id_rsa.pub hadoop@nna
#cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
sudo chmod 700 ~/.ssh
sudo chmod 600 ~/.ssh/authorized_keys
并复制到所有机器
scp ~/.ssh/authorized_keys hadoop@nns:~/.ssh/
...

#sudo grep 'sshd' /var/log/secure | grep 'Authentication refused' | tail -5
#Authentication refused: bad ownership or modes for directory


NTP:
#https://www.staroon.dev/2017/11/05/SetEnv/#%E9%85%8D%E7%BD%AEntp%E6%97%B6%E9%97%B4%E5%90%8C%E6%AD%A5
https://blog.csdn.net/u010514380/article/details/88083139
#Working on nna
sudo systemctl disable chronyd.service
sudo systemctl stop chronyd.service
sudo yum -y install ntp
sudo timedatectl set-timezone Asia/Shanghai
sudo vim /etc/ntp.conf
restrict 0.0.0.0 mask 0.0.0.0 nomodify notrap
server 127.127.1.0
fudge  127.127.1.0 stratum 10
#server 0.centos.pool.ntp.org iburst
#server 1.centos.pool.ntp.org iburst
#server 2.centos.pool.ntp.org iburst
#server 3.centos.pool.ntp.org iburst

sudo systemctl enable ntpd.service
sudo systemctl start ntpd.service


#Working on others nodes
sudo systemctl disable chronyd.service
sudo systemctl stop chronyd.service
sudo yum -y install ntp
sudo timedatectl set-timezone Asia/Shanghai
sudo vim /etc/ntp.conf
#server 0.centos.pool.ntp.org iburst
#server 1.centos.pool.ntp.org iburst
#server 2.centos.pool.ntp.org iburst
#server 3.centos.pool.ntp.org iburst
server nna

sudo systemctl enable ntpd.service
sudo systemctl start ntpd.service
#在其它节点上手动同步master1的时间
sudo ntpdate -u nna
sudo ntpstat

Important: NFS Gateway/Hive Gateway/Spark Gateway：all nodes

nna:  8G/4C
nns:  16G/4C
dn1:  8G/12C
dn2:  8G/12C
dn3:  8G/12C
kylin: 16G/8C

HDFS: 
NFS Gateway: all nodes
DataNode: dn1/dn2/dn3
NameNode: nna
SecondaryNameNode/Balancer: nns

YARN:
ResourceManager: nna
JobHisotry Server: nna
NodeManager: the same as hdfs datanodes

Zookeeper:
Server: nna

Hive:
Gateway: all nodes
Metastore Server/HiveServer2: nns

Spark:
Gateway: all nodes
History Server: nna

Sqoop1:
Gateway: all nodes


https://www.staroon.dev/2018/12/01/CDH6Install/
#下载安装包：
https://archive.cloudera.com/cdh6/6.1.1/parcels/
https://archive.cloudera.com/cm6/6.1.1/redhat7/yum/RPMS/x86_64/

#repo方式安装：
wget https://archive.cloudera.com/cm6/6.1.1/allkeys.asc -P /Developer/Kylin/cloudera-repos/cm6/6.1.1/
wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/gplextras6/6.1.1/redhat7/ -P /Developer/Kylin/cloudera-repos
wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/cdh6/6.1.1/redhat7/ -P /Developer/Kylin/cloudera-repos
wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/cm6/6.1.1/redhat7/ -P /Developer/Kylin/cloudera-repos

wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/cdh6/6.1.1/parcels/ -P /Developer/Kylin/cloudera-repos

mv /Developer/Kylin/cloudera-repos /Developer/Kylin/
cd /Developer/Kylin/
#python -m SimpleHTTPServer 8900
#http-server -p8900
python3 -m http.server 8900
sudo su -

yum remove epel-release -y

cat > /etc/yum.repos.d/cloudera-repo.repo << EOF
[cloudera-repo]
name=cloudera-repo
baseurl=http://192.168.80.196:8900/cloudera-repos/cm6/6.1.1/redhat7/yum/
enabled=1
gpgcheck=0 
EOF

cat > /etc/yum.repos.d/cloudera-repo-cdh.repo << EOF
[cloudera-repo-cdh]
name=cloudera-repo-cdh
baseurl=http://192.168.80.196:8900/cloudera-repos/cdh6/6.1.1/redhat7/yum/
enabled=1
gpgcheck=0
EOF

yum clean all
yum makecache
#Working on all nodes
sudo yum install oracle-j2sdk1.8 -y
sudo yum install cloudera-manager-daemons cloudera-manager-agent -y

#Working on nns
sudo yum install cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server -y

------------------------------------
手动安装：(可选安装方式，建议)
#Working on all nodes
cd /vagrant/CDH/6/rpm/
sudo rpm -ivh oracle-j2sdk1.8-1.8.0+update181-1.x86_64.rpm

#cloudera-scm-server
#Working on all nodes
sudo rpm -ivh cloudera-manager-daemons-6.1.1-853290.el7.x86_64.rpm
sudo yum localinstall cloudera-manager-agent-6.1.1-853290.el7.x86_64.rpm -y

#Working on nns
sudo rpm -ivh cloudera-manager-server-6.1.1-853290.el7.x86_64.rpm
-------------------------------------

#Working on nns
sudo cp -a /vagrant/CDH/6/parcel-repo/* /opt/cloudera/parcel-repo/
sudo chown -R cloudera-scm:cloudera-scm /opt/cloudera/parcel-repo/
<!-- sudo mv CDH-6.1.1-1.cdh6.1.1.p0.875250-el7.parcel.sha256 CDH-6.1.1-1.cdh6.1.1.p0.875250-el7.parcel.sha
sha1sum CDH-6.1.1-1.cdh6.1.1.p0.875250-el7.parcel
修改manifest.json中的hash与.sha文件中的值为sha1sum计算出来的值 -->

Mysql:
https://blog.csdn.net/u010514380/article/details/88083139

#Working on nns:
cd /vagrant/CDH/mysql
sudo yum localinstall *.rpm -y

#启动MySQL
sudo systemctl start mysqld
#查看初始密码
sudo grep 'temporary password' /var/log/mysqld.log
#通过初始密码登陆
mysql -uroot -p
#修改root用户的密码
ALTER USER 'root'@'localhost' IDENTIFIED BY 'Aa123#@!';

#https://docs.cloudera.com/documentation/enterprise/6/6.3/topics/cm_ig_mysql.html#cmig_topic_5_5
服务名	                             数据库名	  用户名
Cloudera Manager Server	            scm	      scm
Activity Monitor	                  amon	    amon
Reports Manager	                    rman	    rman
Hive Metastore Server	              metastore	metastore
Hue	                                hue	      hue
Sentry Server	                      sentry	  sentry
Cloudera Navigator Audit Server	    nav	      nav
Cloudera Navigator Metadata Server	navms	    navms
Oozie	                              oozie	    oozie

CREATE DATABASE scm DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE amon DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE rman DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE hue DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE metastore DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE sentry DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE nav DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE navms DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE oozie DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

GRANT ALL ON scm.* TO 'scm'@'%' IDENTIFIED BY 'Aa123#@!';
GRANT ALL ON amon.* TO 'amon'@'%' IDENTIFIED BY 'Aa123#@!';
GRANT ALL ON rman.* TO 'rman'@'%' IDENTIFIED BY 'Aa123#@!';
GRANT ALL ON hue.* TO 'hue'@'%' IDENTIFIED BY 'Aa123#@!';
GRANT ALL ON metastore.* TO 'metastore'@'%' IDENTIFIED BY 'Aa123#@!';
GRANT ALL ON sentry.* TO 'sentry'@'%' IDENTIFIED BY 'Aa123#@!';
GRANT ALL ON nav.* TO 'nav'@'%' IDENTIFIED BY 'Aa123#@!';
GRANT ALL ON navms.* TO 'navms'@'%' IDENTIFIED BY 'Aa123#@!';
GRANT ALL ON oozie.* TO 'oozie'@'%' IDENTIFIED BY 'Aa123#@!';
FLUSH PRIVILEGES;
exit

#Working on all
sudo mkdir -p /usr/share/java/
sudo cp -a /vagrant/CDH/mysql-connector-java-5.1.48-bin.jar /usr/share/java/mysql-connector-java.jar
sudo cp -a /vagrant/CDH/mysql-connector-java-5.1.48-bin.jar /opt/cloudera/cm/lib/mysql-connector-java.jar

#Working on nns
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql amon amon Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql rman rman Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql hue hue Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql metastore metastore Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql sentry sentry Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql nav nav Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql navms navms Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql oozie oozie Aa123#@!

sudo systemctl enable cloudera-scm-server
sudo systemctl start cloudera-scm-server
#第一次启动会很慢
sudo tail -n100 -f /var/log/cloudera-scm-server/cloudera-scm-server.log

#Working on all nodes
sudo sed -i "s;server_host=localhost;server_host=nns;g" /etc/cloudera-scm-agent/config.ini
sudo systemctl enable cloudera-scm-agent
sudo systemctl start cloudera-scm-agent
sudo tail -n100 -n100 -f /var/log/cloudera-scm-agent/cloudera-scm-agent.log

http://nns:7180


## Standalone HBase
https://hbase.apache.org/book.html#quickstart
Using hbase 2.0.0 and login with hdfs:
hbase-site.xml
<configuration>
  <property>
    <name>hbase.rootdir</name>
    <value>file:///data/hbase</value>
  </property>
  <property>
    <name>hbase.zookeeper.property.dataDir</name>
    <value>/data/hbase/zookeeper</value>
  </property>
  <property>
    <name>hbase.unsafe.stream.capability.enforce</name>
    <value>false</value>
    <description>
      Controls whether HBase will check for stream capabilities (hflush/hsync).

      Disable this if you intend to run on LocalFileSystem, denoted by a rootdir
      with the 'file://' scheme, but be mindful of the NOTE below.

      WARNING: Setting this to false blinds you to potential data loss and
      inconsistent system state in the event of process and/or node failures. If
      HBase is complaining of an inability to use hsync or hflush it's most
      likely not a false positive.
    </description>
  </property>
</configuration>

cat /etc/profile.d/java.sh 
export JAVA_HOME=/usr/java/jdk1.8.0_181-cloudera
export PATH=$JAVA_HOME/bin:$PATH

cat /etc/profile.d/kylin.sh 
export KYLIN_HOME=/works/kylin-3.0.2
export PATH=$KYLIN_HOME/bin:$PATH

cat /etc/profile.d/spark.sh 
export SPARK_HOME=/opt/cloudera/parcels/CDH/lib/spark/
export PATH=$SPARK_HOME/bin:$PATH

#Using hadoop account:
sudo mkdir -p /data/hbase
sudo chown -R hadoop:hadoop /data/hbase

start-hbase.sh 
hbase shell
create 'game_x_tmp', '_x'
put 'game_x_tmp', 'rowkey1', '_x', 'v1'
scan 'game_x_tmp'
disable 'game_x_tmp'
drop 'game_x_tmp'

echo "xxx" > hello.txt
#上传本地文件到分布式文件系统中的 tmp 目录
hdfs dfs -mkdir /works/
hdfs dfs -ls /works/
hdfs dfs -put hello.txt /works/hello.txt
hdfs dfs -cat /works/hello.txt
#下载分布式文件系统中 tmp 目录下的 hello.txt 文件本地当前目录
hdfs dfs -get /works/hello.txt ./
#删除分布式文件系统中 tmp 目录下的 hello.txt 文f~:
hdfs dfs -rm -r /works/hello.txt

>spark-shell
var lines=sc.textFile("/works/hello.txt")
lines.count()

Kylin:
mkdir -p /works/kylin-3.0.2/ext/
cp -a /vagrant/CDH/mysql-connector-java-5.1.48-bin.jar $KYLIN_HOME/ext/
cp -a /vagrant/CDH/mysql-connector-java-5.1.48-bin.jar /opt/cloudera/parcels/CDH/lib/sqoop/lib/

SQOOP:
#Testing
sqoop list-databases --connect jdbc:mysql://192.168.80.196:3306 \
--username root --password Gk97TU6coSsvtipC9SB2

vim $KYLIN_HOME/conf/kylin.properties:
kylin.source.default=8
kylin.source.jdbc.connection-url=jdbc:mysql://192.168.80.196:3306/dwh?dontTrackOpenResources=true&defaultFetchSize=1000&useCursorFetch=true
kylin.source.jdbc.driver=com.mysql.jdbc.Driver
kylin.source.jdbc.dialect=mysql
kylin.source.jdbc.user=root
kylin.source.jdbc.pass=Gk97TU6coSsvtipC9SB2
kylin.source.jdbc.sqoop-home=/opt/cloudera/parcels/CDH/lib/sqoop
kylin.source.jdbc.filed-delimiter=|
注意：修改以上jdbc配置，job需要删除并重新创建才能生效

kylin.engine.spark-conf.spark.master=yarn
kylin.engine.spark-conf.spark.submit.deployMode=cluster
kylin.engine.spark-conf.spark.dynamicAllocation.enabled=true
kylin.engine.spark-conf.spark.dynamicAllocation.minExecutors=1
kylin.engine.spark-conf.spark.dynamicAllocation.maxExecutors=1000
kylin.engine.spark-conf.spark.dynamicAllocation.executorIdleTimeout=300
kylin.engine.spark-conf.spark.yarn.queue=default
kylin.engine.spark-conf.spark.driver.memory=2G
kylin.engine.spark-conf.spark.executor.memory=4G
kylin.engine.spark-conf.spark.yarn.executor.memoryOverhead=1024
kylin.engine.spark-conf.spark.executor.cores=6
kylin.engine.spark-conf.spark.network.timeout=600
kylin.engine.spark-conf.spark.shuffle.service.enabled=true
#kylin.engine.spark-conf.spark.executor.instances=1
kylin.engine.spark-conf.spark.eventLog.enabled=true
kylin.engine.spark-conf.spark.hadoop.dfs.replication=2
kylin.engine.spark-conf.spark.hadoop.mapreduce.output.fileoutputformat.compress=true
kylin.engine.spark-conf.spark.hadoop.mapreduce.output.fileoutputformat.compress.codec=org.apache.hadoo
p.io.compress.DefaultCodec
kylin.engine.spark-conf.spark.io.compression.codec=org.apache.spark.io.SnappyCompressionCodec
kylin.engine.spark-conf.spark.eventLog.dir=hdfs\://nna:8020/kylin/spark-history
kylin.engine.spark-conf.spark.history.fs.logDirectory=hdfs\://nna:8020/kylin/spark-history
kylin.env.hadoop-conf-dir=/etc/hadoop/conf
----------------

修改hdfs任何用户可以写入：
https://blog.csdn.net/Ahuuua/article/details/90669011
1、找到hdfs-site.xml 的 HDFS 服务高级配置代码段（安全阀）
2、添加这个，保存更改，重启hdfs
dfs.permissions.enabled 的值设置为false

The required MAP capability is more than the supported max container capability in the cluster
https://blog.csdn.net/weixin_33766168/article/details/93405662
https://www.cnblogs.com/yako/p/5498168.html
mapreduce.map.memory.mb=2G
apreduce.reduce.memory.mb=3G
yarn.scheduler.minimum-allocation-mb=2G

arn.scheduler.maximum-allocation-mb=6G

yarn.scheduler.minimum-allocation-vcores=4
yarn.scheduler.maximum-allocation-vcores=12

#https://www.cnblogs.com/missie/p/4370135.html
#表示该节点上YARN可使用的物理内存总量，默认是8192（MB），注意，如果你的节点内存资源不够8GB，则需要调减小这个值，而YARN不会智能的探测节点的物理内存总量。
yarn.nodemanager.resource.memory-mb=5G
#单个任务可申请的最多物理内存量，默认是8192（MB）。
yarn.scheduler.maximum-allocation-mb=4G

kylin_hadoop_conf_dir is empty, check if there's error in the output of 'kylin.sh start'
在 kylin.properties 中设置属性 “kylin.env.hadoop-conf-dir” 好让 Kylin 知道这个目录:
kylin.env.hadoop-conf-dir=/etc/hadoop/conf



ExecutorLostFailure (executor 1 exited caused by one of the running tasks) Reason: Container killed by YARN for exceeding memory limits. 5.0 GB of 5 GB physical memory used. Consider boosting spark.yarn.executor.memoryOverhead or disabling yarn.nodemanager.vmem-check-enabled because of YARN-4714.

Exception in thread "main" java.lang.IllegalArgumentException: Required executor memory (4096), overhead (4096 MB), and PySpark memory (0 MB) is above the max threshold (6144 MB) of this cluster! Please check the values of 'yarn.scheduler.maximum-allocation-mb' and/or 'yarn.nodemanager.resource.memory-mb'.

kylin.engine.spark-conf.spark.driver.memory=1G
kylin.engine.spark-conf.spark.executor.memory=2G
#kylin.engine.spark-conf.spark.yarn.executor.memoryOverhead=1024
kylin.engine.spark-conf.spark.executor.cores=6

oozie:
https://www.cnblogs.com/yinzhengjie/p/10934172.html
https://blog.csdn.net/adshiye/article/details/84311890

Failed to install Oozie ShareLib:
cpu core not greate than..
此时已经创建了oozie，新开一个窗口修改core后，再在此页面点击resume.

hue:
https://blog.csdn.net/gao123456789amy/article/details/79242713
hue的时区zone修改为：
Asia/Shanghai
http://nns:8889

cp -a /vagrant/CDH/mysql-connector-java-5.1.48-bin.jar /opt/cloudera/parcels/CDH/lib/sqoop/lib/

sqoop import-all-tables \
             --connect jdbc:mysql://192.168.80.196:3306/dwh \
             --username root \
             --password Gk97TU6coSsvtipC9SB2 \
             --hive-import \
             --hive-database dwh \
             --exclude-tables dim_client,dim_collection_status,dim_date,dim_loan_account,dim_loan_account_process_status,dim_loan_account_status,dim_loan_account_type,dim_loan_bill,dim_loan_product,dim_loan_type,dim_repay_amount_type,dim_source_system,dim_trading_summary,dim_virtual_center,dws_fin_exempt,dws_fin_loan_account_d,temp \
             --num-mappers 1 \
             --verbose

sqoop list-databases --connect jdbc:mysql://192.168.80.196:3306 --username root --password Gk97TU6coSsvtipC9SB2