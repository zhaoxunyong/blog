---
title: Kubernetes安装Docker registry
date: 2017-10-13 16:06:48
categories: ["Kubernetes","docker"]
tags: ["Kubernetes","docker"]
toc: true
---

记录一下Kubernetes安装Docker registry的过程。

<!-- more -->

## 生成证书
参考[http://blog.gcalls.cn/blog/2017/01/Docker学习总结.html#证书安装方式](http://blog.gcalls.cn/blog/2017/01/Docker学习总结.html#证书安装方式)

```bash
openssl req \
  -subj "/C=CN/ST=GuangDong/L=ShenZhen/CN=registry.gcalls.cn" \
  -reqexts SAN -config <(cat /etc/pki/tls/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:www.abc.com,IP:192.168.10.6")) \
  -newkey rsa:4096 -nodes -sha256 -keyout domain.key \
  -x509 -days 365 -out domain.crt 
```

## ConfigMap
将domain.crt与domain.key通过configmap方式mount在容器中：

registry-configMap.yaml

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: registry-configmap
  namespace: kube-system
  labels:
    app: registry-configmap
data:
  domain.crt: |
    -----BEGIN CERTIFICATE-----
    ...
    -----END CERTIFICATE-----
  domain.key: |
    -----BEGIN PRIVATE KEY-----
    ...
    -----END PRIVATE KEY-----

```

## PV
registry-pv.yaml

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: kube-system-kube-registry-pv
  labels:
    kubernetes.io/cluster-service: "true"
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: /data
  #nfs:
  #  path: /data/k8s
  #  server: 192.168.12.171
  persistentVolumeReclaimPolicy: Recycle
```

## PVC
registry-pvc.yaml

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: kube-registry-pvc
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

## registry-ds

registry-ds.yaml

```yaml
apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: kube-registry-v0
  namespace: kube-system
  labels:
    k8s-app: kube-registry
    version: v0
    kubernetes.io/cluster-service: "true"
spec:
  replicas: 1
  selector:
    matchLabels:
      k8s-app: kube-registry
      version: v0
  template:
    metadata:
      labels:
        k8s-app: kube-registry
        version: v0
        kubernetes.io/cluster-service: "true"
    spec:
      containers:
      - name: registry
        image: registry:2
        resources:
          # keep request = limit to keep this container in guaranteed class
          limits:
            cpu: 100m
            memory: 100Mi
          requests:
            cpu: 100m
            memory: 100Mi
        env:
        - name: REGISTRY_HTTP_ADDR
          value: :5000
        - name: REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY
          value: /var/lib/registry
        - name: REGISTRY_HTTP_TLS_CERTIFICATE
          value: /certs/domain.crt
        - name: REGISTRY_HTTP_TLS_KEY
          value: /certs/domain.key
        volumeMounts:
        - name: image-store
          mountPath: /var/lib/registry
        - name: cert-volume
          mountPath: /certs
        ports:
        - containerPort: 5000
          name: registry
          protocol: TCP
      volumes:
      - name: image-store
        persistentVolumeClaim:
          claimName: kube-registry-pvc
      - name: cert-volume
        configMap:
          name: registry-configmap
```

## registry-svc

registry-svc.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kube-registry
  namespace: kube-system
  labels:
    k8s-app: kube-registry
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "KubeRegistry"
spec:
  selector:
    k8s-app: kube-registry
  type: NodePort
  ports:
  - name: registry
    port: 5000
    nodePort: 30009
    protocol: TCP
```

## 创建

```bash
kubectl create -f registry-configMap.yaml
kubectl create -f registry-pv.yaml
kubectl create -f registry-pvc.yaml
kubectl create -f registry-ds.yaml
kubectl create -f registry-svc.yaml
```

参考[registry.zip](/files/registry.zip)

## 客户端
如果要用docker pull或者docker push的客户端，都需要执行以下命令：
```bash
mkdir -p /etc/docker/certs.d/192.168.10.6:30009
cp domain.crt /etc/docker/certs.d/192.168.10.6:30009/ca.crt
```
否则，会报以下错误：
```bash
Error response from daemon: Get https://192.168.10.6:30009/v1/_ping: x509: certificate signed by unknown authority
```

## 测试
```bash
docker pull hello-world
docker tag hello-world 192.168.10.6:30009/hello-world
docker push 192.168.10.6:30009/hello-world
```

## 异常
如测试出现：
Get https://192.168.10.6:30009/v1/_ping: net/http: TLS handshake timeout
有可以本地与docker开启了代理，需要关闭docker代理或者将ip添加到NO_PROXY中，文件位于：
```bash
/etc/systemd/system/docker.service.d/http-proxy.conf
```

Get https://192.168.10.6:30009/v1/_ping: x509: cannot validate certificate for 192.168.10.6 because it doesn't contain any IP SANs
这个是由于CN为registry.gcalls.cn，但通过ip，需要添加SAN信息：
先/etc/pki/tls/openssl.cnf配置，在该文件中找到[ v3_ca ]，在它下面添加如下内容：
```bash
[ v3_ca ]
# Extensions for a typical CA
subjectAltName = IP:192.168.10.6
```

也可以直接在创建crt时，传-reqexts SAN参数。

## 参考
> https://github.com/kubernetes/kubernetes/blob/v1.7.5/cluster/addons/registry/