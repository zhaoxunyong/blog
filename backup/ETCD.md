https://blog.csdn.net/Michaelwubo/article/details/92659986

sudo yum install -y etcd

80.201：
tee /etc/etcd/etcd.conf << EOF
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
ETCD_NAME="master"
#
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.80.201:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.80.201:2379,http://192.168.80.201:4001"
ETCD_INITIAL_CLUSTER="master=http://192.168.80.201:2380,node1=http://192.168.80.196:2380,node2=http://192.168.80.94:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF

80.196：
tee /etc/etcd/etcd.conf << EOF
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
ETCD_NAME="node1"
#
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.80.196:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.80.196:2379,http://192.168.80.196:4001"
ETCD_INITIAL_CLUSTER="master=http://192.168.80.201:2380,node1=http://192.168.80.196:2380,node2=http://192.168.80.94:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF

80.94：
tee /etc/etcd/etcd.conf << EOF
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
ETCD_NAME="node2"
#
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.80.94:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://192.168.80.94:2379,http://192.168.80.94:4001"
ETCD_INITIAL_CLUSTER="master=http://192.168.80.201:2380,node1=http://192.168.80.196:2380,node2=http://192.168.80.94:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
EOF


test:
systemctl enable etcd
systemctl start etcd
etcdctl member list

#Working on all nodes:
etcdctl --endpoints "http://192.168.80.201:2379,http://192.168.80.196:2379,http://192.168.80.94:2379" set /coreos.com/network/config '{"NetWork":"10.244.0.0/16"}'

$ sed -i 's;^FLANNEL_ETCD_ENDPOINTS=.*;FLANNEL_ETCD_ENDPOINTS="http://192.168.80.201:2379,http://192.168.80.196:2379,http://192.168.80.94:2379";g' \
/etc/sysconfig/flanneld

$ sed -i 's;^FLANNEL_ETCD_PREFIX=.*;FLANNEL_ETCD_PREFIX="/coreos.com/network";g' \
/etc/sysconfig/flanneld

201/94:
$ sed -i 's;^ExecStart=.*;ExecStart=/usr/bin/flanneld-start --iface=em1 -etcd-endpoints=${FLANNEL_ETCD_ENDPOINTS} -etcd-prefix=${FLANNEL_ETCD_PREFIX} $FLANNEL_OPTIONS;g' \
/usr/lib/systemd/system/flanneld.service
196:
$ sed -i 's;^ExecStart=.*;ExecStart=/usr/bin/flanneld-start --iface=team0 -etcd-endpoints=${FLANNEL_ETCD_ENDPOINTS} -etcd-prefix=${FLANNEL_ETCD_PREFIX} $FLANNEL_OPTIONS;g' \
/usr/lib/systemd/system/flanneld.service

systemctl daemon-reload
systemctl enable flanneld
systemctl start flanneld
systemctl status flanneld

sed -i -e '/ExecStart=/iEnvironmentFile=/run/flannel/docker' -e 's;^ExecStart=/usr/bin/dockerd;ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTIONS;g' \
/usr/lib/systemd/system/docker.service

#重启docker服务
systemctl daemon-reload
systemctl enable docker
systemctl restart docker


test:
docker run -it --rm --name centos centos bash
docker run -it --rm --privileged --name myCentos centos /usr/sbin/init
进入bash后，ip addr查看各自ip，互相ping一下对方的ip，如果可以ping通，表示安装正常，否则请检查相关的安装步骤。