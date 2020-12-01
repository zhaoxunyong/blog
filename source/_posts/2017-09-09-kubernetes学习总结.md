---
title: kubernetes学习总结
date: 2017-09-09 19:09:16
categories: ["kubernetes"]
tags: ["kubernetes"]
toc: true
---
本文记录一下kubernetes的常用功能。

<!-- more -->

## DaemonSet

DaemonSet能够让所有（或者一些特定）的Node节点运行同一个pod。当节点加入到kubernetes集群中，pod会被（DaemonSet）调度到该节点上运行，当节点从kubernetes集群中被移除，被（DaemonSet）调度的pod会被移除，如果删除DaemonSet，所有跟这个DaemonSet相关的pods都会被删除。

在使用kubernetes来运行应用时，很多时候我们需要在一个区域（zone）或者所有Node上运行同一个守护进程（pod），例如如下场景：

每个Node上运行一个分布式存储的守护进程，例如glusterd，ceph
运行日志采集器在每个Node上，例如fluentd，logstash
运行监控的采集端在每个Node，例如prometheus node exporter，collectd等
在简单的情况下，一个DaemonSet可以覆盖所有的Node，来实现Only-One-Pod-Per-Node这种情形；在有的情况下，我们对不同的计算几点进行着色，或者把kubernetes的集群节点分为多个zone，DaemonSet也可以在每个zone上实现Only-One-Pod-Per-Node。

## Deployment
Kubernetes Deployment提供了官方的用于更新Pod和Replica Set（下一代的Replication Controller）的方法，您可以在Deployment对象中只描述您所期望的理想状态（预期的运行状态），Deployment控制器为您将现在的实际状态转换成您期望的状态，例如，您想将所有的webapp:v1.0.9升级成webapp:v1.1.0，您只需创建一个Deployment，Kubernetes会按照Deployment自动进行升级。现在，您可以通过Deployment来创建新的资源（pod，rs，rc），替换已经存在的资源等。

Deployment集成了上线部署、滚动升级、创建副本、暂停上线任务，恢复上线任务，回滚到以前某一版本（成功/稳定）的Deployment等功能，在某种程度上，Deployment可以帮我们实现无人值守的上线，大大降低我们的上线过程的复杂沟通、操作风险。



Deployment的使用场景

 下面是Deployment的典型用例：

使用Deployment来启动（上线/部署）一个Pod或者ReplicaSet
检查一个Deployment是否成功执行
更新Deployment来重新创建相应的Pods（例如，需要使用一个新的Image）
如果现有的Deployment不稳定，那么回滚到一个早期的稳定的Deployment版本
暂停或者恢复一个Deployment
 

kind: 定义的对象： Replicationcontroller,  ReplicaSet  Deployment 区别

Replicationcontroller 的升级版是 ReplicaSet , ReplicaSet支持基于集合的 Label selector, 而RC只支持基于等式的 Lable select

Deployment其实就是内部调用 ReplicaSet.

DaemonSet 根据标签指定pod 在那个服务器上运行，需要与nodeselect 公用。

server定义的selector 与 Deployment 中的 template 的 lables 对应：
```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: tomcat-deployment
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: tomcat
        tier: frontend
    spec:
      #hostNetwork: true
      containers:
      - name: tomcat
        image: tomcat:8.5.20
        ports:
        - containerPort: 8080
          #hostPort: 80
        volumeMounts:
        - name: workdir
          mountPath: /opt
      volumes:
      - name: workdir
        emptyDir: {}
        #hostPath:
        #  path: "/data/works/tomcat/logs"

---
apiVersion: v1
kind: Service
metadata:
  name: tomcat-server
spec:
  type: NodePort
  ports:
  - port: 11111   # cluster IP 的端口，也就是service的ip，默认为containerPort
    targetPort: 8080  # container容器的端口
    nodePort: 30001
  selector:
    tier: frontend
#  externalIPs: 
#  - 192.168.10.6
#  - 192.168.10.7
#  - 192.168.10.8
```

## 外部系统访问service 问题

kubernetes 中三种IP 包括

> 1. NodeIP   node节点的IP地址
> 2. PodIP     pod的IP地址
> 3. clusterIP   service的IP地址

nodeIP 是kubernetes集群中每个节点的物理网卡的IP地址， client 访问kubernetes集群使用的IP地址。
Pod ip地址 是更具创建的网络类型，网桥分配的IP地址。
clusterIP 是一个虚拟的IP， cluster ip 仅作用于kubernetes service 这个对象， 是由kubernetes管理和分配ip地址，源于cluster ip地址池：

```yaml
[root@kubernetes nginx]# vim /etc/kubernetes/apiserver
# Address range to use for services
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"
```

cluster IP 无法ping通， 因为没有一个实体网络对象响应；

cluster ip 只能结合 service port 组成一个具体的通信接口，单独的cluster IP不具备tcp/ip通信基础；

如果 pod 对外访问，需要在servcie 中 指定 type 为 NodePort；

```bash
[root@k8s-master yaml]# kubectl describe service tomcat-server
Name:                   tomcat-server
Namespace:              default
Labels:                 <none>
Annotations:            <none>
Selector:               tier=frontend
Type:                   NodePort
IP:                     10.100.53.62
Port:                   <unset> 11111/TCP
NodePort:               <unset> 30002/TCP
Endpoints:              10.244.36.10:8080,10.244.36.13:8080,10.244.36.7:8080 + 1 more...
Session Affinity:       None
Events:                 <none>
```

访问node IP ＋　node port ,可以访问页面。

nodeport 并没有完全解决外部访问service 的问题， 比如负载均衡问题，如果有10 pod 节点， 如果是用谷歌的GCE公有云，那么可以把 service  type=NodePort 修改为 LoadBalancer。

另外也可以通过设置pod(daemonset) hostNetwork=true, 将pod中所有容器的端口号直接映射到物理机上， 设置hostNetwork=true的时候需要注意，如果不指定hostport，默认hostport 等于containerport, 如果指定了hostPort, 则hostPort 必须等于containerPort的值。


## deployment创建部署

### 命令行方式

#### 创建deployment
类似于docker run方式：
```bash
[root@k8s-master ~]# kubectl create deploy --image=nginx:1.12.1 nginx-app
deployment.apps/nginx-app created

[root@k8s-master ~]# kubectl get deploy nginx-app   
NAME        DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx-app   1         1         1            1           1m
[root@k8s-master ~]# kubectl get pod |grep nginx-app
nginx-app-2778402574-zv4r6           1/1       Running       0          1m
```

以上实际上创建的是一个由deployment来管理的Pod。

kubectl run并不是直接创建一个Pod，而是先创建一个Deployment资源（replicas=1），再由与Deployment关联的ReplicaSet来自动创建Pod，这等价于这样一个配置：
```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    run: nginx-app
  name: nginx-app
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      run: nginx-app
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      labels:
        run: nginx-app
    spec:
      containers:
      - image: nginx
        name: nginx-app
        ports:
        - containerPort: 80
          protocol: TCP
      dnsPolicy: ClusterFirst
      restartPolicy: Always
```

等到容器变成Running后，就可以用kubectl命令来操作它了，比如

- kubectl get - 类似于docker ps，查询资源列表
- kubectl describe - 类似于docker inspect，获取资源的详细信息
- kubectl logs - 类似于docker logs，获取容器的日志
- kubectl exec - 类似于docker exec，在容器内执行一个命令

也可以通过api访问：
node:
```bash
https://192.168.10.6:6443/api/v1/nodes
```

namespaces:
```bash
https://192.168.10.6:6443/api/v1/namespaces
```

pods:
```bash
https://192.168.10.6:6443/api/v1/pods
```

services:
```bash
https://192.168.10.6:6443/api/v1/services
https://192.168.10.6:6443/api/v1/namespaces/default/services/nginx-app
```

endpoint:
```bashh
https://192.168.10.6:6443/api/v1/endpoints
https://192.168.10.6:6443/api/v1/namespaces/default/endpoints/nginx-app
```

#### 创建Service

前面虽然创建了Pod，但是在kubernetes中，Pod的IP地址会随着Pod的重启而变化，并不建议直接拿Pod的IP来交互。那如何来访问这些Pod提供的服务呢？使用Service。Service为一组Pod（通过labels来选择）提供一个统一的入口，并为它们提供负载均衡和自动服务发现。比如，可以为前面的nginx-app创建一个service：
```bash
$ kubectl expose deployment nginx-app --port=80 --target-port=80 --type=NodePort
service "nginx-app" exposed
$ kubectl describe service nginx-app
Name:  			nginx-app
Namespace:     		default
Labels:			run=nginx-app
Selector:      		run=nginx-app
Type:  			ClusterIP
IP:    			10.0.0.66
Port:  			<unset>	80/TCP
NodePort:      		<unset>	30772/TCP
Endpoints:     		172.17.0.3:80
Session Affinity:      	None
No events.
```

该命令不能设置nodePort，如果需要指定nodePort，需要通过kubectl edit service nginx-app修改：
```yaml
...
spec:
  clusterIP: 10.97.111.200
  ports:
  - nodePort: 31798
    port: 80
    protocol: TCP
    targetPort: 80
    nodePort: 32222
...
```

测试：
```bash
[root@k8s-master ~]# kubectl get svc
NAME            CLUSTER-IP       EXTERNAL-IP   PORT(S)           AGE
nginx-app       10.97.111.200    <nodes>       80:32222/TCP      10m

[root@k8s-master ~]# kubectl run busybox --rm -ti --image=busybox --restart=Never /bin/sh
#以上每次退出后会自动删除images中的镜像，每次执行都会重新下载image，所以每次执行都会有些慢。
If you don't see a command prompt, try pressing enter.
/ # ping nginx-app
PING nginx-app (10.97.111.200): 56 data bytes
^C
--- nginx-app ping statistics ---
1 packets transmitted, 0 packets received, 100% packet loss
```


这样，在cluster内部就可以通过http://10.97.111.200和http://node-ip:32222来访问nginx-app。
而在cluster外面，则只能通过http://node-ip:32222来访问。


### deployment部署文件
```bash
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
        tier: frontend
    spec:
      #hostNetwork: true
      containers:
      - name: nginx
        image: nginx:1.12.1
        ports:
        - containerPort: 80
          #hostPort: 80
        volumeMounts:
        - name: workdir
          mountPath: /opt
      volumes:
      - name: workdir
        emptyDir: {}
        #emptyDir:
        #  medium: Memory
        #hostPath:
        #  path: "/data/works/nginx/logs"

---
apiVersion: v1
kind: Service
metadata:
  name: nginx-server
spec:
  type: NodePort
  ports:
  - port: 22222   # cluster IP 的端口
    targetPort: 80  # container容器的端口
    nodePort: 30002
  selector:
    tier: frontend
#  externalIPs: 
#  - 192.168.10.6
#  - 192.168.10.7
#  - 192.168.10.8
```

容易混淆的概念：
1、NodePort和port

前者是将服务暴露给外部用户使用并在node上、后者则是为内部组件相互通信提供服务的，是在service上的端口。

2、targetPort
targetPort是pod上的端口，用来将pod内的container与外部进行通信的端口

3、port、NodePort、ContainerPort和targetPort在哪儿？

port在service上，负责处理对内的通信，clusterIP:port

NodePort在node上，负责对外通信，NodeIP:NodePort

ContainerPort在容器上，用于被pod绑定

targetPort在pod上、负责与kube-proxy代理的port和Nodeport数据进行通信

### 创建
```bash
kubectl create -f nginx.yaml
```

### 查看状态
```bash
[root@k8s-master yaml]# kubectl get deploy nginx -o wide           
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINER(S)   IMAGE(S)       SELECTOR
nginx     1         1         1            1           1d        nginx          nginx:1.12.1   app=nginx
```

DESIRED 期望的副本数
CURRENT 当前副本数
UP-TO-DATA 最新副本数
AVALLABLE  可用副本数

### 删除
```bash
kubectl delete -f nginx.yaml
```

如果没有原始的yaml，有两种方式可以删除：

先删除deployment:
```bash
[root@k8s-master ~]# kubectl get deploy
NAME                DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
nginx               1         1         1            1           30m

kubectl delete deploy nginx
#或者
kubectl delete deployment/nginx
```

再删除service:
```bashh
[root@k8s-master ~]# kubectl get svc
NAME            CLUSTER-IP       EXTERNAL-IP   PORT(S)           AGE
nginx           10.100.125.137   <nodes>       80:32222/TCP      10m

kubectl delete service nginx
```

另外一种方式可以先把deployment与service生成yaml，再通过yaml文件生成：
```bash
kubectl get deploy,svc nginx-app -o yaml > nginx-app.yaml
kubectl delete -f nginx.yaml
```

### 使用RS管理Pod

Replica Set（简称RS）是k8s新一代的Pod controller。与RC相比仅有selector存在差异，RS支持了set-based selector（可以使用in、notin、key存在、key不存在四种方式来选择满足条件的label集合）。Deployment是基于RS实现的，我们可以使用kubectl get rs命令来查看Deployment创建的RS：
```bash
[root@k8s-master ~]# kubectl get rs    
NAME                           DESIRED   CURRENT   READY     AGE
nginx-app-2778402574           1         1         1         34m
```

由Deployment创建的RS的命名规则为"<Deployment名称>-<pod template摘要值>"。

### 更新部署
（镜像升级）：
把image镜像从 nginx:1.12.1 升级到 nginx:1.13
kubectl set image deployment/tomcat-deployment nginx=nginx:1.13

### 直接使用edit 修改
```bash
kubectl edit deployment/nginx-deployment
```

### 扩展副本数
```bash
kubectl scale deployment nginx-deployment --replicas=3
```

## kubernetes volume
（存储卷）:

### emptyDir
EmptyDir类型的volume创建于pod被调度到某个宿主机上的时候，而同一个pod内的容器都能读写EmptyDir中的同一个文件。一旦这个pod离开了这个宿主机，EmptyDirr中的数据就会被永久删除。所以目前EmptyDir类型的volume主要用作临时空间，比如Web服务器写日志或者tmp文件需要的临时目录。
默认的，emptyDir 磁盘会存储在主机所使用的媒介上，可能是SSD，或者网络硬盘，这主要取决于你的环境。当然，我们也可以将emptyDir.medium的值设置为Memory来告诉Kubernetes 来挂在一个基于内存的目录tmpfs，因为tmpfs速度会比硬盘块度了，但是，当主机重启的时候所有的数据都会丢失。
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: gcr.io/google_containers/test-webserver
    name: test-container
    volumeMounts:
    - mountPath: /cache
      name: cache-volume
  volumes:
  - name: cache-volume
    #emptyDir: {}
    emptyDir:
      medium: Memory
```

### hostPath
为在pod上挂载宿主机上的文件或者目录
```yaml
    spec:
      #hostNetwork: true
      containers:
      - name: tomcat
        image: tomcat:8.5.20
        ports:
        - containerPort: 8080
          #hostPort: 80
        volumeMounts:
        - name: workdir
          mountPath: /opt
      volumes:
      - name: workdir
        hostPath:
          path: "/data/works/tomcat/logs"
```

### nfs
使用nfs网络文件服务器提供的共享目录存储数据时，需要部署一个nfs server，定义nfs类型volume 如：
```yaml
        volumeMounts:
        - name: workdir
          nfs:
            server: nfs-server
            path: "/"
```

## Namespace 
命名空间
Namespace 在很多情况下用于多租户的资源隔离，Namespace通过将集群内部的资源对象“分配”到不通的Namespace中， 形成逻辑上的分组的不同项目，小组或者 用户组，便于不同的分组在共享使用这个集群的资源的同时还能被分别管理。
如果不特别指明namespace，则用户创建的 pod rc service 都将被系统创建到defalut中

kubernetes集群在启动后，会创建一个 default 的 namespace:
```bash
[root@k8s-master ~]# kubectl get namespace
NAME          STATUS    AGE
default       Active    6d
kube-public   Active    6d
kube-system   Active    6d
monitoring    Active    2d
sock-shop     Active    5d
xxx           Active    5d
```

如果不特别指明namespace，则用户创建的 pod rc service 都将被系统创建到defalut中。
创建namespace：
```bash
#创建fengjian20170221 的命名空间
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring

---

apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: tomcat-deployment
  namespace: monitoring
...
```

## ConfigMap
configmap 供容器使用的典型方案如下：

1. 生成为容器内的环境变量
2. 设置容器启动命令的启动参数
3. 以volume的形式挂载为容器内部的文件或者目录
4: 注意必须先创建 configMap, 然后pod 才能创建，如果已经创建的pod，升级，环境变量无法找到，一定要做好提前规划。

### 生成为容器内的环境变量
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: testenv
#  namespace: test
data:
  mysql_server: 192.168.10.1
  redis_server: 192.168.20.1
  mongo_server: 192.168.30.1
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
  selector:
    app: nginx
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx
#  namespace: test
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.12.1
        ports:
        - containerPort: 80
        env:
        - name: mysql_server
          valueFrom:
            configMapKeyRef:
              name: testenv
              key: mysql_server
        - name: redis_server
          valueFrom:
            configMapKeyRef:
              name: testenv
              key: redis_server
        - name: mongo_server
          valueFrom:
            configMapKeyRef:
              name: testenv
              key: mongo_server
```

### mount的方式
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: db-hosts
data:
  hosts: |
    192.168.10.6  k8s-master
    192.168.10.7  k8s-node1
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
  selector:
    app: nginx
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx
#  namespace: test
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      volumes:
      - name: hosts-volume
        configMap:
          name: db-hosts

      containers:
      - name: nginx
        image: nginx:1.12.1
        ports:
        - containerPort: 80

        volumeMounts:
        - name: hosts-volume
          mountPath: /mnt/hosts.append
      restartPolicy: Always
```

查询mount的内容：
```bash
[root@k8s-master yaml]# kubectl exec nginx-1688079652-917zh cat /mnt/hosts.append/hosts                      
192.168.10.6  k8s-master
192.168.10.7  k8s-node1
```

查询所有的configmap：
```bash
[root@k8s-master yaml]# kubectl get configmap
NAME             DATA      AGE
db-hosts         1         1d
special-config   2         3d
```

## Nginx Ingress
Kubernetes 暴露服务的方式目前只有三种：LoadBlancer Service、NodePort Service、Ingress。

### 部署默认后端
我们知道 前端的 Nginx 最终要负载到后端 service 上，那么如果访问不存在的域名咋整？官方给出的建议是部署一个 默认后端，对于未知请求全部负载到这个默认后端上；这个后端啥也不干，就是返回 404，部署如下：
```bash
wget https://raw.githubusercontent.com/kubernetes/ingress/master/examples/deployment/nginx/default-backend.yaml
kubectl create -f default-backend.yaml
```

### 部署Ingress Controller
部署完后端就得把最重要的组件Nginx Ingres Controller部署：
```bash
wget https://raw.githubusercontent.com/kubernetes/ingress/master/examples/daemonset/nginx/nginx-ingress-daemonset.yaml
kubectl create -f nginx-ingress-daemonset.yaml
```

注意：如果需要nginx controller监听80端口的话，需要添加hostNetwork: true的参数：
```yaml
    spec:
      terminationGracePeriodSeconds: 60
      hostNetwork: true
      ...
```

也可以采用deployment方式，参考[https://github.com/kubernetes/ingress/tree/master/examples/deployment/nginx](https://github.com/kubernetes/ingress/tree/master/examples/deployment/nginx)。

### 部署Ingress
希望通过frontend.zhaoxy.com访问frontend:80的服务，nginx.zhaoxy.com访问nginx-app:80的服务：
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: web-ingress
  namespace: default
spec:
  rules:
  - host: frontend.zhaoxy.com
    http:
      paths:
      - backend:
          serviceName: frontend
          servicePort: 80
  - host: nginx.zhaoxy.com
    http:
      paths:
      - backend:
          serviceName: nginx-app
          servicePort: 80
```

### 查看ingress状态
```bash
[root@k8s-master yaml]# kubectl get ing -o wide
NAME          HOSTS                                                 ADDRESS                     PORTS     AGE
web-ingress   www.zhaoxy.com,frontend.zhaoxy.com,nginx.zhaoxy.com   192.168.10.6,192.168.10.7   80        21m
```

完成后我们可以通过keppalived对nginx做集群即可。

## 部署Traefik
参考[http://huxos.me/kubernetes/2017/09/19/kubernetes-cluster-07-ingress.html](http://huxos.me/kubernetes/2017/09/19/kubernetes-cluster-07-ingress.html)
Ingress的引入主要解决创建入口站点规则的问题，主要作用于7层入口(http)。 可以通过K8s的Ingress对象定义类似于nginx中的vhost、localtion、upstream等。 Nginx官方也有Ingress的实现nginxinc/kubernetes-ingress来对接k8s。

考虑到[Traefik](https://github.com/containous/traefik)部署较为方便，使用traefik提供Ingress服务。

![traefik](/images/traefik.png)

### 定义traefik需要的RBAC规则

traefik-rbac.yaml:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik-ingress-controller
  namespace: kube-system
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: traefik-ingress-controller
rules:
  - apiGroups:
      - ""
    resources:
      - pods
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: traefik-ingress-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik-ingress-controller
subjects:
- kind: ServiceAccount
  name: traefik-ingress-controller
  namespace: kube-system

```

### 定义ingress编排的daemonset模版

traefik-daemonset.yaml:

```yaml
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  labels:
    k8s-app: traefik-ingress-lb
  name: traefik-ingress-controller
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: traefik-ingress-lb
  template:
    metadata:
      labels:
        k8s-app: traefik-ingress-lb
        name: traefik-ingress-lb
    spec:
      containers:
      - args:
        - --web
        - --web.address=:8580
        - --kubernetes
        - --web.metrics
        - --web.metrics.prometheus
        image: traefik
        imagePullPolicy: IfNotPresent
        name: traefik-ingress-lb
        ports:
        - containerPort: 80
          hostPort: 80
          protocol: TCP
        - containerPort: 8580
          hostPort: 8580
          protocol: TCP
        resources:
          requests:
            #cpu: "2"
            memory: 512M
      dnsPolicy: ClusterFirst
      hostNetwork: true
      nodeSelector:
        role: ingress
      restartPolicy: Always
      schedulerName: default-scheduler
      serviceAccount: traefik-ingress-controller
      serviceAccountName: traefik-ingress-controller
      terminationGracePeriodSeconds: 60
```

### 创建ingress规则

traefik-ingress.yaml:

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: metadata 
  namespace: default
spec:
  rules:
  - host: a.zhaoxy.com
    http:
      paths:
      - backend:
          serviceName: nginx-app 
          servicePort: 80
```

### 创建
参考[traefik.zip](/files/traefik.zip)
```bash
kubectl create -f ./
```

### 访问

这样其实相当于定义了一个http的站点，域名a.zhaoxy.com指向了default的metadata-server这个服务。
访问相关节点的8580端口就能看到a.zhaoxy.com站点对应的信息了。

可以通过http://a.zhaoxy.com访问nginx-app的80服务。
可以通过http://a.zhaoxy.com:8580/dashboard/访问监控服务。

![traefik-dashboard](/images/traefik-dashboard.png)

## 最新命令汇总

```
minikube addons list
minikube addons enable ingress
minikube addons enable heapster
kubectl top node
kubectl top pod --all-namespaces
kubectl cluster-info
minikube service monitoring-grafana -n kube-system
kubectl get pod --watch
kubectl delete all --all
k get pod --show-labels
k label pod xxx app=foo --overwrite

#Creating by commands
kubectl create deployment kubia --image=luksa/kubia
#kubectl expose deployment kubia --type=NodePort --name kubia-http --port=80
kubectl expose deployment kubia --type=LoadBalancer --name kubia-http --port=80
minikube service kubia-http --url

#Creating by yaml
#kubia-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kubia
spec:
  replicas: 2
  #指定新创建的pod至少要成功运行多久才视为可用
  #让k8s在pod就绪之后继续等待10秒后，才继续执行滚动升级
  minReadySeconds: 10
  revisionHistoryLimit: 8
  progressDeadlineSeconds: 10
  strategy:
    rollingUpdate:
      maxSurge: 1
      #0确保升级过程中pod被挨个替换
      maxUnavailable: 0
    type: RollingUpdate
  template:
    metadata:
      name: kubia
      labels:
        app: kubia
    spec:
      containers:
        - name: nodejs
          image: luksa/kubia:v2
          readinessProbe:
            periodSeconds: 1
            httpGet:
              path: /
              port: 8080
  selector:
    matchLabels:
      app: kubia

#--record会记录历史版本号
kubectl create -f kubia-deployment.yaml --record

#kubia-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia-http
spec:
#   sessionAffinity: ClientIP
#  type: NodePort
#  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
#      nodePort: 30123
  selector:
    app: kubia
  sessionAffinity: ClientIP

#kubia-ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kubia
spec:
  rules:
    - host: kubia.example.com
      http:
        paths:
          - path: /kubia # 将 /kubia 子路径请求转发到 kubia-nodeport 服务的 80 端口
            backend:
              serviceName: kubia-http
              servicePort: 80

#Rollout
kubectl create -f kubia-deployment.yaml --record
#kubectl scale deployment kubia --replicas=3
kubectl set image deployment kubia nodejs=luksa/kubia:v3
kubectl rollout pause deployment kubia
kubectl rollout resume deployment kubia
kubectl rollout status deployment kubia
kubectl rollout history deployment kubia
kubectl rollout undo deployment kubia --to-revision=1
kubectl patch deployment kubia -p '{"spec": {"revisionHistoryLimit": 5}}'
#指定新创建的pod至少要成功运行多久才视为可用,让k8s在pod就绪之后继续等待10秒后，才继续执行滚动升级
kubectl patch deployment kubia -p '{"spec": {"minReadySeconds": 10}}'
#滚动失败的超时时间
kubectl patch deployment kubia -p '{"spec": {"progressDeadlineSeconds": 15}}'
#将本地网络端口转发到pod中的端口
kubectl port-forward kubia-7d46fb6687-86th4 8888:8080
kubectl port-forward service/hello-minikube 7080:8080
```

## Example

```bash
#Example:
#https://learnk8s.io/spring-boot-kubernetes-guide
docker network create knote
docker run \
  --name=mongo \
  --rm \
  --network=knote \
  mongo
docker run \
  --name=knote-java \
  --rm \
  --network=knote \
  -p 8080:8080 \
  -e MONGO_URL=mongodb://mongo:27017/dev \
  learnk8s/knote-java:1.0.0

#https://spring.io/guides/gs/spring-boot-kubernetes/
$ kubectl create deployment demo --image=springguides/demo --dry-run -o=yaml > deployment.yaml
$ echo --- >> deployment.yaml
$ kubectl create service clusterip demo --tcp=8080:8080 --dry-run -o=yaml >> deployment.yaml

#https://spring.io/guides/topicals/spring-on-kubernetes/
```

## 参考
> http://blog.csdn.net/felix_yujing/article/details/51622132
> [docker与kubectl命令对比](http://www.pangxie.space/docker/157)
> http://www.cnblogs.com/fengjian2016/p/6423455.html
> https://github.com/feiskyer/kubernetes-handbook/blob/master/introduction/101.md
> http://blog.csdn.net/xts_huangxin/article/details/51891709
> https://www.stratoscale.com/blog/kubernetes/kubernetes-exposing-pods-service/
> http://blog.csdn.net/u012804178/article/category/6861460
> http://feisky.xyz/2016/09/11/Kubernetes%E4%B8%AD%E7%9A%84%E6%9C%8D%E5%8A%A1%E5%8F%91%E7%8E%B0%E4%B8%8E%E8%B4%9F%E8%BD%BD%E5%9D%87%E8%A1%A1/
> http://dockone.io/article/2247
> https://www.kubernetes.org.cn/%E6%96%87%E6%A1%A3%E4%B8%8B%E8%BD%BD
> http://kubernetes.kansea.com/docs/
> https://www.kubernetes.org.cn/1885.html
> https://mritd.me/2017/03/04/how-to-use-nginx-ingress
> http://huxos.me/kubernetes/2017/09/19/kubernetes-cluster-07-ingress.html


