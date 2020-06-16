CDH 6
准备环境：
https://www.staroon.dev/2017/11/05/SetEnv/
https://blog.csdn.net/LCYong_/article/details/82385668

资源配置：
https://docs.cloudera.com/documentation/enterprise/6/latest/topics/cm_ig_host_allocations.html#concept_f43_j4y_dw__section_icy_mgj_ndb
https://docs.cloudera.com/documentation/enterprise/6/release-notes/topics/rg_hardware_requirements.html
5.x
https://docs.cloudera.com/documentation/enterprise/release-notes/topics/hardware_requirements_guide.html
https://docs.cloudera.com/cdpdc/7.0/release-guide/topics/cdpdc-hardware-requirements.html

#Working all

#Not necessary
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

nna:  12G/4C
nns:  16G/8C
dn1:  16G/16C
dn2:  16G/16C
dn3:  16G/16C
dn4:  16G/16C
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

cat > /etc/yum.repos.d/cloudera-repo.repo << EOF
[cloudera-repo]
name=cloudera-repo
baseurl=http://192.168.80.98:8900/cloudera-repos/cm6/6.1.1/redhat7/yum/
enabled=1
gpgcheck=0 
EOF

cat > /etc/yum.repos.d/cloudera-repo-cdh.repo << EOF
[cloudera-repo-cdh]
name=cloudera-repo-cdh
baseurl=http://192.168.80.98:8900/cloudera-repos/cdh6/6.1.1/redhat7/yum/
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
cd /cdh/CDH/6/rpm/
sudo rpm -ivh oracle-j2sdk1.8-1.8.0+update181-1.x86_64.rpm

#cloudera-scm-agent
#Working on all nodes
sudo rpm -ivh cloudera-manager-daemons-6.1.1-853290.el7.x86_64.rpm
sudo yum localinstall cloudera-manager-agent-6.1.1-853290.el7.x86_64.rpm -y

#cloudera-scm-server
#Working on nns
sudo rpm -ivh cloudera-manager-server-6.1.1-853290.el7.x86_64.rpm
-------------------------------------

#Working on cloudera-scm-server
sudo cp -a /cdh/CDH/6/parcel-repo/* /opt/cloudera/parcel-repo/
sudo chown -R cloudera-scm:cloudera-scm /opt/cloudera/parcel-repo/
<!-- sudo mv CDH-6.1.1-1.cdh6.1.1.p0.875250-el7.parcel.sha256 CDH-6.1.1-1.cdh6.1.1.p0.875250-el7.parcel.sha
sha1sum CDH-6.1.1-1.cdh6.1.1.p0.875250-el7.parcel
修改manifest.json中的hash与.sha文件中的值为sha1sum计算出来的值 -->

Mysql:
https://blog.csdn.net/u010514380/article/details/88083139

#Working on nns:
cd /cdh/CDH/mysql
sudo yum localinstall *.rpm -y

#启动MySQL
sudo systemctl enable mysqld
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
#grant all privileges on *.* to root@'%' identified by 'Aa123#@!' WITH GRANT OPTION;
FLUSH PRIVILEGES;
exit

#Working on all
sudo mkdir -p /usr/share/java/
sudo cp -a /cdh/CDH/mysql-connector-java-5.1.48-bin.jar /usr/share/java/mysql-connector-java.jar
sudo cp -a /cdh/CDH/mysql-connector-java-5.1.48-bin.jar /opt/cloudera/cm/lib/mysql-connector-java.jar

#Working on nns
#scm_prepare_database.sh mysql  -uroot -p --scm-host localhost scm scm scm_password
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql -h192.168.80.98 -p6Aq2FuMVvWzsEFeJ4p84ctiwM scm scm Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql -h192.168.80.98 -p6Aq2FuMVvWzsEFeJ4p84ctiwM amon amon Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql -h192.168.80.98 -p6Aq2FuMVvWzsEFeJ4p84ctiwM rman rman Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql -h192.168.80.98 -p6Aq2FuMVvWzsEFeJ4p84ctiwM hue hue Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql -h192.168.80.98 -p6Aq2FuMVvWzsEFeJ4p84ctiwM metastore metastore Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql -h192.168.80.98 -p6Aq2FuMVvWzsEFeJ4p84ctiwM sentry sentry Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql -h192.168.80.98 -p6Aq2FuMVvWzsEFeJ4p84ctiwM nav nav Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql -h192.168.80.98 -p6Aq2FuMVvWzsEFeJ4p84ctiwM navms navms Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql -h192.168.80.98 -p6Aq2FuMVvWzsEFeJ4p84ctiwM oozie oozie Aa123#@!

sudo systemctl enable cloudera-scm-server
sudo systemctl start cloudera-scm-server
#第一次启动会很慢
sudo tail -n100 -f /var/log/cloudera-scm-server/cloudera-scm-server.log

#Working on all nodes
sudo sed -i "s;server_host=.*;server_host=nns;g" /etc/cloudera-scm-agent/config.ini
sudo systemctl enable cloudera-scm-agent
sudo systemctl start cloudera-scm-agent
sudo tail -n100 -n100 -f /var/log/cloudera-scm-agent/cloudera-scm-agent.log

http://nns:7180

<!-- sudo mkdir /data/
/data/hbase
/data/dfs/dn
/data/dfs/snn
/data/yarn/nm -->

## Kylin
sudo su -

groupadd kylin
useradd -m -g kylin kylin
passwd kylin
chmod +w /etc/sudoers

vim /etc/sudoers
#在 sudoers 文件中添加以下内容
echo "kylin ALL=(root)NOPASSWD: ALL" >> /etc/sudoers
#最后保存内容后退出,并取消 sudoers 文件的写权限
chmod -w /etc/sudoers

sudo su - kylin
sudo mkdir /works
sudo chown -R kylin:kylin /works
<!-- sudo mkdir -p /data/hbase
sudo chown -R kylin:kylin /data -->

cat > /etc/profile.d/kylin.sh << EOF
export JAVA_HOME=/usr/java/jdk1.8.0_181-cloudera
export SPARK_HOME=/opt/cloudera/parcels/CDH/lib/spark/
export HBASE_HOME=/opt/cloudera/parcels/CDH/lib/hbase/
export KYLIN_HOME=/works/kylin-3.0.2
export PATH=\$JAVA_HOME/bin:\$SPARK_HOME/bin:\$HBASE_HOME/bin:\$KYLIN_HOME/bin:$PATH
EOF

. /etc/profile

exit

cd /works
tar zxf apache-kylin-3.0.2-bin-cdh60.tar.gz
mv apache-kylin-3.0.2-bin-cdh60 kylin-3.0.2

mkdir /works/kylin-3.0.2/ext/
sudo cp -a /cdh/CDH/mysql-connector-java-5.1.48-bin.jar /works/kylin-3.0.2/ext/
sudo cp -a /cdh/CDH/mysql-connector-java-5.1.48-bin.jar /opt/cloudera/parcels/CDH/lib/sqoop/lib/

cp -a /cdh/commons-configuration-1.6.jar /works/kylin-3.0.2/tomcat/lib/

kylin_hadoop_conf_dir is empty, check if there's error in the output of 'kylin.sh start'
在 kylin.properties 中设置属性 “kylin.env.hadoop-conf-dir” 好让 Kylin 知道这个目录:
kylin.env.hadoop-conf-dir=/etc/hadoop/conf

java.lang.NoClassDefFoundError: org/apache/commons/configuration/ConfigurationException:
https://www.hotbak.net/key/NoClassDefFoundError%E9%94%99%E8%AF%AF%E7%9A%84%E8%A7%A3%E5%86%B3%E6%96%B9%E6%B3%95KylinKylin%E7%9A%84%E4%B8%93%E6%A0%8FCSDN%E5%8D%9A%E5%AE%A2.html
sudo find / -name "*commons-configuration*"


<!-- start-hbase.sh  -->
hbase shell
create 'game_x_tmp', '_x'
put 'game_x_tmp', 'rowkey1', '_x', 'v1'
scan 'game_x_tmp'
disable 'game_x_tmp'
drop 'game_x_tmp'

hive>
＃在创建数据库时添加判断，防止因创建的数据库己存在而抛出异常
CREATE DATABASE IF NOT EXISTS game; 
DROP DATABASE game;

修改hdfs任何用户可以写入：
https://blog.csdn.net/Ahuuua/article/details/90669011
1、找到hdfs-site.xml 的 HDFS 服务高级配置代码段（安全阀）
2、添加这个，保存更改，重启hdfs
HDFS Service Advanced Configuration Snippet (Safety Valve) for hdfs-site.xml中添加：
dfs.permissions.enabled 的值设置为false

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

Cannot run program "/etc/hadoop/conf.cloudera.yarn/topology.py"
#Working on dn4:
scp -r /etc/hadoop/conf.cloudera.yarn root@kylin1:/etc/hadoop/

check-env.sh 
kylin.sh start

http://kylin1:7070/kylin

oozie:
https://www.cnblogs.com/yinzhengjie/p/10934172.html
https://blog.csdn.net/adshiye/article/details/84311890

Failed to install Oozie ShareLib:
cpu core not greate than...
此时已经创建了oozie，新开一个窗口修改core后，再在此页面点击resume.

hue:
https://blog.csdn.net/gao123456789amy/article/details/79242713
hue的时区zone修改为：
Asia/Shanghai
http://nns:8889

SQOOP:
#Testing
sqoop list-databases --connect jdbc:mysql://192.168.80.98:3306 \
--username root --password 6Aq2FuMVvWzsEFeJ4p84ctiwM

grant all privileges on *.* to root@'%' identified by '6Aq2FuMVvWzsEFeJ4p84ctiwM' WITH GRANT OPTION;

vim $KYLIN_HOME/conf/kylin.properties:
kylin.source.default=8
kylin.source.jdbc.connection-url=jdbc:mysql://192.168.80.98:3306/dwh?dontTrackOpenResources=true&defaultFetchSize=1000&useCursorFetch=true
kylin.source.jdbc.driver=com.mysql.jdbc.Driver
kylin.source.jdbc.dialect=mysql
kylin.source.jdbc.user=root
kylin.source.jdbc.pass=6Aq2FuMVvWzsEFeJ4p84ctiwM
kylin.source.jdbc.sqoop-home=/opt/cloudera/parcels/CDH/lib/sqoop
kylin.source.jdbc.filed-delimiter=|

kylin.env.hadoop-conf-dir=/etc/hadoop/conf
kylin.job.mr.config.override.mapreduce.map.java.opts=-Xmx4g
kylin.job.mr.config.override.mapreduce.map.memory.mb=4500
kylin.job.mr.config.override.mapreduce.reduce.java.opts=-Xmx8g
kylin.job.mr.config.override.mapreduce.reduce.memory.mb=8500

kylin.job.mapreduce.mapper.input.rows=500000
kylin.job.mapreduce.default.reduce.input.mb=200
#kylin.hbase.region.cut=2
#kylin.hbase.hfile.size.gb=1
kylin.storage.hbase.region-cut-gb=2
kylin.storage.hbase.hfile-size-gb=1

kylin.cube.cubeplanner.enabled=true
kylin.server.query-metrics2-enabled=true
kylin.metrics.reporter-query-enabled=true
kylin.metrics.reporter-job-enabled=true
kylin.metrics.monitor-enabled=true

kylin.web.dashboard-enabled=true

kylin.job.notification-enabled=true
kylin.job.notification-mail-enable-starttls=true
kylin.job.notification-mail-host=smtp.exmail.qq.com
kylin.job.notification-mail-port=465
kylin.job.notification-mail-username=notify@zerofinance.com
kylin.job.notification-mail-password=NotAeasy8396*
kylin.job.notification-mail-sender=notify@zerofinance.com
kylin.job.notification-admin-emails=dave.zhao@zerofinance.com

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
kylin.engine.spark-conf.spark.executor.cores=1
kylin.engine.spark-conf.spark.network.timeout=600
kylin.engine.spark-conf.spark.shuffle.service.enabled=true
#kylin.engine.spark-conf.spark.executor.instances=1
kylin.engine.spark-conf.spark.eventLog.enabled=true
kylin.engine.spark-conf.spark.hadoop.dfs.replication=2
kylin.engine.spark-conf.spark.hadoop.mapreduce.output.fileoutputformat.compress=true
kylin.engine.spark-conf.spark.hadoop.mapreduce.output.fileoutputformat.compress.codec=org.apache.hadoo
p.io.compress.DefaultCodec
kylin.engine.spark-conf.spark.io.compression.codec=org.apache.spark.io.SnappyCompressionCodec
kylin.engine.spark-conf.spark.eventLog.dir=hdfs\://master1:8020/kylin/spark-history
kylin.engine.spark-conf.spark.history.fs.logDirectory=hdfs\://master1:8020/kylin/spark-history
----------------


The required MAP capability is more than the supported max container capability in the cluster
https://blog.csdn.net/weixin_33766168/article/details/93405662
https://www.cnblogs.com/yako/p/5498168.html
https://blog.csdn.net/z3935212/article/details/78637157?utm_medium=distribute.pc_relevant.none-task-blog-baidujs-9
说明：单个Map/Reduce task 申请的内存大小，其值应该在RM中的最大和最小container值之间。如果没有配置则通过如下简单公式获得：
max(MIN_CONTAINER_SIZE, (Total Available RAM) / containers))
一般reduce内存大小应该是map的2倍。注：这两个值可以在应用启动时通过参数改变，可以动态调整；

#https://blog.csdn.net/u014665013/article/details/80923044
#https://blog.csdn.net/z3935212/article/details/78637157?utm_medium=distribute.pc_relevant.none-task-blog-baidujs-9
#https://blog.csdn.net/mamls/article/details/68941800
#https://www.cnblogs.com/missie/p/4370135.html

#就是你的这台服务器节点上准备分给yarn的内存
yarn.nodemanager.resource.memory-mb=20G（default: the maxnuim of the pysyical machine）

#单个任务可申请的最多物理内存量，默认是8192（MB）
yarn.scheduler.minimum-allocation-mb=1G
#单个任务可申请的最多物理内存量，默认是8192（MB）
yarn.scheduler.maximum-allocation-mb=20G

#单个map任务申请内存资源,一般reduce内存大小应该是map的2倍
#mapreduce.map.memory.mb=4G（default: 0）
#mapreduce.reduce.memory.mb=8G（default: 0）

#https://www.jianshu.com/p/d49135b0559f
#表示该节点服务器上yarn可以使用的虚拟的CPU个数
yarn.nodemanager.resource.cpu-vcores=14
#表示单个任务最小可以申请的虚拟核心数，默认为1
yarn.scheduler.minimum-allocation-vcores=1
#表示单个任务最大可以申请的虚拟核数，默认为4；如果申请资源时，超过这个配置，会抛出 InvalidResourceRequestException
yarn.scheduler.maximum-allocation-vcores=14
#cpu分配不平衡
yarn.scheduler.fair.maxassign=4

清理空间：
http://kylin.apache.org/cn/docs/howto/howto_cleanup_storage.html
${KYLIN_HOME}/bin/kylin.sh org.apache.kylin.tool.StorageCleanupJob --delete false
${KYLIN_HOME}/bin/kylin.sh org.apache.kylin.tool.StorageCleanupJob --delete true

如果您想要删除所有资源；可添加 “–force true” 选项：
${KYLIN_HOME}/bin/kylin.sh org.apache.kylin.tool.StorageCleanupJob --force true --delete true
https://www.csdn.net/gather_26/MtTaEgzsMjI1MC1ibG9n.html
https://www.cnblogs.com/sellsa/p/10212620.html
metastore.sh clean
metastore.sh clean --delete true
kylin.sh storage cleanup
kylin.sh storage cleanup --delete true
hdfs dfs -du -h /hbase/archive/data/default
hdfs dfs -rm -r -skipTrash /hbase/archive/data/default/*
hdfs dfs -expunge

#cpu分配不平衡：
https://blog.csdn.net/nazeniwaresakini/article/details/105137788
yarn.scheduler.fair.maxassign=4

ExecutorLostFailure (executor 1 exited caused by one of the running tasks) Reason: Container killed by YARN for exceeding memory limits. 5.0 GB of 5 GB physical memory used. Consider boosting spark.yarn.executor.memoryOverhead or disabling yarn.nodemanager.vmem-check-enabled because of YARN-4714.

Exception in thread "main" java.lang.IllegalArgumentException: Required executor memory (4096), overhead (4096 MB), and PySpark memory (0 MB) is above the max threshold (6144 MB) of this cluster! Please check the values of 'yarn.scheduler.maximum-allocation-mb' and/or 'yarn.nodemanager.resource.memory-mb'.

Cube优化：
kylin.sh org.apache.kylin.engine.mr.common.CubeStatsReader dwh_cube

https://www.jianshu.com/p/fb1d690dc19a
kylin的默认设置中

kylin.storage.hbase.region-cut-gb=5
kylin.storage.hbase.min-region-count=1
kylin.storage.hbase.max-region-count=500
优化
kylin.storage.hbase.region-cut-gb=1
kylin.storage.hbase.min-region-count=2
kylin.storage.hbase.max-region-count=100
Spark:
kylin.engine.spark.rdd-partition-cut-mb=500

备份还还原元数据：
metastore.sh backup
metastore.sh restore /works/kylin-3.0.2/meta_backups/meta_2020_06_11_16_27_05
在web UI上单击"Reload Metadata"对元数据缓存进行刷新

<!-- kylin spark Container killed on request. Exit code is 143
https://blog.csdn.net/yijichangkong/article/details/51332432 -->

## 配置：
kylin_hive_conf.xml 
    <property>
      <name>hive.optimize.skewjoin</name>
      <value>true</value>
    </property>
    <property>
      <name>hive.groupby.skewindata</name>
      <value>true</value>
    </property>
    <property>
      <name>mapred.reduce.child.java.opts</name>
      <value>-Xmx2g</value>
    </property>
    <property>
      <name>mapred.map.tasks</name>
      <value>20</value>
    </property>
    <property>
      <name>mapred.reduce.tasks</name>
      <value>40</value>
    </property>
    <property>
      <name>hive.auto.convert.join</name>
      <value>true</value>
    </property>

kylin_job_conf_cube_merge.xml
    <!--Additional config for in-mem cubing, giving mapper more memory -->
    <property>
        <name>mapreduce.map.memory.mb</name>
        <value>4500</value>
        <description></description>
    </property>

    <property>
        <name>mapreduce.map.java.opts</name>
        <value>-Xmx4g -XX:OnOutOfMemoryError='kill -9 %p'</value>
        <description></description>
    </property>

    <property>
        <name>mapreduce.reduce.memory.mb</name>
        <value>8500</value>
        <description></description>
    </property>

    <property>
        <name>mapreduce.reduce.java.opts</name>
        <value>-Xmx8g -XX:OnOutOfMemoryError='kill -9 %p'</value>
        <description></description>
    </property>

    <property>
        <name>mapreduce.task.io.sort.mb</name>
        <value>200</value>
        <description></description>
    </property>

kylin_job_conf_inmem.xml
    <!--Additional config for in-mem cubing, giving mapper more memory -->
    <property>
        <name>mapreduce.map.memory.mb</name>
        <value>4500</value>
        <description></description>
    </property>

    <property>
        <name>mapreduce.map.java.opts</name>
        <value>-Xmx4g -XX:OnOutOfMemoryError='kill -9 %p'</value>
        <description></description>
    </property>

    <property>
        <name>mapreduce.reduce.memory.mb</name>
        <value>8500</value>
        <description></description>
    </property>

    <property>
        <name>mapreduce.reduce.java.opts</name>
        <value>-Xmx8g -XX:OnOutOfMemoryError='kill -9 %p'</value>
        <description></description>
    </property>

    <property>
        <name>mapreduce.task.io.sort.mb</name>
        <value>200</value>
        <description></description>
    </property>

---------------------
## Standalone HBase
#Using hadoop account:
sudo mkdir /works
sudo chown -R kylin:kylin /works
sudo mkdir -p /data/hbase
sudo chown -R kylin:kylin /data/hbase
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

#Starting hbase
start-hbase.sh 
<!-- Testing  -->
hbase shell
create 'game_x_tmp', '_x'
put 'game_x_tmp', 'rowkey1', '_x', 'v1'
scan 'game_x_tmp'
disable 'game_x_tmp'
drop 'game_x_tmp'

<!-- sqoop import-all-tables \
             --connect jdbc:mysql://192.168.80.98:3306/dwh \
             --username root \
             --password 6Aq2FuMVvWzsEFeJ4p84ctiwM \
             --hive-import \
             --hive-database dwh \
             --exclude-tables dim_client,dim_collection_status,dim_date,dim_loan_account,dim_loan_account_process_status,dim_loan_account_status,dim_loan_account_type,dim_loan_bill,dim_loan_product,dim_loan_type,dim_repay_amount_type,dim_source_system,dim_trading_summary,dim_virtual_center,dws_fin_exempt,dws_fin_loan_account_d,temp \
             --num-mappers 1 \
             --verbose -->

sqoop list-databases --connect jdbc:mysql://192.168.80.98:3306 --username root --password 6Aq2FuMVvWzsEFeJ4p84ctiwM

dwh.dws_fin_loan_account_d,dwh.dim_date

SELECT min(snap_date_key), max(snap_date_key) FROM dwh.dws_fin_loan_account_d  WHERE dws_fin_loan_account_d.snap_date_key >= '2020-01-01' AND dws_fin_loan_account_d.snap_date_key < '2020-04-30'

SELECT dws_fin_loan_account_d.snap_date_key as SNAP_DATE_KEY, 
sum(DWS_FIN_LOAN_ACCOUNT_D.principal_repay_balance_amount) as principal_repay_balance_amount, 
sum(DWS_FIN_LOAN_ACCOUNT_D.principal_repay_balance_irr_amount) as principal_repay_balance_irr_amount, 
sum(DWS_FIN_LOAN_ACCOUNT_D.principal_process_balance_amount) as principal_process_balance_amount,
sum(DWS_FIN_LOAN_ACCOUNT_D.principal_process_balance_irr_amount) as principal_process_balance_irr_amount,
sum(DWS_FIN_LOAN_ACCOUNT_D.receive_repay_income_amount) as receive_repay_income_amount,
sum(DWS_FIN_LOAN_ACCOUNT_D.receive_process_income_amount) as receive_process_income_amount,
sum(DWS_FIN_LOAN_ACCOUNT_D.receive_repay_income_deadline_amount) as receive_repay_income_deadline_amount,
sum(DWS_FIN_LOAN_ACCOUNT_D.receive_process_income_deadline_amount) as receive_process_income_deadline_amount
FROM dwh.dws_fin_loan_account_d  
WHERE dws_fin_loan_account_d.snap_date_key >= '2013-01-01' 
AND dws_fin_loan_account_d.snap_date_key < '2020-04-30' 
GROUP BY dws_fin_loan_account_d.snap_date_key

SELECT dws_fin_loan_account_d.snap_date_key as SNAP_DATE_KEY, 
sum(DWS_FIN_LOAN_ACCOUNT_D.principal_repay_balance_amount) as principal_repay_balance_amount, 
sum(DWS_FIN_LOAN_ACCOUNT_D.principal_repay_balance_irr_amount) as principal_repay_balance_irr_amount, 
sum(DWS_FIN_LOAN_ACCOUNT_D.principal_process_balance_amount) as principal_process_balance_amount,
sum(DWS_FIN_LOAN_ACCOUNT_D.principal_process_balance_irr_amount) as principal_process_balance_irr_amount,
sum(DWS_FIN_LOAN_ACCOUNT_D.receive_repay_income_amount) as receive_repay_income_amount,
sum(DWS_FIN_LOAN_ACCOUNT_D.receive_process_income_amount) as receive_process_income_amount,
sum(DWS_FIN_LOAN_ACCOUNT_D.receive_repay_income_deadline_amount) as receive_repay_income_deadline_amount,
sum(DWS_FIN_LOAN_ACCOUNT_D.receive_process_income_deadline_amount) as receive_process_income_deadline_amount
FROM dwh.dws_fin_loan_account_d dws_fin_loan_account_d 
INNER JOIN dwh.dim_date dim_date ON dws_fin_loan_account_d.snap_date_key = dim_date.date_key 
WHERE 1=1 
AND (dws_fin_loan_account_d.snap_date_key >= '2013-01-01' 
AND dws_fin_loan_account_d.snap_date_key < '2020-04-30')
GROUP BY dws_fin_loan_account_d.snap_date_key

                 mapreducer/spark
smaple_dwh_cube: 4.37 mins-5.00 KB/4.18 mins-5.00 KB
dwh_cube:        71.45(65.58)mins-12.21 GB/


Kylin Dashboard:
http://kylin.apache.org/cn/docs/tutorial/setup_systemcube.html
kylin.sh org.apache.kylin.tool.metrics.systemcube.SCCreator -inputConfig /works/kylin-3.0.2/SCSinkTools.json -output /data/kylin/
hive -f /data/kylin/create_hive_tables_for_system_cubes.sql
metastore.sh restore /data/kylin/

system-cube.sh setup
system-cube.sh build
system-cube.sh cron

修改kylin密码：
https://w3sun.com/210.html
http://kylin.apache.org/cn/docs/gettingstarted/faq.html
cd $KYLIN_HOME/tomcat/webapps/kylin/WEB-INF/lib
java -classpath kylin-server-base-3.0.2.jar:spring-beans-4.3.10.RELEASE.jar:spring-core-4.3.10.RELEASE.jar:spring-security-core-4.2.3.RELEASE.jar:commons-codec-1.7.jar:commons-logging-1.1.1.jar:kylin-cache-3.0.2.jar org.apache.kylin.rest.security.PasswordPlaceholderConfigurer BCrypt "Aa123456"

vi $KYLIN_HOME/tomcat/webapps/kylin/WEB-INF/classes/kylinSecurity.xml中ADMIN的密码并重启
#drop database if exists dwh cascade; 
#CREATE DATABASE IF NOT EXISTS game; 

删除旧有database并创建新的：
hive -e "DROP DATABASE dwh cascade;
CREATE DATABASE dwh;
" --hiveconf hive.merge.mapredfiles=false --hiveconf hive.auto.convert.join=true --hiveconf dfs.replication=2 --hiveconf hive.exec.compress.output=true --hiveconf hive.auto.convert.join.noconditionaltask=true --hiveconf mapreduce.job.split.metainfo.maxsize=-1 --hiveconf hive.merge.mapfiles=false --hiveconf hive.auto.convert.join.noconditionaltask.size=100000000 --hiveconf hive.stats.autogather=true

#https://stackoverflow.com/questions/54760995/sqoop-import-data-to-hive-and-hdfs
导入所有的表（排除个别表）
sqoop import-all-tables \
--connect "jdbc:mysql://192.168.80.98:3306/dwh?dontTrackOpenResources=true&defaultFetchSize=1000&useCursorFetch=true" --driver com.mysql.jdbc.Driver \
--username root --password "6Aq2FuMVvWzsEFeJ4p84ctiwM" \
--exclude-tables dws_fin_loan_account_d \
--warehouse-dir /data/warehouse/dwh.db/ \
--fields-terminated-by '|'  \
--null-string '\\N'  --null-non-string '\\N'  \
--hive-import \
--hive-database dwh \
--num-mappers 4

19:10:28-19:21:05

导入固定的表：
sqoop import --connect "jdbc:mysql://192.168.80.98:3306/dwh?dontTrackOpenResources=true&defaultFetchSize=1000&useCursorFetch=true" --driver com.mysql.jdbc.Driver \
--username root --password "6Aq2FuMVvWzsEFeJ4p84ctiwM" \
--table dim_date \
--hive-database dwh \
--hive-import \
--target-dir /data/warehouse/dwh.db/dim_date \
--null-string '\\N' --null-non-string '\\N' \
--fields-terminated-by '|' --num-mappers 4

sqoop import --connect "jdbc:mysql://192.168.80.98:3306/dwh?dontTrackOpenResources=true&defaultFetchSize=1000&useCursorFetch=true" --driver com.mysql.jdbc.Driver \
--username root --password "6Aq2FuMVvWzsEFeJ4p84ctiwM" \
--table dws_fin_loan_account_d \
--hive-database dwh \
--hive-import \
--target-dir /data/warehouse/dwh.db/dws_fin_loan_account_d \
--split-by \`snap_date_key\` \
--boundary-query "SELECT min(\`snap_date_key\`), max(\`snap_date_key\`) FROM \`dwh\`.\`dws_fin_loan_account_d\`" \
--null-string '\\N' --null-non-string '\\N' \
--fields-terminated-by '|' --num-mappers 4

通过query导入指定的数据：
sqoop import --connect "jdbc:mysql://192.168.80.98:3306/dwh?dontTrackOpenResources=true&defaultFetchSize=1000&useCursorFetch=true" --driver com.mysql.jdbc.Driver \
--username root --password "6Aq2FuMVvWzsEFeJ4p84ctiwM" \
--query "SELECT * FROM dwh.dws_fin_loan_account_d WHERE 1=1 AND (dws_fin_loan_account_d.snap_date_key >= '2020-04-01' AND dws_fin_loan_account_d.snap_date_key < '2020-06-01')  AND \$CONDITIONS" \
--hive-table dws_fin_loan_account_d \
--hive-database dwh \
--hive-import \
--target-dir /data/warehouse/dwh.db/dws_fin_loan_account_d \
--split-by snap_date_key \
--boundary-query "SELECT min(snap_date_key), max(snap_date_key) FROM dwh.dws_fin_loan_account_d  WHERE dws_fin_loan_account_d.snap_date_key >= '2020-04-01' AND dws_fin_loan_account_d.snap_date_key < '2020-06-01'" \
--null-string '\\N' --null-non-string '\\N' \
--fields-terminated-by '|' --num-mappers 4

19:35:23-19:39:15

14:21-14:35

--target-dir hdfs://master1:8020/kylin/kylin_metadata/kylin-17a6c8ed-e221-dbbe-1f3b-f7c66ab5419d/kylin_intermediate_dwh_cube_9864cfd8_5a44_6137_85c9_62b3f9c0750b \
--split-by \`snap_date_key\` \
--null-non-string '\\N' \
--fields-terminated-by '|' \
--num-mappers 4


/opt/cloudera/parcels/CDH/lib/sqoop/bin/sqoop import -Dorg.apache.sqoop.splitter.allow_text_splitter=true  -Dmapreduce.job.queuename=default --connect "jdbc:mysql://192.168.80.98:3306/dwh?dontTrackOpenResources=true&defaultFetchSize=1000&useCursorFetch=true" --driver com.mysql.jdbc.Driver --username root --password "6Aq2FuMVvWzsEFeJ4p84ctiwM" --query "SELECT \`dws_fin_loan_account_d\`.\`fin_loan_account_d_id\` as \`DWS_FIN_LOAN_ACCOUNT_D_FIN_LOAN_ACCOUNT_D_ID\` ,\`dws_fin_loan_account_d\`.\`sid\` as \`DWS_FIN_LOAN_ACCOUNT_D_SID\` ,\`dws_fin_loan_account_d\`.\`source_system_id\` as \`DWS_FIN_LOAN_ACCOUNT_D_SOURCE_SYSTEM_ID\` ,\`dws_fin_loan_account_d\`.\`snap_date_key\` ,\`dws_fin_loan_account_d\`.\`loan_bill_id\` as \`DWS_FIN_LOAN_ACCOUNT_D_LOAN_BILL_ID\` ,\`dws_fin_loan_account_d\`.\`loan_client_id\` as \`DWS_FIN_LOAN_ACCOUNT_D_LOAN_CLIENT_ID\` ,\`dws_fin_loan_account_d\`.\`loan_account_id\` as \`DWS_FIN_LOAN_ACCOUNT_D_LOAN_ACCOUNT_ID\` ,\`dws_fin_loan_account_d\`.\`contract_id\` as \`DWS_FIN_LOAN_ACCOUNT_D_CONTRACT_ID\` ,\`dws_fin_loan_account_d\`.\`loan_product_id\` as \`DWS_FIN_LOAN_ACCOUNT_D_LOAN_PRODUCT_ID\` ,\`dws_fin_loan_account_d\`.\`virtual_center_id\` as \`DWS_FIN_LOAN_ACCOUNT_D_VIRTUAL_CENTER_ID\` ,\`dws_fin_loan_account_d\`.\`principal_repay_balance_amount\` as \`DWS_FIN_LOAN_ACCOUNT_D_PRINCIPAL_REPAY_BALANCE_AMOUNT\` ,\`dws_fin_loan_account_d\`.\`principal_repay_balance_irr_amount\` as \`DWS_FIN_LOAN_ACCOUNT_D_PRINCIPAL_REPAY_BALANCE_IRR_AMOUNT\` ,\`dws_fin_loan_account_d\`.\`principal_process_balance_amount\` as \`DWS_FIN_LOAN_ACCOUNT_D_PRINCIPAL_PROCESS_BALANCE_AMOUNT\` ,\`dws_fin_loan_account_d\`.\`principal_process_balance_irr_amount\` as \`DWS_FIN_LOAN_ACCOUNT_D_PRINCIPAL_PROCESS_BALANCE_IRR_AMOUNT\` ,\`dws_fin_loan_account_d\`.\`receive_repay_income_amount\` as \`DWS_FIN_LOAN_ACCOUNT_D_RECEIVE_REPAY_INCOME_AMOUNT\` ,\`dws_fin_loan_account_d\`.\`receive_process_income_amount\` as \`DWS_FIN_LOAN_ACCOUNT_D_RECEIVE_PROCESS_INCOME_AMOUNT\` ,\`dws_fin_loan_account_d\`.\`receive_repay_income_deadline_amount\` as \`DWS_FIN_LOAN_ACCOUNT_D_RECEIVE_REPAY_INCOME_DEADLINE_AMOUNT\` ,\`dws_fin_loan_account_d\`.\`receive_process_income_deadline_amount\` as \`DWS_FIN_LOAN_ACCOUNT_D_RECEIVE_PROCESS_INCOME_DEADLINE_AMOUNT\`  FROM \`dwh\`.\`dws_fin_loan_account_d\` \`dws_fin_loan_account_d\` INNER JOIN \`dwh\`.\`dim_date\` \`dim_date\` ON \`dws_fin_loan_account_d\`.\`snap_date_key\` = \`dim_date\`.\`date_key\` WHERE 1=1 AND (\`dws_fin_loan_account_d\`.\`snap_date_key\` >= '2020-05-01' AND \`dws_fin_loan_account_d\`.\`snap_date_key\` < '2020-06-01')  AND \$CONDITIONS" --target-dir hdfs://master1:8020/kylin/kylin_metadata/kylin-17a6c8ed-e221-dbbe-1f3b-f7c66ab5419d/kylin_intermediate_dwh_cube_9864cfd8_5a44_6137_85c9_62b3f9c0750b --split-by \`snap_date_key\` --boundary-query "SELECT min(\`snap_date_key\`), max(\`snap_date_key\`) FROM \`dwh\`.\`dws_fin_loan_account_d\`  WHERE \`dws_fin_loan_account_d\`.\`snap_date_key\` >= '2020-05-01' AND \`dws_fin_loan_account_d\`.\`snap_date_key\` < '2020-06-01'" --null-string '\\N' --null-non-string '\\N' --fields-terminated-by '|' --num-mappers 4

