---
title: Kubernetes Development Environment
date: 2020-12-19 09:27:52
tags: ["Linux"]
toc: true
---

This article will teach us how to set up a development environment in you local machine, including java/k8s/spring cloud kubernetes, etc.

<!-- more -->

## OS

reference: https://docs.microsoft.com/en-us/windows/wsl/install-win10

I'd recommend you base on WSL system to develop, if you don't know what's the wsl, look at [this article](http://blog.gcalls.cn/blog/2020/12/WSL.html)

Installing WSL As below:

```bash
#Step 1 - Enable WSL
#Openning PowerShell as administrotor：
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
#Step 2 - Enable Virtual Machine 
#Openning PowerShell as administrotor：
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
#Step 3 - Downloading Linux Kernel
wget http://aka.ms/wsl2kernelmsix64
#Step 4 - Setting WSL 2 as default
wsl --set-default-version 2
#Step 5 - Installing linux 
Searching proper linux version in Microsoft Store
```

## Windows Terminal 

I'd highly recommend using Windows terminal in Windows 10, it's pretty handly.

Reference: https://docs.microsoft.com/en-us/windows/terminal/get-started

Adding git-bash support：

```bash
{
    "closeOnExit" : true,
    "commandline" : "D:\\Developer\\Git\\bin\\bash.exe --login -i",
    "guid" : "{1d4e097e-fe87-4164-97d7-3ca794c316fd}",
    "icon" : "D:\\Developer\\Git\\git-bash.png",
    "name" : "Bash",
    "startingDirectory" : "%USERPROFILE%"
}
```

## Install Docker(Optional)

If you want to use the remote development environment, don't need it. 

Reference:

- https://docs.docker.com/docker-for-windows/wsl/
- https://kubernetes.io/blog/2020/05/21/wsl-docker-kubernetes-on-the-windows-desktop/

Just need to install Docker-Desktop for Windows, and select the ubuntu at "Setting->Resources/WSL Integration", that's all.

## Installing Kubernetes(Optional)

If you want to use the remote development environment, don't need it. 

Just need to enable kubernetes in "Docker-Desktop Settings", that's all. But you need to set the proxy in the Docker Setting, or you will get the failure by Downloading google's containers.

```
http://192.168.101.175:1082
127.0.0.1,localhost,10.0.0.0/8,172.0.0.0/8,192.168.0.0/16,*.zerofinance.net,*.aliyun.com,*.163.com,*.docker-cn.com,registry.gcalls.cn
```

Enable Ingress Addon:

Reference：https://github.com/docker/for-win/issues/7094

```bash
#https://kubernetes.github.io/ingress-nginx/deploy/#docker-for-mac
 #kubectl.exe create -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/cloud/deploy.yaml
 #Resolved: Unable to connect to the server
 proxy_on
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.41.2/deploy/static/provider/cloud/deploy.yaml
proxy_off
 kubectl apply -f deploy.yaml
```

demo.yaml

```bash
kind: Service
apiVersion: v1
metadata:
  name: hello
  labels:
    app: hello
spec:
  type: NodePort
  ports:
  - protocol: TCP
    name: http
    port: 8080
    targetPort: 8080
  selector:
    app: hello

---

kind: Deployment
apiVersion: apps/v1
metadata:
  name: hello
  labels:
    app: hello
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - name: hello
        # image: paulbouwer/hello-kubernetes:1.8
        image: gcr.io/google-samples/hello-app:1.0
        ports:
        - containerPort: 8080

---

apiVersion: networking.k8s.io/v1beta1 # for versions before 1.14 use extensions/v1beta1
kind: Ingress
metadata:
  name: hello
  # annotations:
  #   nginx.ingress.kubernetes.io/rewrite-target: /$1
    # nginx.ingress.kubernetes.io/whitelist-source-range: 192.168.147.174/32
spec:
  rules:
  - host: hello.info
    http:
      paths:
      - path: /
        backend:
          serviceName: hello
          servicePort: 8080
```

## Remote Kubernetes Environment

I'd recommend installing docker and kubernetes on the remote machine, and all of developers can share it and save some of local resources.

### Docker

Reference: http://blog.gcalls.cn/blog/2018/12/ubuntu-os.html#Docker

### Kubernetes

Recommending microk8s on Linux.

Reference：

https://jiajunhuang.com/articles/2019_11_17-microk8s.md.html
https://microk8s.io/#quick-start
https://microk8s.io/docs
https://www.cnblogs.com/xiao987334176/p/10931290.html

```bash
sudo snap install microk8s --classic
#sudo vim /var/snap/microk8s/current/args/containerd-env
HTTP_PROXY="http://192.168.101.175:1082"
HTTPS_PROXY="http://192.168.101.175:1082"
NO_PROXY="127.0.0.1,localhost,10.0.0.0/8,172.0.0.0/8,192.168.0.0/16,*.zerofinance.net,*.aliyun.com,*.163.com,*.docker-cn.com"
microk8s.start
microk8s status --wait-ready
microk8s.kubectl describe pods -A
#Addons: https://microk8s.io/docs/addons#heading--list
microk8s.enable dashboard dns ingress istio registry storage rbac
microk8s.inspect

#服务端
vim /etc/docker/daemon.json
"insecure-registries" : ["localhost:32000", "192.168.95.233:32000"]
#客户端
"insecure-registries" : ["192.168.95.233:32000"]
#并重启docker

#https://microk8s.io/docs/working-with-kubectl
#Export client's config
cd $HOME
mkdir .kube
cd .kube
microk8s config > config

#~/.bash_profile
alias kubectl=microk8s.kubectl
alias k=kubectl
source <(kubectl completion bash | sed s/kubectl/k/g)
source /usr/share/bash-completion/bash_completion
```

## Local development with Java

参考：

- https://www.telepresence.io/discussion/overview
- https://github.com/cesartl/telepresence-k8s
- https://kubernetes.io/zh/docs/tasks/debug-application-cluster/local-debugging/
- https://cloud.google.com/community/tutorials/developing-services-with-k8s

### Install

https://www.telepresence.io/reference/windows


```bash
#For Windows:
1. Install Windows Subsystem for Linux.
2. Start the BASH.exe program.
3. Install Telepresence by following the Ubuntu instructions above.
>wsl
curl -s https://packagecloud.io/install/repositories/datawireio/telepresence/script.deb.sh | sudo bash
sudo apt install --no-install-recommends telepresence

#For ubuntu:
curl -s https://packagecloud.io/install/repositories/datawireio/telepresence/script.deb.sh | sudo bash
sudo apt install --no-install-recommends telepresence
```

### Usage

- https://anjia0532.github.io/2019/01/21/debug-cloud-native/
- https://www.telepresence.io/tutorials/docker
- https://www.telepresence.io/tutorials/kubernetes
- https://github.com/telepresenceio/telepresence/tree/master/examples/guestbook
- https://github.com/cesartl/telepresence-k8s

```bash
#https://www.telepresence.io/tutorials/java
#kubectl apply -f https://raw.githubusercontent.com/telepresenceio/telepresence/master/docs/tutorials/hello-world.yaml
#kubectl create deployment hello-world --image=datawire/hello-world
#kubectl expose deployment hello-world --type=LoadBalancer --port=8000
#$ curl 127.0.0.1:8000
#Hello, world!
git clone https://github.com/cesartl/telepresence-k8s
cd telepresence-k8s
#Setting up Quote Of the Moment Service
kubectl run qotm --image=datawire/qotm:1.3 --port=5000 --expose
#Basic profile
#Using the basic profile, service disovery using K8S API is disable; The Ribbon client use the service #host name directly:
qotm:
    ribbon:
        listOfServers: qotm:5000

#telepresence --docker-run --rm -it pstauffer/curl -- curl http://hello-world:8000/
#telepresence --new-deployment telepresence-k8s --expose 8080:8080 --run-shell
#telepresence --new-deployment telepresence-k8s --expose 8080 --expose 8081 --run-shell
#telepresence --swap-deployment telepresence-k8s --docker-run --rm -it --name mynginx -p 8080:80 nginx
#telepresence --new-deployment telepresence-k8s --docker-run --rm -it --name mynginx -p 8081:80 nginx
#telepresence --swap-deployment hello-world --expose 8000 --run python3 -m http.server 8000 &
telepresence --new-deployment telepresence-k8s --run-shell

#spring-boot部分版本（2.0.0.RELEASE可以，其他版本不明）通过mvnDebug或者MAVEN_DEBUG_OPTS参数启动时，不支持remote debug:
#cat /Developer/apache-maven-3.3.9/bin/mvnDebug
#MAVEN_DEBUG_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=8000"
>cd /mnt/d/Developer/workspace/telepresence-k8s/
>export PROFILES=basic
>mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8000"
#Preparing to Execute Maven in Debug Mode
#此处会暂停，只到有remote debug过来才会继续往下, 如不希望，可修改以上MAVEN_DEBUG_OPTS中的suspend=n
#Listening for transport dt_socket at address: 8000
#通过eclipse远程debug即可，注意：pom.xml不要开启以下，否则不能远程debug:
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
    <optional>true</optional>
</dependency>
#以上当代码修改时会自动重启，没必要。
#Testing:
curl localhost:8080/rest/quote/cesar
```

### JRebel

```bash
#https://www.jrebel.com/success/products/jrebel/free-trial
#https://www.jrebel.com/products/jrebel/quickstart/eclipse/
#https://www.jrebel.com/products/jrebel/download/prev-releases
#https://manuals.jrebel.com/jrebel/standalone/activate.html
#Plugin for eclipse:
#update site: 
http://update.zeroturnaround.com/update-site
#Download ZIP
http://update.zeroturnaround.com/update-site/update-site.zip

#Crack
#https://www.cnblogs.com/flyrock/archive/2019/09/23/11574617.html
#Generating GUID  from: 
https://www.guidgen.com/
#服务器地址： Pasting the following url on the "Licensing service"
https://jrebel.qekang.com/{GUID}
https://jrebel.qekang.com/d1b8919f-e1e9-4a8d-84da-0c43d75aa970
aaa@bbb.com
#Activation for standalone:
wget https://www.jrebel.com/download/jrebel/496
cd /Developer/jrebel/bin
./activate.sh https://jrebel.qekang.com/d1b8919f-e1e9-4a8d-84da-0c43d75aa970 aaa@bbb.com

#https://manuals.jrebel.com/jrebel/standalone/springboot.html#spring-boot-2-x-using-maven
#https://manuals.jrebel.com/jrebel/standalone/config.html#rebel-xml
#https://www.javazhiyin.com/22460.html
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-agentpath:/Developer/jrebel/lib/libjrebel64.so"
#注意：项目必须位于linux目录下才能生效，如果是/mnt下面的windows目录则不会生效。正常时会有以下提示：
2020-12-14 12:26:33 JRebel: Reloading class 'com.ctl.telepresencek8s.DummyRestController'.
2020-12-14 12:26:38 JRebel: Reconfiguring bean 'dummyRestController' [com.ctl.telepresencek8s.DummyRestController]
```

### demo

- https://github.com/zq2599/blog_demos
- https://xinchen.blog.csdn.net/article/details/92394559
- http://www.mydlq.club/article/31

```bash
#account-service
#mvn clean install fabric8:deploy -Dfabric8.generator.from=fabric8/java-jboss-openjdk8-jdk -Pkubernetes
cd /mnt/d/Developer/workspace/java-k8s/spring-cloud-k8s-account-service
mvn clean install fabric8:deploy -Pkubernetes
#cd /mnt/d/Developer/workspace/java-k8s/spring-cloud-k8s-web-service
#mvn clean install fabric8:deploy -Pkubernetes
#telepresence --swap-deployment web-service --run-shell
telepresence --new-deployment web-service --run-shell
#当为new-deployment时，调用服务时会报： Did not find any endpoints in ribbon in namespace [null] for name [account-service] and portName [null]
#https://github.com/telepresenceio/telepresence/issues/947
export KUBERNETES_NAMESPACE=default
cd /mnt/d/Developer/workspace/java-k8s/spring-cloud-k8s-web-service
#spring-boot部分版本（2.0.0.RELEASE可以，其他版本不明）通过mvnDebug或者MAVEN_DEBUG_OPTS参数启动时，不支持remote debug:
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8000"
curl 127.0.0.1:8080/account
kubectl scale --replicas=0 deployment account-service
```

注意：spring-boot部分版本通过mvnDebug启动时，不支持remote debug，具体原因不明，但可通过以下方式开启remote debug:

#https://docs.spring.io/spring-boot/docs/2.3.4.RELEASE/maven-plugin/reference/html/

```bash
<plugin>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-maven-plugin</artifactId>
    <configuration>
      <jvmArguments>
        -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8000
      </jvmArguments>
    </configuration>
    <executions>
        <execution>
            <goals>
                <goal>repackage</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

或者：

```bash
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8000"
```