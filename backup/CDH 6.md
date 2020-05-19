CDH 6
准备环境：https://www.staroon.dev/2017/11/05/SetEnv/

https://docs.cloudera.com/documentation/enterprise/6/latest/topics/cm_ig_host_allocations.html#concept_f43_j4y_dw__section_icy_mgj_ndb

https://archive.cloudera.com/cdh6/6.1.1/parcels/
https://archive.cloudera.com/cm6/6.1.1/redhat7/yum/RPMS/x86_64/


wget https://archive.cloudera.com/cm6/6.1.1/allkeys.asc -P /var/www/html/cloudera-repos/cm6/6.1.1/
wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/gplextras6/6.1.1/redhat7/ -P /var/www/html/cloudera-repos
wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/cdh6/6.1.1/redhat7/ -P /var/www/html/cloudera-repos
wget --recursive --no-parent --no-host-directories https://archive.cloudera.com/cm6/6.1.1/redhat7/ -P /var/www/html/cloudera-repos

python -m SimpleHTTPServer 8900

https://blog.csdn.net/u010514380/article/details/88083139
#Working on nns:
sudo yum localinstall *.rpm
sudo systemctl start mysqld
sudo cat /var/log/mysqld.log |grep password
2020-05-19T06:46:45.968754Z 1 [Note] A temporary password is generated for root@localhost: C5fmlcqqur?*

#启动MySQL
systemctl start mysqld
#查看初始密码
grep 'temporary password' /var/log/mysqld.log
#通过初始密码登陆
mysql -uroot -p
#修改root用户的密码
ALTER USER 'root'@'localhost' IDENTIFIED BY 'Aa123#@!';


CREATE DATABASE hive DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE monitor DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

GRANT ALL ON hive.* TO 'hive'@'%' IDENTIFIED BY 'Aa123#@!';
GRANT ALL ON monitor.* TO 'monitor'@'%' IDENTIFIED BY 'Aa123#@!';


GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY 'Aa123#@!' WITH GRANT OPTION;
flush privileges;

#Working on all nodes
sudo rpm -ivh oracle-j2sdk1.8-1.8.0+update181-1.x86_64.rpm

#Working on nns
sudo rpm -ivh cloudera-manager-server-6.1.1-853290.el7.x86_64.rpm
#cloudera-scm-server

#Working on all nodes
sudo rpm -ivh cloudera-manager-daemons-6.1.1-853290.el7.x86_64.rpm
sudo yum localinstall cloudera-manager-agent-6.1.1-853290.el7.x86_64.rpm -y

#Working on nns
sudo cp -a /vagrant/CDH/6/parcel-repo/* /opt/cloudera/parcel-repo/
sudo chown -R cloudera-scm:cloudera-scm /opt/cloudera/parcel-repo/
sudo mv CDH-6.1.1-1.cdh6.1.1.p0.875250-el7.parcel.sha256 CDH-6.1.1-1.cdh6.1.1.p0.875250-el7.parcel.sha
sha1sum CDH-6.1.1-1.cdh6.1.1.p0.875250-el7.parcel
修改manifest.json中的hash与.sha文件中的值为sha1sum计算出来的值

#Working on all
sudo mkdir -p /usr/share/java/
sudo cp -a /vagrant/CDH/mysql-connector-java-5.1.48-bin.jar /usr/share/java/mysql-connector-java.jar
sudo vim /etc/cloudera-scm-agent/config.ini
server_host=nns

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
sudo tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log
http://nns:7180

#Working on all nodes
sudo systemctl enable cloudera-scm-agent
sudo systemctl start cloudera-scm-agent
sudo tail -n100 -f /var/log/cloudera-scm-agent/cloudera-scm-agent.log

