https://blog.csdn.net/Michaelwubo/article/details/92659986

sudo yum install -y etcd

80.94：
tee /etc/etcd/etcd.conf << EOF
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
ETCD_NAME="master"
#
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.80.94:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.80.94:2379,http://192.168.80.94:4001"
ETCD_INITIAL_CLUSTER="master=http://192.168.80.94:2380,node1=http://192.168.80.97:2380,node2=http://192.168.80.99:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF

80.97：
tee /etc/etcd/etcd.conf << EOF
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
ETCD_NAME="node1"
#
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.80.97:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.80.97:2379,http://192.168.80.97:4001"
ETCD_INITIAL_CLUSTER="master=http://192.168.80.94:2380,node1=http://192.168.80.97:2380,node2=http://192.168.80.99:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF

80.99：
tee /etc/etcd/etcd.conf << EOF
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
ETCD_NAME="node2"
#
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.80.99:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.80.99:2379,http://192.168.80.99:4001"
ETCD_INITIAL_CLUSTER="master=http://192.168.80.94:2380,node1=http://192.168.80.97:2380,node2=http://192.168.80.99:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF


test:
systemctl enable etcd
systemctl start etcd
etcdctl member list

yum install -y flannel

etcdctl --endpoints "http://192.168.80.94:2379,http://192.168.80.97:2379,http://192.168.80.99:2379" set /coreos.com/network/config '{"NetWork":"10.244.0.0/16"}'

#Working on all nodes:
$ sed -i 's;^FLANNEL_ETCD_ENDPOINTS=.*;FLANNEL_ETCD_ENDPOINTS="http://192.168.80.94:2379,http://192.168.80.97:2379,http://192.168.80.99:2379";g' \
/etc/sysconfig/flanneld

$ sed -i 's;^FLANNEL_ETCD_PREFIX=.*;FLANNEL_ETCD_PREFIX="/coreos.com/network";g' \
/etc/sysconfig/flanneld

$ sed -i 's;^#FLANNEL_OPTIONS=.*;FLANNEL_OPTIONS="-ip-masq=true";g' \
/etc/sysconfig/flanneld

$ sed -i 's;^ExecStart=.*;ExecStart=/usr/bin/flanneld-start -etcd-endpoints=${FLANNEL_ETCD_ENDPOINTS} -etcd-prefix=${FLANNEL_ETCD_PREFIX} $FLANNEL_OPTIONS;g' \
/usr/lib/systemd/system/flanneld.service

systemctl daemon-reload
systemctl enable flanneld
systemctl restart flanneld
systemctl status flanneld

<!-- 流量再从flannel出去，其他host上看到的source ip就是flannel的网关ip
https://www.cnblogs.com/wjoyxt/p/9970837.html
https://github.com/coreos/flannel/issues/117
/usr/lib/systemd/system/docker.service
ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTIONS --ip-masq=false -->

<!-- #Disabling ExecStartPost in /usr/lib/systemd/system/flanneld.service while rebooting, change a new ip -->

<!-- #防止重启后可以IP会变更，使用/data/flannel/docker文件
mkdir -p /data/flannel/
cp -a /run/flannel/docker /data/flannel/docker -->


sed -i -e '/ExecStart=/iEnvironmentFile=/run/flannel/docker' -e 's;^ExecStart=/usr/bin/dockerd;ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTIONS;g' \
/usr/lib/systemd/system/docker.service

#重启docker服务
systemctl daemon-reload
systemctl enable docker
systemctl restart docker


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
cat /run/flannel/docker
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
cat /run/flannel/docker
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
cat /run/flannel/docker
DOCKER_OPT_BIP="--bip=10.244.61.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=false"
DOCKER_OPT_MTU="--mtu=1472"
DOCKER_NETWORK_OPTIONS=" --bip=10.244.61.1/24 --ip-masq=false --mtu=1472"

cat /run/flannel/subnet.env
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.61.1/24
FLANNEL_MTU=1472
FLANNEL_IPMASQ=true

dn4:
cat /run/flannel/docker
DOCKER_OPT_BIP="--bip=10.244.47.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=false"
DOCKER_OPT_MTU="--mtu=1472"
DOCKER_NETWORK_OPTIONS=" --bip=10.244.47.1/24 --ip-masq=false --mtu=1472"

cat /run/flannel/subnet.env
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.47.1/24
FLANNEL_MTU=1472
FLANNEL_IPMASQ=true
