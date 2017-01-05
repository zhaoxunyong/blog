---
title: kubernetes常用命令
date: 2017-01-04 09:56:26
categories: ["kubernetes"]
tags: ["kubernetes"]
---
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

#### 动态调整rc replicas
```bash
[root@k8s-master ~]$ kubectl scale rc redis-slave --replicas=3
[root@k8s-master ~]$ kubectl get rc
NAME           DESIRED   CURRENT   AGE
frontend       3         3         2h
redis-master   1         1         2h
redis-slave    3         3         2h
```

#### 创建namespaces
kubectl create -f namespace-dev.yaml
kubectl get pods --namespace=development

## 参考
> http://blog.csdn.net/felix_yujing/article/details/51622132
> [docker与kubectl命令对比](http://www.pangxie.space/docker/157)