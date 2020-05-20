CDH 6
准备环境：
https://www.staroon.dev/2017/11/05/SetEnv/

sudo su -
echo "vm.swappiness = 10" >> /etc/sysctl.conf
sysctl -p

echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled"  >> /etc/rc.local

https://www.staroon.dev/2018/12/01/CDH6Install/

https://docs.cloudera.com/documentation/enterprise/6/latest/topics/cm_ig_host_allocations.html#concept_f43_j4y_dw__section_icy_mgj_ndb

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
baseurl=http://192.168.102.166:8900/cloudera-repos/cm6/6.1.1/redhat7/yum/
enabled=1
gpgcheck=0 
EOF

cat > /etc/yum.repos.d/cloudera-repo-cdh.repo << EOF
[cloudera-repo-cdh]
name=cloudera-repo-cdh
baseurl=http://192.168.102.166:8900/cloudera-repos/cdh6/6.1.1/redhat7/yum/
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

服务名	                             数据库名	  用户名
Cloudera Manager Server	            scm	        scm
Activity Monitor	                amon	    amon
Reports Manager	                    rman	    rman
Hive Metastore Server	            hive	hive

Hue	                                hue	        hue
Sentry Server	                    sentry	    sentry
Cloudera Navigator Audit Server	    nav	        nav
Cloudera Navigator Metadata Server	navms	    navms
Oozie	                            oozie	    oozie

CREATE DATABASE scm DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE amon DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE rman DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE metastore DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE hive DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

GRANT ALL ON scm.* TO 'scm'@'%' IDENTIFIED BY 'Aa123#@!';
GRANT ALL ON amon.* TO 'amon'@'%' IDENTIFIED BY 'Aa123#@!';
GRANT ALL ON rman.* TO 'rman'@'%' IDENTIFIED BY 'Aa123#@!';
GRANT ALL ON metastore.* TO 'metastore'@'%' IDENTIFIED BY 'Aa123#@!';
GRANT ALL ON hive.* TO 'hive'@'%' IDENTIFIED BY 'Aa123#@!';
#GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY 'Aa123#@!' WITH GRANT OPTION;
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
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql metastore metastore Aa123#@!
sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql hive hive Aa123#@!

sudo sed -i "s;server_host=localhost;server_host=nns;g" /etc/cloudera-scm-agent/config.ini
<!-- sudo vim /etc/cloudera-scm-agent/config.ini
server_host=nns -->

sudo systemctl enable cloudera-scm-server
sudo systemctl start cloudera-scm-server
#第一次启动会很慢
sudo tail -n100 -f /var/log/cloudera-scm-server/cloudera-scm-server.log

#Working on all nodes
sudo systemctl enable cloudera-scm-agent
sudo systemctl start cloudera-scm-agent
sudo tail -n100 -n100 -f /var/log/cloudera-scm-agent/cloudera-scm-agent.log


http://nns:7180

安装时修改Remote Parcel Repository URLs为
#http://192.168.102.166:8900/cloudera-repos/cdh6/6.1.1/parcels/



