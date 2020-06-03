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


192.168.100.100    root    wlt.local   32G/8Core     Master Host 1/Utility Host 1
192.168.108.100    root    wlt.local   32G/8Core     Master Host 2/Gateway Hosts 1
192.168.80.94      root                32G/8Core     Master Host 2/Gateway Hosts 1


192.168.100.31     root    wlt.local   64G/16Core

192.168.80.201      root    tqPAI1H24TYjR5H57bHF7xxRBoSZldSp   64G/48Core
192.168.80.196      root    AsvpWKtDNoCFiLfVJMNsAni5RhAJcIz3   64G/48Core