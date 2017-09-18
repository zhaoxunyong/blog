---
title: kubernetes常用命令
date: 2017-01-04 09:56:26
categories: ["kubernetes"]
tags: ["kubernetes"]
toc: true
---
本文记录一下kubernetes的常用命令。

<!-- more -->

## kubectl常用使用

### 查看类命令

#### 查看集群信息
```bash
kubectl cluster-info
```

#### 查看各组件信息
```bash
kubectl -s http://localhost:8080 get componentstatuses
```

#### 查看pods所在的运行节点
```bash
kubectl get pods(po) -o wide
kubectl get pod -o wide -n kube-system
kubectl get pods -o wide --all-namespaces
```

#### 查看pods定义的详细信息
```bash
kubectl get pods -o yaml
```

#### 查看Replication Controller信息
```bash
kubectl get rc
```

#### 查看service的信息
```bash
kubectl get service(svc)
```

#### 查看节点信息
```bash
kubectl get nodes(no)
```

#### 按selector名来查找pod
```bash
kubectl get pod --selector name=redis
```

#### 查看运行的pod的环境变量
```bash
kubectl exec pod名 env
```

#### 查看运行的pod的日志
```bash
kubectl logs -f --tail 100 pod名
```

#### 查看pod的endpoint
```bash
[root@k8s-master ~]$ kubectl get endpoints(ep)
```

#### 查看namespaces
```bash
kubectl get namespaces
NAME          STATUS    AGE
default       Active    5h
kube-system   Active    5h
```

### 操作类命令

#### 创建
```bash
kubectl create -f 文件名
```

#### 重建
```bash
kubectl replace -f 文件名  [--force]
```

#### 删除
```bash
kubectl delete -f 文件名
kubectl delete pod pod名
kubectl delete rc rc名
kubectl delete service service名
kubectl delete pod --all
```

#### 删除所有pods
比如需要删除所有的curl实例：参考[https://www.58jb.com/html/155.html](https://www.58jb.com/html/155.html)
```bssh
kubectl get pods --all-namespaces -o wide
NAMESPACE     NAME                                 READY     STATUS    RESTARTS   AGE       IP             NODE
default       curl-57077659-swdxm                  1/1       Running   0          9m        10.244.3.3     k8s-node2
```

先查看对应的rs：
```bash
kubectl get rs
NAME            DESIRED   CURRENT   READY     AGE
curl-57077659   1         1         1         50m
```

再查看对应的deployment：
```bash
kubectl get deployment
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
curl      1         1         1            1           52m
```

需要把deployment删除才行：
```bash
kubectl delete deployment curl
```

#### 动态调整rc replicas
```bash
[root@k8s-master ~]$ kubectl scale rc redis-slave --replicas=3
[root@k8s-master ~]$ kubectl get rc
NAME           DESIRED   CURRENT   AGE
frontend       3         3         2h
redis-master   1         1         2h
redis-slave    3         3         2h
```

#### node unschedule
```bash
[root@k8s-master x86_64]# vim unschedule_node.yaml
apiVersion: v1
kind: Node
metadata:
  name: k8s-node1
  labels:
    kubernetes.io/hostname: k8s-node1
spec:
  unschedulable: true

[root@k8s-master x86_64]# kubectl replace -f unschedule_node.yaml
```
或者：
unschedule:
```bash
[root@k8s-master x86_64]# kubectl patch node k8s-node1 -p '{"spec": {"unschedulable": true}}'

[root@k8s-master x86_64]# kubectl get no
NAME        STATUS                     AGE
127.0.0.1   NotReady                   8d
k8s-node1   Ready,SchedulingDisabled   8d
k8s-node2   Ready                      8d
```
schedule:
```bash
[root@k8s-master x86_64]# kubectl patch node k8s-node1 -p '{"spec": {"unschedulable": false}}'
```

#### 动态调用deployment
```bash
kubectl scale deployment elasticsearch --replicas=1 -n kube-system
```

#### 创建namespaces
```bash
kubectl create -f namespace-dev.yaml
kubectl get pods --namespace=development
```

