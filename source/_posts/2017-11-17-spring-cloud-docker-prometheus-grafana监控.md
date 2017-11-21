---
title: spring cloud+docker+prometheus grafana监控
date: 2017-11-17 15:28:48
categories: ["spring cloud","docker","prometheus"]
tags: ["spring cloud","docker","prometheus"]
toc: true
---
最近公司上线一套基于docker的spring cloud微服务系统，记录一下相关的监控技术。

<!-- more -->

## spring boot监控

### actuator

Spring Boot 包含了一系列的附加特性，来帮助你监控和管理生产环境下运行时的应用程序。你可以通过HTTP endpoints、JMX或者SSH来监控和管理应用——健康状况、系统指标、参数信息、内存状况等等。

添加依赖:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

### admin-dashboard

Spring Boot Admin是一个管理和监控Spring Boot应用的项目。我们可以通过Spring Boot Admin的客户端运行，也可以Spring Cloud中注册为一个服务（比如：注册到Eureka中）。Spring Boot Amin仅仅是一个建立在Spring Boot Actuator端点上的AngularJS的应用。

只好不要集成在业务系统中，可以单独建立一个project。只需要进行以下添加：

添加依赖：

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-eureka</artifactId>
</dependency>

<dependency>
    <groupId>de.codecentric</groupId>
    <artifactId>spring-boot-admin-server</artifactId>
</dependency>

<dependency>
    <groupId>de.codecentric</groupId>
    <artifactId>spring-boot-admin-server-ui</artifactId>
</dependency>
```

启动类添加：

```java
@EnableDiscoveryClient
@EnableAdminServer
@SpringBootApplication
```

配置:

```yml
server:
  port: 8040
  
management:
  context-path: /ops
  security:
    enabled: false
    
spring:
  application:
    name: admin-dashboard
  boot:
    admin:
      monitor:
        connect-timeout: 10000
        read-timeout: 60000

eureka:
  instance:
    preferIpAddress: true
      # eureka的ip，如果有多个ip地址时，需要在此处指定
#      ipAddress: 127.0.0.1
      # 续约到期时间（默认90秒）
    leaseExpirationDurationInSeconds: 30
      #续约更新时间间隔（默认30秒），在生产中，最好坚持使用默认值，因为在服务器内部有一些计算，他们对续约做出假设。
    leaseRenewalIntervalInSeconds: 10
#    instance-id: ${spring.application.name}:${eureka.instance.ipAddress}:${server.port}
    statusPageUrlPath: ${management.context-path}/info
    healthCheckUrlPath: ${management.context-path}/health
    metadata-map:
      management.context-path: ${management.context-path}
    
  client:
    registerWithEureka: false
    serviceUrl:
      defaultZone: http://localhost:8761/eureka/
```

效果：
![admin-dashboard.png](/images/admin-dashboard.png)

### prometheus日志收集

Prometheus用于收集actuator的信息，再在grafana中进行显示。

添加依赖：

```xml
<dependency>
    <groupId>io.prometheus</groupId>
    <artifactId>simpleclient_spring_boot</artifactId>
    <version>0.1.0</version>
</dependency>
```

启动类添加：

```java
@EnablePrometheusEndpoint
@EnableSpringBootMetricsCollector
@SpringBootApplication
```

配置:

```yml
# prometheus endpoint, enabled default false    
endpoints:
  prometheus:
    enabled: true

# prometheus endpoint, enabled default false    
endpoints:
  prometheus:
    enabled: true
```

访问：
http://ip:port/ops/prometheus
![prometheus.png](/images/prometheus.png)

## prometheus

参考：[https://segmentfault.com/a/1190000008629939](https://segmentfault.com/a/1190000008629939)

Prometheus 是使用 Golang 开发的开源监控系统，被人称为下一代监控系统，是为数不多的适合 Docker、Mesos 、Kubernetes 环境的监控系统之一 。

### 安装

```bash
docker run -d --name prometheus -p 9090:9090 -v \
/works/conf/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus
```

### 配置

prometheus.yml相关配置如下：
```yml
global:
  scrape_interval: 10s
  scrape_timeout: 10s
  evaluation_interval: 10m

scrape_configs:
  - job_name: config_server
    #scrape_interval: 5s
    #scrape_timeout: 5s
    metrics_path: /ops/prometheus
    scheme: http
    #basic_auth:
    #  username: admin
    #  password: 123456
    static_configs:
    - targets: ['192.168.63.21:8100']
      labels:
        instance: 192.168.63.21
    - targets: ['192.168.64.21:8100']
      labels:
        instance: 192.168.64.21

  - job_name: employee_server
    metrics_path: /ops/prometheus
    scheme: http
    static_configs:
    - targets: ['192.168.63.31:8078']
      labels:
        instance: 192.168.63.31
    - targets: ['192.168.64.31:8078']
      labels:
        instance: 192.168.64.31
        
  - job_name: hkcash_server
    metrics_path: /ops/prometheus
    scheme: http
    static_configs:
    - targets: ['192.168.63.21:8085']
      labels:
        instance: 192.168.63.21
    - targets: ['192.168.64.21:8085']
      labels:
        instance: 192.168.64.21
        
  - job_name: eureka_server
    metrics_path: /ops/prometheus
    scheme: http
    static_configs:
    - targets: ['192.168.63.31:8761']
      labels:
        instance: 192.168.63.31
    - targets: ['192.168.64.31:8761']
      labels:
        instance: 192.168.64.31
        
  - job_name: notify_server
    metrics_path: /ops/prometheus
    scheme: http
    static_configs:
    - targets: ['192.168.63.31:8086']
      labels:
        instance: 192.168.63.31
    - targets: ['192.168.64.31:8086']
      labels:
        instance: 192.168.64.31
        
  - job_name: tu_server
    metrics_path: /ops/prometheus
    scheme: http
    static_configs:
    - targets: ['192.168.63.11:45678']
      labels:
        instance: 192.168.63.11
    - targets: ['192.168.64.11:45678']
      labels:
        instance: 192.168.64.11
        
  - job_name: app_gateway
    metrics_path: /ops/prometheus
    scheme: http
    static_configs:
    - targets: ['192.168.63.11:8062']
      labels:
        instance: 192.168.63.11
    - targets: ['192.168.64.11:8062']
      labels:
        instance: 192.168.64.11
        
  - job_name: lms_webapp
    metrics_path: /ops/prometheus
    scheme: http
    static_configs:
    - targets: ['192.168.63.101:8079']
      labels:
        instance: 192.168.63.101
        
  - job_name: los_webapp
    metrics_path: /ops/prometheus
    scheme: http
    static_configs:
    - targets: ['192.168.63.101:8080']
      labels:
        instance: 192.168.63.101

  - job_name: cAdvisor
    static_configs:
    - targets: ['192.168.63.21:4194']
      labels:
        container_group: 192.168.63.21
    - targets: ['192.168.64.21:4194']
      labels:
        container_group: 192.168.64.21
    - targets: ['192.168.63.31:4194']
      labels:
        container_group: 192.168.63.31
    - targets: ['192.168.64.31:4194']
      labels:
        container_group: 192.168.64.31
    - targets: ['192.168.63.11:4194']
      labels:
        container_group: 192.168.63.11
    - targets: ['192.168.64.11:4194']
      labels:
        container_group: 192.168.64.11
    - targets: ['192.168.63.101:4194']
      labels:
        container_group: 192.168.63.101
    - targets: ['192.168.64.178:4194']
      labels:
        container_group: 192.168.64.178
    - targets: ['192.168.64.179:4194']
      labels:
        container_group: 192.168.64.179
```

### 访问

访问：
http://ip:9090/graph

效果：
![prometheus-ui](/images/prometheus-ui.png)

## grafna

Grafana 是一个开源的图表可视化系统，简言之，其特点在于图表配置比较方便、生成的图表漂亮。
Prometheus + Grafana 监控系统的组合中，前者负责采样数据并存储这些数据；后者则侧重于形象生动的展示数据。

### 安装

```bash
docker run -d --name grafana -p 3000:3000 grafana/grafana
```

### 访问
http://192.168.64.178:3000

默认登录账户密码都为admin

### 配置

#### 添加数据源
![grafana-config](/images/grafana-config.png)

#### 添加Templating

![templating](/images/templating.png)

job:
![templating-job](/images/templating-job.png)

instance:
![templating-instance](/images/templating-instance.png)

apis:
![templating-apis](/images/templating-apis.png)

效果
![templating1](/images/templating1.png)


#### 添加panel

##### mem

```yml
mem{job=~"[[job]]",instance=~"[[instance]]"}
mem_free{job=~"[[job]]",instance=~"[[instance]]"}
```

![grafana-panel1](/images/grafana-panel1.png)

![grafana-panel2](/images/grafana-panel2.png)

![grafana-panel3](/images/grafana-panel3.png)

![grafana-panel4](/images/grafana-panel4.png)

效果
![grafana-panel5](/images/grafana-panel5.png)

##### Heap

```yml
heap{job=~"[[job]]",instance=~"[[instance]]"}
heap_committed{job=~"[[job]]",instance=~"[[instance]]"}
heap_used{job=~"[[job]]",instance=~"[[instance]]"}
nonheap{job="~[[job]]",instance="~[[instance]]"}
nonheap_committed{job=~"[[job]]",instance=~"[[instance]]"}
nonheap_used{job=~"[[job]]",instance=~"[[instance]]"}
```

##### Threads

```yml
threads{job=~"[[job]]",instance=~"[[instance]]"}
threads_peak{job=~"[[job]]",instance=~"[[instance]]"}
threads_daemon{job=~"[[job]]",instance=~"[[instance]]"}
```

##### systemload_average

```yml
systemload_average{job=~"[[job]]",instance=~"[[instance]]"}
```

##### Gauge_servo_response_api

```yml
{job=~"[[job]]",instance=~"[[instance]]",__name__=~"gauge_servo_response_api_.*"}
```

具体的配置文件参考[prometheus.json](/files/prometheus.json)

### 整体效果
![grafana-ui](/images/grafana-ui.png)

## 容器监控

通过cAdvisor收集docker日志，再通过prometheus在grafana中显示。

### cAdvisor

每台容器安装：
```bash
docker run --restart=always \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:rw \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=4194:8080 \
  --detach=true \
  --name=cadvisor \
  google/cadvisor:latest
```

访问：
http://hostIp:4194/

### prometheus配置
```yml
...
  - job_name: cAdvisor
    static_configs:
    - targets: ['192.168.63.21:4194']
      labels:
        container_group: 192.168.63.21
    - targets: ['192.168.64.21:4194']
      labels:
        container_group: 192.168.64.21
    - targets: ['192.168.63.31:4194']
      labels:
        container_group: 192.168.63.31
    - targets: ['192.168.64.31:4194']
      labels:
        container_group: 192.168.64.31
    - targets: ['192.168.63.11:4194']
      labels:
        container_group: 192.168.63.11
    - targets: ['192.168.64.11:4194']
      labels:
        container_group: 192.168.64.11
    - targets: ['192.168.63.101:4194']
      labels:
        container_group: 192.168.63.101
    - targets: ['192.168.64.178:4194']
      labels:
        container_group: 192.168.64.178
    - targets: ['192.168.64.179:4194']
      labels:
        container_group: 192.168.64.179
```

![prometheus-cadvisor](/images/prometheus-cadvisor.png)

### grafana dashboard

可以从grafana官网导入dashboard：https://grafana.com/dashboards
![docker-dashboard](/images/docker-dashboard.png)

导入dashboard:
![docker-dashboard-import1](/images/docker-dashboard-import1.png)

![docker-dashboard-import2](/images/docker-dashboard-import2.png)

![docker-dashboard-import3](/images/docker-dashboard-import3.png)

### 效果
![docker-dashboard1](/images/docker-dashboard1.png)


## hystrix-dashboard

### hystrix

hystrix旨在通过控制那些访问远程系统、服务和第三方库的节点，从而对延迟和故障提供更强大的容错能力。Hystrix具备拥有回退机制和断路器功能的线程和信号隔离，请求缓存和请求打包（request collapsing，即自动批处理），以及监控和配置等功能。

添加依赖：
```xml
<!-- /hystrix.stream需要用到spring-boot-starter-actuator -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-hystrix</artifactId>
</dependency>
```

启动类中添加：
```java
@EnableEurekaClient
@EnableHystrix
@SpringBootApplication
```

### dashboard

Hystrix-dashboard是一款针对Hystrix进行实时监控的工具，通过Hystrix Dashboard我们可以在直观地看到各Hystrix Command的请求响应时间, 请求成功率等数据。

添加依赖：
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-hystrix-dashboard</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-eureka</artifactId>
</dependency>
```

### turbine
但是只使用Hystrix Dashboard的话, 你只能看到单个应用内的服务信息, 这明显不够. 我们需要一个工具能让我们汇总系统内多个服务的数据并显示到Hystrix Dashboard上, 这个工具就是Turbine.

添加依赖：
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-netflix-turbine</artifactId>
</dependency>
```

启动类添加：
```java
@EnableHystrixDashboard
@EnableTurbine
@EnableEurekaClient
@SpringBootApplication
```

### 配置
```yml
server:
  port: 8050

management:
  context-path: /ops
  security:
    enabled: false
    
spring:
  application:
    name: hystrix-dashboard

eureka:
  instance:
    preferIpAddress: true
    # eureka的ip，如果有多个ip地址时，需要在此处指定
#   ipAddress: 127.0.0.1
    # 续约到期时间（默认90秒）
    leaseExpirationDurationInSeconds: 30
    #续约更新时间间隔（默认30秒），在生产中，最好坚持使用默认值，因为在服务器内部有一些计算，他们对续约做出假设。
    leaseRenewalIntervalInSeconds: 10
    # default: ${spring.cloud.client.hostname}:${spring.application.name}:${spring.application.instance_id:${server.port}}
#    instance-id: ${spring.application.name}:${eureka.instance.ipAddress}:${server.port}
    statusPageUrlPath: ${management.context-path}/info
    healthCheckUrlPath: ${management.context-path}/health
    metadata-map:
      management.context-path: ${management.context-path}
  client:
    registerWithEureka: false
    serviceUrl:
      defaultZone: http://localhost:8761/eureka/

turbine:
  appConfig: app-gateway,hkcash-server,tu-server
  #turbine需要聚合的集群名称，需要在对应的服务的，通过 http://localhost:8050/turbine.stream?cluster=default 访问 
  #aggregator.clusterConfig: hkcash
  aggregator.clusterConfig: default
  #获取集群名表达式，这里表示获取元数据中的cluster数据，在lms的配置文件中配置对应信息
  #clusterNameExpression: metadata['cluster']
  clusterNameExpression: new String("default")
```

效果：
![hystrix](/images/hystrix.png)

