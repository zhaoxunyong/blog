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
  instanceUrlSuffix: ${management.context-path}/hystrix.stream
  #获取集群名表达式，这里表示获取元数据中的cluster数据，在lms的配置文件中配置对应信息
  #clusterNameExpression: metadata['cluster']
  clusterNameExpression: new String("default")
```

效果：
![hystrix](/images/hystrix.png)

## sleuth zipkin

spring cloud sleuth是从google的dapper论文的思想实现的，提供了对spring cloud系列的链路追踪。

目的：
> 提供链路追踪。通过sleuth可以很清楚的看出一个请求都经过了哪些服务。可以很方便的理清服务间的调用关系。
> 可视化错误。对于程序未捕捉的异常，可以在zipkin界面上看到。
> 分析耗时。通过sleuth可以很方便的看出每个采样请求的耗时，分析出哪些服务调用比较耗时。当服务调用的耗时随着请求量的增大而增大时，也可以对服务的扩容提供一定的提醒作用。
> 优化链路。对于频繁地调用一个服务，或者并行地调用等，可以针对业务做一些优化措施。

### 应用程序集成

#### sleuth+log

添加依赖：
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-sleuth</artifactId>
</dependency>
```

这种方式只需要引入jar包即可。如果配置log4j，这样会在打印出如下的日志：
```log
2017-04-08 23:56:50.459 INFO [bootstrap,38d6049ff0686023,d1b8b0352d3f6fa9,false] 8764 — [nio-8080-exec-1] demo.JpaSingleDatasourceApplication : Step 2: Handling print
2017-04-08 23:56:50.459 INFO [bootstrap,38d6049ff0686023,d1b8b0352d3f6fa9,false] 8764 — [nio-8080-exec-1] demo.JpaSingleDatasourceApplication : Step 1: Handling home
```

比原先的日志多出了 [bootstrap,38d6049ff0686023,d1b8b0352d3f6fa9,false] 这些内容，[appname,traceId,spanId,exportable]。

appname：服务名称
traceId\spanId：链路追踪的两个术语，后面有介绍
exportable:是否是发送给zipkin

#### sleuth+zipkin+http

sleuth收集跟踪信息通过http请求发给zipkin。这种需要启动一个zipkin,zipkin用来存储数据和展示数据。

添加依赖：
```xml
<!--<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-sleuth</artifactId>
</dependency>-->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-zipkin</artifactId>
</dependency>
```

配置：
```yml
spring:
  sleuth:
    sampler:
      percentage: 1.0
  zipkin:
    enabled: true
    base-url: http://localhost:9411/
```

#### sletuh+streaming+zipkin

这种方式通过spring cloud streaming将追踪信息发送到zipkin。spring cloud streaming目前只有kafka和rabbitmq的binder。以rabbitmq为例：

添加依赖：
```xml
<dependency>
   <groupId>org.springframework.cloud</groupId>
   <artifactId>spring-cloud-sleuth-stream</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-stream-rabbit</artifactId>
</dependency>
```

配置：
```yml
spring:
  sleuth:
    stream:
      enabled: true
    sampler:
      percentage: 1
  #for sleuth
  rabbitmq:
    host: 192.168.99.100
    port: 5672
    username: guest
    password: guest
#    virtual-host: cloud_host
```

### zipkin-server

Zipkin 是 Twitter 的一个开源项目，允许开发者收集 Twitter 各个服务上的监控数据，并提供查询接口。

#### 安装

zipkin-server采用spring方式安装：

##### http方式

添加依赖：
```yml
<dependency>
    <groupId>io.zipkin.java</groupId>
    <artifactId>zipkin-server</artifactId>
</dependency>
<dependency>
    <groupId>io.zipkin.java</groupId>
    <artifactId>zipkin-autoconfigure-ui</artifactId>
    <scope>runtime</scope>
</dependency>
```

启动类添加：
```java
@EnableZipkinServer
@SpringBootApplication
```

##### stream方式

添加依赖：
```yml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-sleuth-zipkin-stream</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-stream-rabbit</artifactId>
</dependency>
<dependency>
    <groupId>io.zipkin.java</groupId>
    <artifactId>zipkin-autoconfigure-ui</artifactId>
    <scope>runtime</scope>
</dependency>
```

启动类添加：
```java
@EnableZipkinStreamServer
@SpringBootApplication
```

配置：
```yml
spring:
  #@EnableZipkinStreamServer时使用  
  rabbitmq:
    host: 192.168.100.88
    port: 5672
    username: guest
    password: guest
```

##### elasticsearch安装

如果容器内部通讯没有打通的话，需要采用以下方式部署：
```bash
tee elasticsearch.yml << EOF
network.host: 192.168.64.179
discovery.zen.minimum_master_nodes: 1
EOF
 
docker run --privileged=true --net=host -d -h elasticsearch --restart=always --name elasticsearch \
-p 9200:9200 -p 9300:9300 \
-e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
-v "$PWD/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml" \
elasticsearch:2.4.4

如果想将存储指到容器外，可以映射：
#-v "$PWD/config":/usr/share/elasticsearch/config \
#-v "$PWD/esdata":/usr/share/elasticsearch/data \

#index
curl http://192.168.99.100:9200/_cat/indices?v
```

如果有打通容器内部通讯或者与zipkin-server部署在同一台机器上，则安装比较简单：

```bash
docker run -d -h elasticsearch --restart=always --name elasticsearch \
-p 9200:9200 -p 9300:9300 \
-e "ES_JAVA_OPTS=-Xms512m -Xmx512m" \
elasticsearch:2.4.4
```

##### rabbitmq

日志采集是通过sleuth-zipkin-stream方式收集的，此处采用rabbitmq。可以采用docker方式安装：

```bash
docker run -d -h rabbitmq --restart=always --name rabbitmq -p 5672:5672 -p 15672:15672 \
rabbitmq:3.6.6

 # login:guest/guest   
 # url:http://ip:15672
docker exec -it rabbitmq rabbitmq-plugins enable rabbitmq_management
#docker run -d --hostname my-rabbit --name some-rabbit -p 8080:15672 rabbitmq:3-management
#docker run -d --hostname my-rabbit --name some-rabbit -e RABBITMQ_DEFAULT_USER=user -e
RABBITMQ_DEFAULT_PASS=password rabbitmq:3-management

# list_queues
#docker exec -it rabbitmq rabbitmqctl list_queues
```

#### 数据存储

##### Mem

内存方式，只适合于测试环境：

配置：
```yml
zipkin:  
  storage:
    type: mem
```

##### MySQL

添加依赖：
```xml
<dependency>
    <groupId>io.zipkin.java</groupId>
    <artifactId>zipkin-autoconfigure-storage-mysql</artifactId>
</dependency>
<dependency>
    <groupId>mysql</groupId>
    <artifactId>mysql-connector-java</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jdbc</artifactId>
</dependency>
```

配置：
```yml
spring:
  application:
    name: zipkin-server
    
  datasource:
    url: jdbc:mysql://192.168.100.88:3308/zipkin?autoReconnect=true
    username: root
    password: helloworld
    driver-class-name: com.mysql.jdbc.Driver
#    schema: classpath:/mysql.sql
#    initialize: true
#    continue-on-error: true

zipkin:
  storage:
    type: mysql
```

##### Elasticsearch

添加依赖：
```xml
<dependency>
    <groupId>io.zipkin.java</groupId>
    <artifactId>zipkin-autoconfigure-storage-elasticsearch</artifactId>
    <version>1.19.2</version>
</dependency>
<dependency>
    <groupId>org.elasticsearch</groupId>
    <artifactId>elasticsearch</artifactId>
</dependency>
```

配置：
```yml
zipkin:
  storage:
    type: elasticsearch
    elasticsearch:
      cluster: elasticsearch
      hosts: 192.168.108.183:9300
      index: zipkin
#      index-shards: ${ES_INDEX_SHARDS:5}
#      index-replicas: ${ES_INDEX_REPLICAS:1}
```

#### zipkin-dependencies

如果为非mem方式部署的zipkin-server，[zipkin-dependencies](https://github.com/openzipkin/zipkin-dependencies)是没有数据的，需要加入zipkin-dependencies模块才能正常显示。以elasticsearch为例：

添加依赖：
```xml
<dependency>
    <groupId>io.zipkin.dependencies</groupId>
    <artifactId>zipkin-dependencies-elasticsearch</artifactId>
    <version>1.5.4</version>
</dependency>
```

添加代码：
```java
@Component
public class ElasticsearchDependenciesTask {
    
    private Logger logger = LoggerFactory.getLogger(this.getClass());
    
    @Value("${spark.es.nodes}")
    private String esNodes;
    
    @Value("${spark.driver.allowMultipleContexts}")
    private String allowMultipleContexts;
    
    @Scheduled(cron = "0 */5 * * * ?")
    public void run() throws Exception {
//        -e ES_HOSTS="192.168.108.183:9200"
        Map<String, String> envs = Maps.newHashMap();
        envs.put("spark.driver.allowMultipleContexts",allowMultipleContexts);
        envs.put("ES_HOSTS",esNodes);
        EnvUtils.setEnv(envs);
        ElasticsearchDependenciesJob.builder().build().run();
    }   
}
```

配置：
```yml
# dependencies-elasticsearch配置
spark:
  driver:
    allowMultipleContexts: true
  es:
    nodes: 192.168.108.183:9200
```

内部是通过spark进行数据分析，再生成对应的dependencies数据。

当然也可以通过docker部署：
```bash
docker run --rm --name zipkin-dependencies \
-e STORAGE_TYPE=elasticsearch \
-e ES_HOSTS=192.168.108.183:9200 \
-e "JAVA_OPTS=-Xms128m -Xmx128m" \
openzipkin/zipkin-dependencies:1.5.4
```

## 参考
> http://tech.lede.com/2017/04/19/rd/server/SpringCloudSleuth/
> https://segmentfault.com/a/1190000008629939
> https://mykite.github.io/2017/04/21/zipkin%E7%AE%80%E5%8D%95%E4%BB%8B%E7%BB%8D%E5%8F%8A%E7%8E%AF%E5%A2%83%E6%90%AD%E5%BB%BA%EF%BC%88%E4%B8%80%EF%BC%89/


