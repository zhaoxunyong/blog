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
sudo vagrant box add centos7 centos7-0.0.99.box
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
sudo vagrant snapshot list nna

#udo vagrant package --output centos-ready.box
sudo vagrant package nna --output centos-ready.box

sudo iptables -nvL

sudo route add default gw 192.168.80.254
#每次重启都要删除
sudo route del default gw 10.0.2.2

80.201:
sudo vagrant snapshot save nna nna_base_snapshot
sudo vagrant snapshot save nns nns_base_snapshot
sudo vagrant snapshot save dn1 dn1_base_snapshot
sudo vagrant snapshot save dn2 dn2_base_snapshot

80.196:
sudo vagrant snapshot save kylin1 kylin1_base_snapshot
sudo vagrant snapshot save dn3 dn3_base_snapshot
sudo vagrant snapshot save dn4 dn4_base_snapshot

sudo vagrant snapshot restore nna nna_kylin_snapshot
...

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
sudo mkdir -p "/data/vagrant/VirtualBox VMs"
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


https://askubuntu.com/questions/317338/how-can-i-increase-disk-size-on-a-vagrant-vm
https://medium.com/@kanrangsan/how-to-automatically-resize-virtual-box-disk-with-vagrant-9f0f48aa46b3
I found this simplest way to resolve this problem:

Install this plugin: vagrant plugin install vagrant-disksize

Edit the Vagrantfile:

Vagrant.configure('2') do |config|
  ...
  config.vm.box = 'ubuntu/xenial64'
  config.disksize.size = '150GB'
  ...
end
vagrant halt && vagrant up

Note: this will not work with vagrant reload

Enter container:
sudo parted /dev/sda print free
sudo parted /dev/sda resizepart 2 100%
sudo pvresize /dev/sda2
sudo lvextend -l +100%FREE /dev/mapper/centos-root
sudo xfs_growfs /dev/mapper/centos-root

合并home到root：
https://www.cnblogs.com/liusingbon/p/12896370.html
#!/bin/bash

cd /
sudo tar -cvf /mnt/home.tar /home
sudo fuser -km /home
sudo umount /home
sudo lvremove /dev/centos/home
sudo vgdisplay
#sudo vim /etc/fstab : Disable /dev/mapper/centos-home mount
sudo sed -i "s;/dev/mapper/centos-home;#/dev/mapper/centos-home;" /etc/fstab
sudo lvdisplay
sudo parted /dev/sda print free
sudo parted /dev/sda resizepart 2 100%
sudo pvresize /dev/sda2
sudo lvextend -l +100%FREE /dev/mapper/centos-root
sudo xfs_growfs /dev/mapper/centos-root
sudo tar -xvf /mnt/home.tar -C /
#reboot system to take affect


Filesystem               Size  Used Avail Use% Mounted on
devtmpfs                 7.8G     0  7.8G   0% /dev
tmpfs                    7.8G     0  7.8G   0% /dev/shm
tmpfs                    7.8G   17M  7.8G   1% /run
tmpfs                    7.8G     0  7.8G   0% /sys/fs/cgroup
/dev/mapper/centos-root   50G   15G   36G  29% /
/dev/sda1               1014M   83M  932M   9% /boot
/dev/mapper/centos-home   47G   44G  3.9G  92% /home
cm_processes             7.8G  1.2M  7.8G   1% /run/cloudera-scm-agent/process
vagrant                  883G  345G  539G  40% /vagrant
tmpfs                    1.6G     0  1.6G   0% /run/user/1001


<!-- 192.168.100.100    root    wlt.local   32G/8Core
192.168.108.100    root    wlt.local   32G/8Core
192.168.100.31     root    wlt.local   64G/16Core -->
192.168.80.196     root    64G/48Core  10G/8C 

192.168.80.94      root    32G/8Core   8G/4C(master1) 24G/4C(utility/mysql)
192.168.80.97      root    32G/8Core   8G/4C(master2)  8G/4C(gateway1)
192.168.80.99      root    32G/8Core   8G/4C(master3)  24G/4C(kylin)

<!-- #192.168.80.201     root    64G/48Core  10G/8C node1/node2/node3/node4/node5/node6 -->
192.168.80.201     root    64G/48Core  20G/14C node1/node2/node3
192.168.80.98      root    64G/16Core  20G/14C node4


80.94
---------------------------
master1:
docker run -d \
-m 8G --cpus=4 \
-h master1 --name master1 \
-p 8088:8088 -p 19888:19888 -p 50070:50070 \
-v /home/dev/cdh:/cdh \
--privileged=true \
dave/cdh:base /sbin/init

utility1:
docker run -d \
-m 24G --cpus=4 \
-h utility --name utility \
-p 7180:7180 -p 8889:8889 \
-v /home/dev/cdh:/cdh \
--privileged=true \
dave/cdh:base /sbin/init

80.97
---------------------------
master2:
docker run -d \
-m 8G --cpus=4 \
-h master2 --name master2 \
-v /home/dev/cdh:/cdh \
-p 8088:8088 -p 19888:19888 -p 50070:50070 \
--privileged=true \
dave/cdh:base /sbin/init

gateway1:
docker run -d \
-m 8G --cpus=4 \
-h gateway1 --name gateway1 \
-v /home/dev/cdh:/cdh \
--privileged=true \
dave/cdh:base /sbin/init

80.99
---------------------------
master3:
docker run -d \
-m 8G --cpus=4 \
-h master3 --name master3 \
-v /home/dev/cdh:/cdh \
-p 8088:8088 -p 19888:19888 -p 50070:50070 \
--privileged=true \
dave/cdh:base /sbin/init

kylin:
docker run -d \
-m 24G --cpus=4 \
-h kylin --name kylin \
-p 7070:7070 \
-v /home/dev/cdh:/cdh \
--privileged=true \
dave/cdh:base /sbin/init

80.201
---------------------------
dn1:
sudo mkdir -p /data/cdh/dn1
docker run -d \
-m 10G --cpus=8 \
-h dn1 --name dn1 \
-v /home/dev/cdh:/cdh \
-v /data/cdh/dn1:/data/cdh \
--privileged=true \
dave/cdh:base /sbin/init

dn2:
sudo mkdir -p /data/cdh/dn2
docker run -d \
-m 10G --cpus=8 \
-h dn2 --name dn2 \
-v /home/dev/cdh:/cdh \
-v /data/cdh/dn2:/data/cdh \
--privileged=true \
dave/cdh:base /sbin/init

dn3:
sudo mkdir -p /data/cdh/dn3
docker run -d \
-m 10G --cpus=8 \
-h dn3 --name dn3 \
-v /home/dev/cdh:/cdh \
-v /data/cdh/dn3:/data/cdh \
--privileged=true \
dave/cdh:base /sbin/init

dn4:
sudo mkdir -p /data/cdh/dn4
docker run -d \
-m 10G --cpus=8 \
-h dn4 --name dn4 \
-v /home/dev/cdh:/cdh \
-v /data/cdh/dn4:/data/cdh \
--privileged=true \
dave/cdh:base /sbin/init

dn5:
sudo mkdir -p /data/cdh/dn5
docker run -d \
-m 10G --cpus=8 \
-h dn5 --name dn5 \
-v /home/dev/cdh:/cdh \
-v /data/cdh/dn5:/data/cdh \
--privileged=true \
dave/cdh:base /sbin/init

dn6:
sudo mkdir -p /data/cdh/dn6
docker run -d \
-m 10G --cpus=8 \
-h dn6 --name dn6 \
-v /home/dev/cdh:/cdh \
-v /data/cdh/dn6:/data/cdh \
--privileged=true \
dave/cdh:base /sbin/init



master1:
cat /run/flannel/docker
DOCKER_OPT_BIP="--bip=10.244.32.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=false"
DOCKER_OPT_MTU="--mtu=1472"
DOCKER_NETWORK_OPTIONS=" --bip=10.244.32.1/24 --ip-masq=false --mtu=1472"

cat /run/flannel/subnet.env
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.32.1/24
FLANNEL_MTU=1472
FLANNEL_IPMASQ=true

master2:
DOCKER_OPT_BIP="--bip=10.244.93.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=false"
DOCKER_OPT_MTU="--mtu=1472"
DOCKER_NETWORK_OPTIONS=" --bip=10.244.93.1/24 --ip-masq=false --mtu=1472"

cat /run/flannel/subnet.env
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.93.1/24
FLANNEL_MTU=1472
FLANNEL_IPMASQ=true

master3:
DOCKER_OPT_BIP="--bip=10.244.5.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=false"
DOCKER_OPT_MTU="--mtu=1472"
DOCKER_NETWORK_OPTIONS=" --bip=10.244.5.1/24 --ip-masq=false --mtu=1472"

cat /run/flannel/subnet.env
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.5.1/24
FLANNEL_MTU=1472
FLANNEL_IPMASQ=true

dn1:
DOCKER_OPT_BIP="--bip=10.244.61.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=false"
DOCKER_OPT_MTU="--mtu=1472"
DOCKER_NETWORK_OPTIONS=" --bip=10.244.61.1/24 --ip-masq=false --mtu=1472"

cat /run/flannel/subnet.env
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.61.1/24
FLANNEL_MTU=1472
FLANNEL_IPMASQ=true

<!-- echo "10.244.61.2 dn1
10.244.61.3 dn2
10.244.61.4 dn3
10.244.61.5 dn4
10.244.61.6 dn5
10.244.61.7 dn6

10.244.93.3 gateway1
10.244.5.3 kylin
10.244.32.2 master1
10.244.93.2 master2
10.244.5.2 master3
10.244.32.3 utility" >> /etc/hosts
 -->

 80.94：
 docker start  master1
 docker start  utility

 80.97：
 docker start master2
 docker start gateway1

 80.99：
 docker start master3
 docker start kylin

 80.201：
 docker start dn1
 docker start dn2
 docker start dn3
 docker start dn4
 docker start dn5
 docker start dn6


echo '10.244.32.2 master1
10.244.32.3   utility
10.244.93.2   master2
10.244.93.3   gateway1
10.244.5.2   master3
10.244.5.3   kylin
10.244.61.2   dn1
10.244.61.3   dn2
10.244.61.4   dn3
10.244.61.5   dn4
10.244.61.6   dn5
10.244.61.7   dn6' >> /etc/hosts

http://192.168.80.94:7180/cmf/
http://192.168.80.99:7070/kylin/



python -c "import base64; print base64.standard_b64encode('ADMIN:KYLIN')"        
QURNSU46S1lMSU4=

curl -c ~/cookie.txt -X POST -H "Authorization: Basic QURNSU46S1lMSU4=" -H 'Content-Type: application/json' http://192.168.80.99:7070/kylin/api/user/authentication
{"userDetails":{"username":"ADMIN","password":"$2a$10$o3ktIWsGYxXNuUWQiYlZXOW5hWcqyNAFQsSSCSEWoC/BRVMAUjL32","authorities":[{"authority":"ROLE_ADMIN"},{"authority":"ROLE_ANALYST"},{"authority":"ROLE_MODELER"},{"authority":"ALL_USERS"}],"disabled":false,"defaultPassword":false,"locked":false,"lockedTime":0,"wrongTime":0,"uuid":"2218e5ca-5b7e-066d-ef30-487e83852233","last_modified":1591674148561,"version":"3.0.0.20500"}}

curl -b ~/cookie.txt -X POST -H "Authorization: Basic QURNSU46S1lMSU4=" -H 'Content-Type: application/json' http://192.168.80.99:7070/kylin/api/user/authentication/api/cubes?cubeName=cube_name&limit=15&offset=0

curl -X PUT --user ADMIN:KYLIN -H "Content-Type: application/json;charset=utf-8" -d '{ "startTime": 820454400000, "endTime": 821318400000, "buildType": "BUILD"}' http://192.168.80.99:7070/kylin/api/cubes/kylin_sales/build