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

Installing WSL as below:

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

## Install Local Docker(Optional)

If you want to use the remote development environment, don't need it. 

Reference:

- https://docs.docker.com/docker-for-windows/wsl/
- https://kubernetes.io/blog/2020/05/21/wsl-docker-kubernetes-on-the-windows-desktop/

Just need to install Docker-Desktop for Windows, and select the ubuntu at "Setting->Resources/WSL Integration", that's all.

## Install Local Kubernetes(Optional)

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

Ubuntu Reference: http://blog.gcalls.cn/blog/2018/12/ubuntu-os.html#Docker

For CentOS:

```bash
#https://www.cnblogs.com/763977251-sg/p/11837130.html
#Docker installation
#https://aka.ms/vscode-remote/samples/docker-from-docker
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sudo yum makecache fast
sudo yum -y install docker-ce
```

### Kubernetes

#### microk8s

Recommend using microk8s on Linux. It's the best performance.

Reference：

https://jiajunhuang.com/articles/2019_11_17-microk8s.md.html
https://microk8s.io/#quick-start
https://microk8s.io/docs
https://www.cnblogs.com/xiao987334176/p/10931290.html

```bash
#For ubuntu:
https://blog.flyfox.top/2020/04/03/microk8s%E5%AE%89%E8%A3%85%E6%95%99%E7%A8%8B/
#For centos7:
#sudo yum install epel-release
sudo su - dev
sudo yum install snapd
sudo systemctl enable --now snapd.socket
sudo ln -s /var/lib/snapd/snap /snap
sudo snap install microk8s --classic
#Notice: microk8s is using containerd, not docker any more.
#Either log out and back in again or restart your system to ensure 
sudo vim /var/snap/microk8s/current/args/containerd-env
HTTP_PROXY="http://192.168.101.175:1082"
HTTPS_PROXY="http://192.168.101.175:1082"
NO_PROXY="127.0.0.1,localhost,10.0.0.0/8,172.0.0.0/8,192.168.0.0/16,*.zerofinance.net,*.aliyun.com,*.163.com,*.docker-cn.com,registry.gcalls.cn"
sudo systemctl list-unit-files |grep -i microk8s
sudo systemctl restart snap.microk8s.daemon-containerd.service
microk8s.start
#Addons: https://microk8s.io/docs/addons#heading--list
#microk8s.enable dashboard dns ingress istio registry storage rbac
microk8s.enable dashboard dns ingress storage
microk8s status --wait-ready
#list all of enabled addons
microk8s status
microk8s.kubectl describe pods -A
microk8s.inspect

kubectl cluster-info
Kubernetes master is running at https://192.168.95.234:16443
Metrics-server is running at https://192.168.95.234:16443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

CoreDNS is running at https://192.168.95.234:16443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.



#bashboard:
#https://medium.com/@junya.kaneko/quick-way-of-using-kubernetes-dashboard-on-microk8s-9c7b0e26be02
#Skip login
microk8s kubectl edit deployment/kubernetes-dashboard -n kube-system
spec:
    containers:
    - args:
    - --auto-generate-certificates
    - --namespace=kube-system
    - --enable-skip-login

microk8s kubectl create clusterrolebinding kubernertes-dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
microk8s kubectl proxy --accept-hosts=.* --address=0.0.0.0
http://192.168.80.98:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#/login
token=$(microk8s kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
echo $token
microk8s kubectl -n kube-system describe secret $token

#uninstall microk8s
sudo snap remove microk8s
rm -fr /root/snap/microk8s /home/dev/snap/microk8s

#https://microk8s.io/docs/working-with-kubectl
#Export the config for clients
cd $HOME
mkdir .kube
cd .kube
microk8s config > config

#~/.bash_profile
#yum install bash-completion -y 
~/.bash_profile
alias k=kubectl
source <(kubectl completion bash | sed s/kubectl/k/g)
#source /usr/share/bash-completion/bash_completion

#Kubectl installation:
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.19.4/bin/linux/amd64/kubectl
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

#OR
#Kubectl For CentOS
#https://blog.csdn.net/nklinsirui/article/details/80581286
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum install -y kubectl
#Kubectl For Ubuntu
#https://blog.csdn.net/nklinsirui/article/details/80581286
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
echo "deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main" >> /etc/apt/sources.list
apt-get update
apt-get install -y kubectl
```

#### Harbor

Harbor is an open source trusted cloud native registry project that stores, signs, and scans content. Harbor extends the open source Docker Distribution by adding the functionalities usually required by users such as security, identity and management. Having a registry closer to the build and run environment can improve the image transfer efficiency. Harbor supports replication of images between registries, and also offers advanced security features such as user management, access control and activity auditing.

```bash
#Habor:
#Using root enviroment:
sudo yum install python3-pip
#root
pip3 install -U docker-compose
#non-root
#pip3 install --user docker-compose
#https://goharbor.io/docs/2.1.0/install-config/configure-https/
#Generating the certificate:
#Using dev enviroment:
sudo su - dev
export DP_Id=""
export DP_Key=""
acme.sh --issue --dns dns_dp -d gcalls.cn -d *.gcalls.cn
#acme.sh --issue --dns dns_dp -d registry.gcalls.cn --keylength ec-256
Your cert is in  /home/dev/.acme.sh/gcalls.cn/gcalls.cn.cer 
Your cert key is in  /home/dev/.acme.sh/gcalls.cn/gcalls.cn.key 
The intermediate CA cert is in  /home/dev/.acme.sh/gcalls.cn/ca.cer 
The full chain certs is there:  /home/dev/.acme.sh/gcalls.cn/fullchain.cer

sudo mkdir -p /etc/docker/certs.d/registry.gcalls.cn
sudo cp /home/dev/.acme.sh/gcalls.cn/gcalls.cn.cer /etc/docker/certs.d/registry.gcalls.cn/
#must be gcalls.cn.cert
sudo cp /home/dev/.acme.sh/gcalls.cn/fullchain.cer /etc/docker/certs.d/registry.gcalls.cn/gcalls.cn.cert
sudo cp /home/dev/.acme.sh/gcalls.cn/gcalls.cn.key /etc/docker/certs.d/registry.gcalls.cn/
sudo cp /home/dev/.acme.sh/gcalls.cn/ca.cer /etc/docker/certs.d/registry.gcalls.cn/
cp -a harbor-offline-installer-v2.1.2.tgz /works/k8s/
cd /works/k8s/
tar zxvf harbor-offline-installer-v2.1.2.tgz
sudo chown -R dev.dev /works/k8s/harbor
#https://goharbor.io/docs/2.1.0/install-config/configure-yml-file/
#Modifying the harbor.yml
vim harbor.yml:
hostname: registry.gcalls.cn
https:
  # The path of cert and key files for nginx
  #certificate: /home/dev/.acme.sh/gcalls.cn/gcalls.cn.cer
  certificate: /etc/docker/certs.d/registry.gcalls.cn/gcalls.cn.cert
  private_key: /home/dev/.acme.sh/gcalls.cn/gcalls.cn.key
 #Execting the script 
./prepare
sudo su - root
cd /works/k8s/harbor
#https://goharbor.io/docs/2.1.0/install-config/run-installer-script/
./install.sh  
#If Harbor is running, stop and remove the existing instance.Your image data remains in the file system, so no data is lost.
#docker-compose down -v
#Restarting
docker-compose stop
docker-compose up -d
#Open a browser and enter https://yourdomain.com. It should display the Harbor interface
https://registry.gcalls.cn
admin/Harbor12345
docker login registry.gcalls.cn
#troubleshooting
Get https://registry.gcalls.cn/v2/: net/http: TLS handshake timeout
If you got the error above, it seems you are using the proxy, try to exclude "registry.gcalls.cn" in the "NO_PROXY", the file is located:
/etc/systemd/system/docker.service.d/http-proxy.conf
Environment="HTTP_PROXY=http://192.168.101.175:1082"
Environment="HTTPS_PROXY=http://192.168.101.175:1082"
Environment="NO_PROXY=127.0.0.1,localhost,10.0.0.0/8,172.0.0.0/8,192.168.0.0/16,*.zerofinance.net,*.aliyun.com,*.163.com,*.docker-cn.com,registry.gcalls.cn"
systemctl daemon-reload && systemctl restart docker
#Test
docker pull hello-world
#must include the project name, like xwallet, and created the project beforehand:
docker tag hello-world registry.gcalls.cn/xwallet/hello-world
docker push registry.gcalls.cn/xwallet/hello-world

#If the registry work without http, need to add the following(https don't do it):
#server-side
#vim /etc/docker/daemon.json
#"insecure-registries" : ["localhost:32000", "192.168.95.233:32000"]
#client-side
#"insecure-registries" : ["192.168.95.233:32000"]
#Don't forget rebooting docker
```

#### kind

Not Recommend.

Reference：https://kind.sigs.k8s.io/docs/user/quick-start/

```bash
# Download the latest version of Kind
curl -Lo ./kind https://github.com/kubernetes-sigs/kind/releases/download/v0.9.0/kind-$(uname)-amd64
# Make the binary executable
chmod +x ./kind
# Move the binary to your executable path
sudo mv ./kind /usr/local/bin/

# Check if the KUBECONFIG is not set
echo $KUBECONFIG
# Check if the .kube directory is created > if not, no need to create it
ls $HOME/.kube
# Create the cluster and give it a name (optional)
export http_proxy="http://192.168.101.175:1082"
export https_proxy=$http_proxy
export no_proxy="127.0.0.1,localhost,10.0.0.0/8,172.0.0.0/8,192.168.0.0/16,*.zerofinance.net,*.aliyun.com,*.163.com,*.docker-cn.com,registry.gcalls.cn"
kind create cluster --name wslkind
kind delete cluster --name wslkind
kind get clusters
# Check if the .kube has been created and populated with files
ls $HOME/.kube
kubectl get nodes
```

Notice: Kind clusters based on docker, cannot communicate with the internal docker container. Adding the extraPortMappings:

Reference：https://kind.sigs.k8s.io/docs/user/using-wsl2/

```bash
# cluster-config.yml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 8080
    hostPort: 8080
    protocol: TCP
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP

kind create cluster --config=cluster-config.yml
#kubectl run nginx --image=nginx --port=3000 --targetPort=80 --expose
kubectl create deployment nginx --image=nginx
#kubectl create service nodeport nginx --tcp=81:80 --node-port=30000
kubectl expose deployment nginx --type=NodePort --name nginx --port=80 --target-port=80


#access service 
curl localhost:30000
```

## Local development

Reference：

- https://www.telepresence.io/discussion/overview
- https://github.com/cesartl/telepresence-k8s
- https://kubernetes.io/zh/docs/tasks/debug-application-cluster/local-debugging/
- https://cloud.google.com/community/tutorials/developing-services-with-k8s

### telepresence

https://www.telepresence.io/reference/windows


```bash
#For Windows:
1. Install Windows Subsystem for Linux.
2. Start the BASH.exe program.
3. Install Telepresence by following the Ubuntu instructions above.

#For ubuntu:
curl -s https://packagecloud.io/install/repositories/datawireio/telepresence/script.deb.sh | sudo bash
sudo apt install --no-install-recommends telepresence

#For CentOS:
sudo yum install torsocks sshfs conntrack python3 -y
git clone https://github.com/telepresenceio/telepresence.git /Developer/telepresence \
 && cd /Developer/telepresence \
 && sudo env PREFIX=/usr/local ./install.sh
```

### Develop

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

#Notice: Some of spring-boot versions don't support remote debug through mvnDebug or MAVEN_DEBUG_OPTS:
#cat /Developer/apache-maven-3.3.9/bin/mvnDebug
#MAVEN_DEBUG_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=8000"
>cd /mnt/d/Developer/workspace/telepresence-k8s/
>export KUBERNETES_NAMESPACE=default
>export PROFILES=basic
>mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8000"
#Preparing to Execute Maven in Debug Mode
#It'll pause until the client is connected, you can set suspend=n to against it.
#Listening for transport dt_socket at address: 8000
#Notice：pom.xml musn't add the section，or you cannot remote debug:
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
    <optional>true</optional>
</dependency>
#Testing:
curl localhost:8080/rest/quote/cesar
```

Notice: 

Making sure "KUBERNETES_NAMESPACE" is set in the OS environment. You can set it of "remoteEnv" of devcontainer.json file if you develop with VSCODE.

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
#Activation Server URL： Pasting the following url on the "Licensing service"
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

#!!!Important!!!: Project must be located at linux folder, a windows folder located won't take affect by JRebel.
#If you see the following message, it works.
2020-12-14 12:26:33 JRebel: Reloading class 'com.ctl.telepresencek8s.DummyRestController'.
2020-12-14 12:26:38 JRebel: Reconfiguring bean 'dummyRestController' [com.ctl.telepresencek8s.DummyRestController]
```

demo:

- https://github.com/zq2599/blog_demos
- https://xinchen.blog.csdn.net/article/details/92394559
- http://www.mydlq.club/article/31

```bash
#account-service
cd /mnt/d/Developer/workspace/java-k8s/spring-cloud-k8s-account-service
mvn clean install -Pk8s
#cd /mnt/d/Developer/workspace/java-k8s/spring-cloud-k8s-web-service
#mvn clean install -Pk8s
#telepresence --swap-deployment web-service --run-shell
telepresence --new-deployment web-service --run-shell
#new-deployment will get the error message： 
#Did not find any endpoints in ribbon in namespace [null] for name [account-service] and portName [null]
#https://github.com/telepresenceio/telepresence/issues/947
#You can fix this with:
export KUBERNETES_NAMESPACE=default
cd /mnt/d/Developer/workspace/java-k8s/spring-cloud-k8s-web-service
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8000"
curl 127.0.0.1:8080/account
kubectl scale --replicas=0 deployment account-service
```

Notice: Some of spring-boot versions don't support remote debug through mvnDebug or MAVEN_DEBUG_OPTS:

https://docs.spring.io/spring-boot/docs/2.3.4.RELEASE/maven-plugin/reference/html/

Fixed this by:

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

Or：

```bash
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=8000"
```

### kubernetes-maven-plugin

https://www.eclipse.org/jkube/docs/kubernetes-maven-plugin

Building Kubernetes, strongly recommended.

```bash
#Copying remote config into "~/.kube/config" of local
#https://github.com/eclipse/jkube/tree/master/quickstarts/maven/
cd /mnt/d/Developer/workspace/java-k8s/spring-cloud-k8s-account-service
#For private docker registry, the most mavenish way is to add a server to the Maven settings file /Developer/apache-maven-3.3.9/conf/settings.xml
<server>
    <id>registry.gcalls.cn</id>
    <username>dave.zhao</username>
    <password>******</password>
</server>

#Generating the configuration automatically, remember don't adding "dockerHost" and "images" selection,
#Or will be generated two image section in the deployment yaml file:
<plugin>
    <groupId>org.eclipse.jkube</groupId>
    <artifactId>kubernetes-maven-plugin</artifactId>
    <version>1.1.0</version>
    <executions>
        <execution>
            <id>fmp</id>
            <goals>
                <goal>resource</goal>
                <goal>build</goal>
                <goal>push</goal>
                <goal>apply</goal>
            </goals>
        </execution>
    </executions>
    <configuration>   
        <resources>
            <imagePullPolicy>Always</imagePullPolicy>
        </resources>
        <enricher>
            <config>
                <fmp-service>
                    <type>NodePort</type>
                </fmp-service>
            </config>
        </enricher>
    </configuration>
</plugin>

#Using the external Dockerfile and deployment.yaml/service.yaml：
#https://www.eclipse.org/jkube/docs/kubernetes-maven-plugin#external-dockerfile
<plugin>
    <groupId>org.eclipse.jkube</groupId>
    <artifactId>kubernetes-maven-plugin</artifactId>
    <version>1.1.0</version>
    <executions>
        <execution>
            <id>fmp</id>
            <goals>
                <goal>build</goal>
                <goal>push</goal>
                <goal>resource</goal>
                #<!-- Don't use deploy, or twice build was triggered -->
                <goal>apply</goal>
            </goals>
        </execution>
    </executions>
    <configuration>   
        <!-- <dockerHost>tcp://registry.gcalls.cn:2375</dockerHost> -->
        <dockerHost>tcp://localhost:2375</dockerHost>
        <images>
            <image>
            <name>registry.gcalls.cn/xwallet/${project.name}:${project.version}</name>
            <build>
                <!-- https://github.com/eclipse/jkube/issues/149 -->
                <assembly>
                    <name>target</name>
                </assembly>
                <dockerFile>${project.basedir}/src/main/docker/Dockerfile</dockerFile> 
                <!-- <contextDir>${project.basedir}</contextDir>  -->
                <filter>@</filter>
            </build>
            </image>
        </images>
        <enricher>
            <config>
                <fmp-service>
                    <type>NodePort</type>
                </fmp-service>
            </config>
        </enricher>
    </configuration>
</plugin>

#Only include the jar file
.maven-dockerinclude:
target/*.jar

#src/man/docker/Dockerfile
FROM java:8-jdk
RUN mkdir /app
WORKDIR /app
ENV APPNAME=account-service \
    VERSION=0.0.1-SNAPSHOT \
    CONFIG=/config/
RUN ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo Asia/Shanghai > /etc/timezone
COPY target/${APPNAME}-${VERSION}.jar /app/
ENTRYPOINT ["sh", "-c", "java -Djava.security.egd=file:/dev/./urandom -jar /app/${APPNAME}-${VERSION}.jar --spring.config.location=${CONFIG} --spring.profiles.active=@spring.profile@"]
EXPOSE 8100

#src/man/jkube/account-service-deployment.yml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: account-service
  namespace: default
  labels:
    app: account-service
    group: com.xwallet
    version: 0.0.1-SNAPSHOT
    provider: jkube
spec:
  replicas: 1
  selector:
    matchLabels:
      app: account-service
      group: com.xwallet
      version: 0.0.1-SNAPSHOT
      provider: jkube
  template:
    metadata:
      labels:
        app: account-service
        group: com.xwallet
        version: 0.0.1-SNAPSHOT
        provider: jkube
    spec:
      containers:
      - name: account-service
        #image: registry.gcalls.cn/xwallet/account-service:0.0.1-SNAPSHOT
        imagePullPolicy: Always
        ports:
        - containerPort: 8089

#src/man/jkube/account-service-service.yml
kind: Service
apiVersion: v1
metadata:
  name: account-service
  namespace: default
  labels:
    app: account-service
    group: com.xwallet
    version: 0.0.1-SNAPSHOT
    provider: jkube
spec:
  type: NodePort
  ports:
  - protocol: TCP
    name: http
    port: 8080
    targetPort: 8080
  selector:
    app: account-service
    group: com.xwallet
    version: 0.0.1-SNAPSHOT
    provider: jkube

#Running:
#If don't define the dockerHost or private registry parameter, using the following command:
#export DOCKER_HOST="tcp://registry.gcalls.cn:2375"
#mvn clean install k8s:push k8s:deploy -Pk8s -Ddocker.registry=registry.gcalls.cn
#mvn clean install k8s:build k8s:push k8s:resource k8s:apply -Dmaven.test.skip=true -Dspring.profile=dev -Pk8s
mvn clean install -Pk8s

#Building by parameters
#Dockerfile
#ENTRYPOINT ["sh", "-c", "java -Djava.security.egd=file:/dev/./urandom -jar /app/${APPNAME}-${VERSION}.jar --spring.profiles.active=@spring.profile@"]
#OR
<profiles>
  <profile>
      <id>k8s</id>
        <properties>
            <spring.profile>default</spring.profile>
        </properties>
#OR
mvn clean install -Pk8s -Dspring.profile=dev

#Exposing extra port of existing docker container 
#https://blog.csdn.net/lsziri/article/details/69396990
#Assuming docker container's name is: asset-app
docker inspect asset-app | grep IPAddress
docker port asset-app
sudo iptables -t nat -nvL --line-number
#Exposing 5100 of host -> 5100 of container 
sudo iptables -t nat -A PREROUTING  -p tcp -m tcp --dport 5100 -j DNAT --to-destination  10.244.47.4:5100 
sudo iptables-save
#docker port asset-app couldn't show the 5100, do this to view:
sudo iptables -t nat -nvL | grep 10.244.47.4

#Push images to aliyun
docker login --username=zhaoxunyong@139.com registry.cn-shenzhen.aliyuncs.com
docker tag [ImageId] registry.cn-shenzhen.aliyuncs.com/zerofinance/fisco:[镜像版本号]
docker push registry.cn-shenzhen.aliyuncs.com/zerofinance/fisco:[镜像版本号]
```

### fabric8-maven-plugin

https://maven.fabric8.io/

Building Kubernetes and Openshift, like kubernetes-maven-plugin, but alway generated both of them, not recommended.

These are different:

```bash
#Zero-Config
<plugin>
    <groupId>io.fabric8</groupId>
    <artifactId>fabric8-maven-plugin</artifactId>
    <version>${fabric8.maven.plugin.version}</version>
    <executions>
        <execution>
            <id>fmp</id>
            <goals>
                <goal>resource</goal>
                <goal>build</goal>
                <goal>push</goal>
                <goal>deploy</goal>
            </goals>
        </execution>
    </executions>
    <configuration>   
        <resources>
            <imagePullPolicy>Always</imagePullPolicy>
        </resources>
        <enricher>
            <config>
                <fmp-service>
                    <type>NodePort</type>
                </fmp-service>
            </config>
        </enricher>
    </configuration>
</plugin>

#https://maven.fabric8.io/#external-dockerfile
#External-Dockerfile
<plugin>
    <groupId>io.fabric8</groupId>
    <artifactId>fabric8-maven-plugin</artifactId>
    <version>${fabric8.maven.plugin.version}</version>
    <executions>
        <execution>
            <id>fmp</id>              
            <properties>
                <spring.profile>default</spring.profile>
            </properties>
            <goals>
                <goal>resource</goal>
                <goal>build</goal>
                <goal>push</goal>
                <goal>apply</goal>
            </goals>
        </execution>
    </executions>
    <configuration>   
        <dockerHost>tcp://registry.gcalls.cn:2375</dockerHost>
        <images>
            <image>
            <name>registry.gcalls.cn/xwallet/${project.name}:${project.version}</name>
            <build>
                <dockerFile>${project.basedir}/src/main/docker/Dockerfile</dockerFile>
                <contextDir>${project.basedir}/</contextDir>
                <filter>@</filter>
            </build>
            </image>
        </images>
        <enricher>
            <config>
                <fmp-service>
                    <type>NodePort</type>
                </fmp-service>
            </config>
        </enricher>
    </configuration>
</plugin>

#Build
mvn clean install fabric8:build fabric8:push fabric8:resource fabric8:apply -Pk8s
```