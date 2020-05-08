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

sudo vagrant snapshot take nna nna_kylin_snapshot
sudo vagrant snapshot take nns nns_kylin_snapshot
sudo vagrant snapshot take dn1 dn1_kylin_snapshot
sudo vagrant snapshot take dn2 dn2_kylin_snapshot
sudo vagrant snapshot take dn3 dn3_kylin_snapshot
sudo vagrant snapshot take dn3 kylin1_kylin_snapshot

修改boxes的目录
sudo vagrant halt
sudo su -
https://www.jianshu.com/p/12cf1ecb224b
https://www.cnblogs.com/csliwei/p/5860005.html
cp -a ~/.vagrant.d/ /data/vagrant/
#加到root与当前使用用户中
vim ~/.bashrc
export VAGRANT_HOME='/data/vagrant'
export VAGRANT_DISABLE_VBOXSYMLINKCREATE=1

#VBoxManage setproperty machinefolder  /data/vagrant/
cp -a "/root/VirtualBox VMs" "/data/vagrant/VirtualBox VMs"
sudo ln -s "/data/vagrant/VirtualBox VMs" "/root/VirtualBox VMs"
mv "/root/VirtualBox VMs" "/root/VirtualBox VMs.bak"
重新登录


Authentication failure. Retrying 
sudo ssh-keygen -t rsa -C "vagrant"
sudo cat  /root/.ssh/id_rsa.pub >>  /root/.ssh/authorized_keys
sudo chmod 600  /root/.ssh/authorized_keys
#Making sure ssh vagrant@nna without password: sudo ssh vagrant@nns
sudo scp  /root/.ssh/authorized_keys vagrant@nna:/home/vagrant/.ssh/
sudo scp  /root/.ssh/authorized_keys vagrant@nns:/home/vagrant/.ssh/
sudo scp  /root/.ssh/authorized_keys vagrant@dn1:/home/vagrant/.ssh/
sudo scp  /root/.ssh/authorized_keys vagrant@dn2:/home/vagrant/.ssh/
sudo scp  /root/.ssh/authorized_keys vagrant@dn3:/home/vagrant/.ssh/
sudo cp -a /root/.ssh/id_rsa /root/.vagrant.d/insecure_private_key

或者在Vagrantfile中添加：
kylin1.ssh.private_key_path = "/root/.ssh/id_rsa"
kylin1.ssh.forward_agent = true

-----------------------------------------------
sudo vagrant ssh-config
  Host kylin1
  HostName 127.0.0.1
  User vagrant
  Port 2222
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /root/.vagrant.d/insecure_private_key
  IdentitiesOnly yes
  LogLevel FATAL



