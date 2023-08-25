Centos AMBARI:

node1 192.168.101.83
node2 192.168.101.84
node3 192.168.101.85

ssh打通：
#Working all
groupadd hadoop
useradd -m -g hadoop hadoop
passwd hadoop
chmod +w /etc/sudoers
echo "hadoop ALL=(ALL)NOPASSWD: ALL" >> /etc/sudoers
chmod -w /etc/sudoers

#免密码登录
#Working on 192.168.101.83
sudo su - hadoop
ssh-keygen -t rsa
#直接写入到~/.ssh/authorized_keys中：
ssh-copy-id -i ~/.ssh/id_rsa.pub hadoop@192.168.101.83
#cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
sudo chmod 700 ~/.ssh
sudo chmod 600 ~/.ssh/authorized_keys
其他的机器需要先创建目录：
sudo su - hadoop
mkdir -p ~/.ssh/
并复制到所有机器。每台机器先执行mkdir ~/.ssh，
scp ~/.ssh/authorized_keys hadoop@192.168.101.84:~/.ssh/
scp ~/.ssh/authorized_keys hadoop@192.168.101.85:~/.ssh/
复制完成后，每台机器执行：
sudo chmod 700 ~/.ssh
sudo chmod 600 ~/.ssh/authorized_keys

scp ~/.ssh/id_rsa* hadoop@192.168.101.84:~/.ssh/
scp ~/.ssh/id_rsa* hadoop@192.168.101.85:~/.ssh/


#For centos on docker:
route del default gw 172.17.0.1
route add default gw 192.168.80.254
chmod +x /etc/rc.local
chmod +x /etc/rc.d/rc.local
echo "ifconfig eth0 down
route del default gw 172.17.0.1
route add default gw 192.168.80.254" >> /etc/rc.local

echo "127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6" >> /etc/hosts

echo "
192.168.80.215 namenode01 namenode01.zerofinance.net
192.168.80.216 namenode02 namenode02.zerofinance.net
192.168.80.217 datanode01 datanode01.zerofinance.net
192.168.80.218 datanode02 datanode02.zerofinance.net
192.168.80.219 datanode03 datanode03.zerofinance.net

192.168.80.225 namenode01-test namenode01-test.zerofinance.net
192.168.80.226 namenode02-test namenode02-test.zerofinance.net
192.168.80.227 datanode01-test datanode01-test.zerofinance.net
192.168.80.228 datanode02-test datanode02-test.zerofinance.net
192.168.80.229 datanode03-test datanode03-test.zerofinance.net" >> /etc/hosts


ntp：
https://www.cnblogs.com/Sungeek/p/10197345.html
#on all:
sudo yum -y install ntp
sudo timedatectl set-timezone Asia/Shanghai
192.168.101.83：
vim /etc/ntp.conf

restrict 0.0.0.0 mask 0.0.0.0 nomodify notrap
server 127.127.1.0
fudge  127.127.1.0 stratum 10

把配置文件下面四行注释掉：
server 0.centos.pool.ntp.org iburst
server 1.centos.pool.ntp.org iburst
server 2.centos.pool.ntp.org iburst
server 3.centos.pool.ntp.org iburst

然后在下面添加这几行：
server 0.cn.pool.ntp.org iburst
server 1.cn.pool.ntp.org iburst
server 2.cn.pool.ntp.org iburst
server 3.cn.pool.ntp.org iburst

systemctl enable ntpd
systemctl start ntpd

查询ntp是否同步
ntpq -p

NTP客户端配置：192.168.101.84/85

[root@localhost ~]# vim /etc/ntp.conf
#配置允许NTP Server时间服务器主动修改本机的时间
restrict 192.168.101.83 nomodify notrap noquery
#注释掉其他时间服务器
#server 0.centos.pool.ntp.org iburst
#server 1.centos.pool.ntp.org iburst
#server 2.centos.pool.ntp.org iburst
#server 3.centos.pool.ntp.org iburst
#配置时间服务器为本地搭建的NTP Server服务器
server 192.168.101.83

systemctl start ntpd
systemctl enable ntpd

同步：
ntpdate -u 192.168.101.83
sudo ntpstat

#所有机器
#echo "192.168.101.83 node1 node1.zerofinance.net
#192.168.101.84 node2 node2.zerofinance.net
#192.168.101.85 node3 node3.zerofinance.net" >> /etc/hosts
#如果是docker centos的话，每次docker重启hosts文件都会被还原


(Custom JDK must be installed on echo machine)
mkdir -p /works/app/jdk
cp -a /vagrant/jdk1.8.0_371 /works/app/jdk/

tee -a /etc/profile.d/java.sh <<EOF
#!/bin/bash

export JAVA_HOME=/works/app/jdk/jdk1.8.0_371
export PATH=\$JAVA_HOME/bin:\$PATH
EOF

. /etc/profile
java -version
----------------

#安装：
Login on 192.168.101.83:
#mysql
192.168.101.83安装mysql
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

#临时密码：
grep 'temporary password' /var/log/mysqld.log

mysql -uroot -p
set global validate_password_policy=0;
alter user 'root'@'localhost' identified by 'Aa123#@!';
CREATE USER 'ambari'@'%' IDENTIFIED BY 'Aa123456';
GRANT ALL PRIVILEGES ON ambari.* TO 'ambari'@'%';
FLUSH PRIVILEGES;
exit

mysql -u ambari -p
CREATE DATABASE ambari;
USE ambari;
SOURCE /var/lib/ambari-server/resources/Ambari-DDL-MySQL-CREATE.sql;
exit

mysql -uroot -p
CREATE DATABASE hive;
CREATE USER 'hive'@'%' IDENTIFIED BY 'Aa123456';
GRANT ALL PRIVILEGES ON hive.* TO 'hive'@'%';
FLUSH PRIVILEGES;
exit

安装ambari-server：
192.168.101.83:
#https://cloud.tencent.com/works/app/jdk/article/1375511
安装：
cd /vagrant
sudo yum install ./ambari-server-2.8.0.0-0.x86_64.rpm
/usr/sbin/ambari-server: line 34: buildNumber: unbound variable
#vim /usr/sbin/ambari-server将${buildNumber}这行换成 HASH="${VERSION}"
sed -i 's;${buildNumber};${VERSION};g' /usr/sbin/ambari-server
sed -i 's;${buildNumber};${VERSION};g' /etc/rc.d/init.d/ambari-server
With Root:
ambari-server setup --jdbc-db=mysql --jdbc-driver=/vagrant/mysql-connector-j-8.0.31.jar
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

rm -fr /usr/share/java && mkdir -p /usr/share/java
cp -a /vagrant/mysql-connector-j-8.0.31.jar /usr/share/java/
systemctl enable ambari-server
systemctl start ambari-server

bigtop repo(192.168.80.225): 
cd /vagrant/bigdatarepo
yum install createrepo
createrepo .
nohup python -m SimpleHTTPServer &
http://192.168.80.225:8000/

web portal:
http://192.168.101.83:8080/
admin、admin

所有机器安装agent：83/84/85:
cd /vagrant/
yum install ./ambari-agent-2.8.0.0-0.x86_64.rpm
#将${buildNumber}这行换成 HASH="${VERSION}"
sed -i 's;${buildNumber};${VERSION};g' /var/lib/ambari-agent/bin/ambari-agent
systemctl enable ambari-agent.service
systemctl restart ambari-agent.service 

namenode01-test.zerofinance.net
namenode02-test.zerofinance.net
datanode01-test.zerofinance.net
datanode02-test.zerofinance.net
datanode03-test.zerofinance.net

SSH User Account: hadoop

-------------------
Admin Name : admin

Cluster Name : dwh

Chose the hdfs account as "hadoop" not "hdfs"

Repositories:

redhat7 (BIGTOP-3.2.0):
http://192.168.101.83:8000/

1.hive启动报错
Sys DB and Information Schema not created yet

解决方案（看错误在哪台机器）：
cd /etc/hive/
touch /etc/hive/sys.db.created
进入ambari-server 端重启
sudo systemctl restart ambari-server

#Add new component, an error was caucse:
ambari 500 status code received on POST method for API:
#https://www.jianshu.com/p/3b54ba251c9e
chown -R hadoop:hadoop /var/run/ambari-server

#Cannot create /var/run/ambari-server/stack-recommendations:
chown -R hadoop:hadoop /var/run/ambari-server

进入web界面：
HDFS--->CONFIGS: 
search for hive, changed hadoop.proxyuser.hive.hosts to *

#mkdir: Permission denied: user=root, access=WRITE, inode="/":hdfs:hdfs:drwxr-xr-x
https://blog.csdn.net/gdkyxy2013/article/details/105254907

zeppelin不能运行flink的问题：
在安装zeppelin的机器上执行：
cd /usr/bigtop/current/flink-client/lib
mv flink-dist-1.15.3.jar flink-dist_2.12-1.15.3.jar

#zeppelin不支持flink 1.15.3, see: https://github.com/apache/zeppelin/blob/v0.10.1/flink/flink-shims/src/main/java/org/apache/zeppelin/flink/FlinkShims.java

zeppelin开启job:
Ambari--->Zeppelin--->Custom zeppelin-site:
zeppelin.jobmanager.enable: true
reboot zeppelin.

-----------------------------------------------------------------
安装：dolphinscheduler
sudo su - hadoop
docker env: need to shutdown eth0 or cannot register the actual ip to zokeeper: 
ifconfig eth0 down

#chmod +w /etc/sudoers
##vim /etc/sudoers
##在 sudoers 文件中添加以下内容
#echo "hadoop ALL=(ALL)NOPASSWD: ALL" >> /etc/sudoers
##最后保存内容后退出,并取消 sudoers 文件的写权限
#chmod -w /etc/sudoers

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

