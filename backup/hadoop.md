docker network create hadoop

docker run -d \
-m 2G --cpus=2 \
--name nna --net=hadoop \
centos:centos7 \
/bin/bash -c "tail -n100 -f /var/log/yum.log"

docker run -d \
-m 2G --cpus=2 \
--name nns --net=hadoop \
centos:centos7 \
/bin/bash -c "tail -n100 -f /var/log/yum.log"

docker run -d \
-m 1G --cpus=1 \
--name dns1 --net=hadoop \
centos:centos7 \
/bin/bash -c "tail -n100 -f /var/log/yum.log"

docker run -d \
-m 1G --cpus=1 \
--name dns2 --net=hadoop \
centos:centos7 \
/bin/bash -c "tail -n100 -f /var/log/yum.log"

docker run -d \
-m 1G --cpus=1 \
--name dns3 --net=hadoop \
centos:centos7 \
/bin/bash -c "tail -n100 -f /var/log/yum.log"

cd vagrant
sudo vagrant box remove centos7
sudo vagrant box add centos7 centos-ready.box
sudo vagrant box list
#sudo vagrant init centos7
sudo vagrant up
#sudo vagrant up nna
sudo vagrant halt
sudo vagrant reload
#sudo vagrant destroy
sudo vagrant ssh
sudo vagrant ssh nna
sudo vagrant ssh nns
sudo vagrant ssh dns1
sudo vagrant ssh dns2
sudo vagrant ssh dns3

sudo vagrant plugin install vagrant-vbox-snapshot
sudo vagrant snapshot take nna nna_0427_snapshot
sudo vagrant snapshot take nns nns_0427_snapshot
sudo vagrant snapshot take dn1 dn1_0427_snapshot
sudo vagrant snapshot take dn2 dn2_0427_snapshot
sudo vagrant snapshot take dn3 dn3_0427_snapshot
sudo vagrant snapshot list nna
sudo vagrant snapshot go nna nna_0427_snapshot

#udo vagrant package --output centos-ready.box
sudo vagrant package nna --output centos-ready.box

sudo iptables -nvL

sudo route add default gw 192.168.80.254
#每次重启都要删除
sudo route del default gw 10.0.2.2


sudo vagrant snapshot take nna nna_hadoopbase_snapshot
sudo vagrant snapshot take nns nns_hadoopbase_snapshot
sudo vagrant snapshot take dn1 dn1_hadoopbase_snapshot
sudo vagrant snapshot take dn2 dn2_hadoopbase_snapshot
sudo vagrant snapshot take dn3 dn3_hadoopbase_snapshot

sudo vagrant snapshot take nna nna_hbase_snapshot
sudo vagrant snapshot take nns nns_hbase_snapshot
sudo vagrant snapshot take dn1 dn1_hbase_snapshot
sudo vagrant snapshot take dn2 dn2_hbase_snapshot
sudo vagrant snapshot take dn3 dn3_hbase_snapshot

sudo vagrant snapshot take nna nna_hive_snapshot
sudo vagrant snapshot take nns nns_hive_snapshot
sudo vagrant snapshot take dn1 dn1_hive_snapshot
sudo vagrant snapshot take dn2 dn2_hive_snapshot
sudo vagrant snapshot take dn3 dn3_hive_snapshot


