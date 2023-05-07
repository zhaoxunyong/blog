---
title: Loki Log System
date: 2022-03-09 16:04:26
categories: ["Log"]
tags: ["Log"]
toc: true
---

This article recorded how to install and configure Log System based on Loki developing by Grafana.

<!-- more -->



## kafka

### Kakfa k8s

It's complex, please refer to Kakfa Config: [kafka.zip](/files/Loki-Log-System/kafka.zip)

Kakfa without zookeeper:

- https://learnk8s.io/kafka-ha-kubernetes#deploying-a-3-node-kafka-cluster-on-kubernetes
- https://stackoverflow.com/questions/73380791/kafka-kraft-replication-factor-of-3
- https://github.com/IBM/kraft-mode-kafka-on-kubernetes

Dockerfile:

```bash
FROM openjdk:17-bullseye

ENV KAFKA_VERSION=3.3.2
ENV SCALA_VERSION=2.13
ENV KAFKA_HOME=/opt/kafka
ENV PATH=${PATH}:${KAFKA_HOME}/bin

LABEL name="kafka" version=${KAFKA_VERSION}

RUN wget -O /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz \
 && tar xfz /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt \
 && rm /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz \
 && ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} ${KAFKA_HOME} \
 && rm -rf /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz

COPY ./entrypoint.sh /
RUN ["chmod", "+x", "/entrypoint.sh"]
```

entrypoint.sh:

```bash
#!/bin/bash

#NODE_ID=${HOSTNAME:6}
NODE_ID=$(hostname | sed s/.*-//)
LISTENERS="PLAINTEXT://:9092,CONTROLLER://:9093"
#ADVERTISED_LISTENERS="PLAINTEXT://kafka-$NODE_ID.$SERVICE.$NAMESPACE.svc.cluster.local:9092"
ADVERTISED_LISTENERS="PLAINTEXT://kafka-$NODE_ID.$SERVICE:9092"

CONTROLLER_QUORUM_VOTERS=""
for i in $( seq 0 $REPLICAS); do
    if [[ $i != $REPLICAS ]]; then
        CONTROLLER_QUORUM_VOTERS="$CONTROLLER_QUORUM_VOTERS$i@kafka-$i.$SERVICE:9093,"
    else
        CONTROLLER_QUORUM_VOTERS=${CONTROLLER_QUORUM_VOTERS::-1}
    fi
done

mkdir -p $SHARE_DIR/$NODE_ID 

if [[ ! -f "$SHARE_DIR/cluster_id" && "$NODE_ID" = "0" ]]; then
    CLUSTER_ID=$(kafka-storage.sh random-uuid)
    echo $CLUSTER_ID > $SHARE_DIR/cluster_id
else
    CLUSTER_ID=$(cat $SHARE_DIR/cluster_id)
fi

sed -e "s+^node.id=.*+node.id=$NODE_ID+" \
-e "s+^controller.quorum.voters=.*+controller.quorum.voters=$CONTROLLER_QUORUM_VOTERS+" \
-e "s+^listeners=.*+listeners=$LISTENERS+" \
-e "s+^advertised.listeners=.*+advertised.listeners=$ADVERTISED_LISTENERS+" \
-e "s+^log.dirs=.*+log.dirs=$SHARE_DIR/$NODE_ID+" \
/opt/kafka/config/kraft/server.properties > server.properties.updated \
&& mv server.properties.updated /opt/kafka/config/kraft/server.properties

kafka-storage.sh format -t $CLUSTER_ID -c /opt/kafka/config/kraft/server.properties

exec kafka-server-start.sh /opt/kafka/config/kraft/server.properties
```

docker building:

```bash
docker build -t "registry.zerofinance.net/xpayappimage/kafka:3.3.2" .
#docker login registry.zerofinance.net
docker push "registry.zerofinance.net/xpayappimage/kafka:3.3.2"
```

kafka-kraft.yml:

```yml
#部署 Service Headless，用于Kafka间相互通信
apiVersion: v1
kind: Service
metadata:
  name: kafka-svc
  labels:
    app: kafka
spec:
  type: ClusterIP
  clusterIP: None
  ports:
    - name: '9092'
      port: 9092
      protocol: TCP
      targetPort: 9092
    - name: '9093'
      port: 9093
      protocol: TCP
      targetPort: 9093
  selector:
    app: kafka

---
#部署 Service，用于外部访问 Kafka
apiVersion: v1
kind: Service
metadata:
  annotations:
    #service.beta.kubernetes.io/alibaba-cloud-loadbalancer-address-type: "intranet"
    #service.beta.kubernetes.io/alibaba-cloud-loadbalancer-vswitch-id: "vsw-j6c8okcv03ah1uvu31tbm"
    service.beta.kubernetes.io/alibaba-cloud-loadbalancer-id: "lb-3nsgew8gt6lzmtzc0vn93"
    service.beta.kubernetes.io/alibaba-cloud-loadbalancer-force-override-listeners: "true"
  name: kafka-broker
  labels:
    app: kafka
spec:
  type: LoadBalancer
  ports:
  - name: '9092'
    port: 9092
    protocol: TCP
    targetPort: 9092
  selector:
    app: kafka

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: "kafka"
  labels:
    app: kafka
spec:
  selector:
    matchLabels:
      app: kafka
  serviceName: kafka-svc
  podManagementPolicy: "OrderedReady"
  replicas: 3
  updateStrategy:
    type: "RollingUpdate"
  template:
    metadata:
      name: "kafka"
      labels:
        app: kafka
    spec:
      #securityContext:
      #  fsGroup: 1001
      nodeSelector:
        xpay-env: logs
      tolerations:
      - key: "xpay-env"
        operator: "Equal"
        value: "logs"
        effect: "NoSchedule"
      containers:
      - name: kafka
        image: "registry.zerofinance.net/xpayappimage/kafka:3.3.2"
        imagePullPolicy: "Always"
        #securityContext:
        #  runAsNonRoot: true
        #  runAsUser: 1001
        env:
        - name: REPLICAS
          value: '3'
        - name: SERVICE
          value: kafka-svc
        - name: SHARE_DIR
          value: /mnt/kafka
        - name: CLUSTER_ID
          value: LelM2dIFQkiUFvXCEcqRWA
        - name: DEFAULT_REPLICATION_FACTOR
          value: '3'
        - name: DEFAULT_MIN_INSYNC_REPLICAS
          value: '2'
        ports:
          - containerPort: 9092
          - containerPort: 9093
        livenessProbe:
          tcpSocket:
            port: 9092
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 2
        readinessProbe:
          tcpSocket:
            port: 9092
          initialDelaySeconds: 5
          periodSeconds: 10
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 6
        volumeMounts:
        - name: data
          mountPath: /mnt/kafka
      volumes:
      - name: data
        hostPath:
          path: "/data/data/kafka-k8s"
```

kafka-ui.yml:

```yml
apiVersion: v1
kind: Service
metadata:
  name: kafka-ui
  labels:
    app: kafka-ui
spec:
  #type: NodePort
  ports:
  - name: kafka
    port: 8080
    targetPort: 8080
    #nodePort: 30900
  selector:
    app: kafka-ui
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kafka-ui
  labels:
    app: kafka-ui
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kafka-ui
  template:
    metadata:
      labels:
        app: kafka-ui
    spec:
      containers:
      - name: kafka-ui
        image: provectuslabs/kafka-ui:latest
        imagePullPolicy: IfNotPresent
        ports:
        - name: kafka-ui
          containerPort: 8080
          protocol: TCP
        env:
        - name: DYNAMIC_CONFIG_ENABLED
          value: "true"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: kafka-ui
        readinessProbe:
          httpGet:
            path: /actuator/info
            port: kafka-ui

---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kafka-ui
spec:
  tls: []
  rules:
    - host: kafka-ui-test.zerofinance.net
      http:
        paths:
          - backend:
              serviceName: kafka-ui
              servicePort: 8080
```

Test:

```bash
> kubectl -n zero-logs run kafka-client --rm -ti --image bitnami/kafka:3.1.0 -- bash
kafka-topics.sh --create --bootstrap-server kafka-svc:9092 --replication-factor 2 --partitions 3 --topic test
kafka-topics.sh --bootstrap-server kafka-svc:9092 --list
kafka-console-producer.sh --broker-list kafka-svc:9092 --topic test
kafka-console-consumer.sh --bootstrap-server kafka-svc:9092 --topic test --from-beginning

kafka-topics.sh --create --bootstrap-server kafka-broker-test.zerofinance.net:9092 --replication-factor 2 --partitions 3 --topic test
kafka-topics.sh --bootstrap-server kafka-broker-test.zerofinance.net:9092 --list
kafka-console-producer.sh --broker-list kafka-broker-test.zerofinance.net:9092 --topic test
kafka-console-consumer.sh --bootstrap-server kafka-broker-test.zerofinance.net:9092 --topic test --from-beginning
```

## Zookeeper

> https://www.qikqiak.com/k8strain/controller/statefulset/
> https://www.jianshu.com/p/f0b0fc3d192f
> https://itopic.org/kafka-in-k8s.html
> https://itopic.org/zookeeper-in-k8s.html

Need to modify resource from: https://github.com/31z4/zookeeper-docker/tree/master/3.8.1

![zookeeper01.png](/images/Loki-Log-System/zookeeper01.png)

![zookeeper02.png](/images/Loki-Log-System/zookeeper02.png)

docker-entrypoint.sh

```bash
#!/bin/bash

set -e

ZOO_MY_ID=$(($(hostname | sed s/.*-//) + 1))

# Allow the container to be started with `--user`
if [[ "$1" = 'zkServer.sh' && "$(id -u)" = '0' ]]; then
    chown -R zookeeper "$ZOO_DATA_DIR" "$ZOO_DATA_LOG_DIR" "$ZOO_LOG_DIR"
    exec gosu zookeeper "$0" "$@"
fi

mkdir -p $ZOO_DATA_DIR/$ZOO_MY_ID $ZOO_DATA_LOG_DIR/$ZOO_MY_ID

# Generate the config only if it doesn't exist
if [[ ! -f "$ZOO_CONF_DIR/zoo.cfg" ]]; then
    CONFIG="$ZOO_CONF_DIR/zoo.cfg"
    {
        echo "dataDir=$ZOO_DATA_DIR/$ZOO_MY_ID"
        echo "dataLogDir=$ZOO_DATA_LOG_DIR/$ZOO_MY_ID"

        echo "tickTime=$ZOO_TICK_TIME"
        echo "initLimit=$ZOO_INIT_LIMIT"
        echo "syncLimit=$ZOO_SYNC_LIMIT"

        echo "autopurge.snapRetainCount=$ZOO_AUTOPURGE_SNAPRETAINCOUNT"
        echo "autopurge.purgeInterval=$ZOO_AUTOPURGE_PURGEINTERVAL"
        echo "maxClientCnxns=$ZOO_MAX_CLIENT_CNXNS"
        echo "standaloneEnabled=$ZOO_STANDALONE_ENABLED"
        echo "admin.enableServer=$ZOO_ADMINSERVER_ENABLED"
    } >> "$CONFIG"
    if [[ -z $ZOO_SERVERS ]]; then
      ZOO_SERVERS="server.1=localhost:2888:3888;2181"
    fi

    for server in $ZOO_SERVERS; do
        echo "$server" >> "$CONFIG"
    done

    if [[ -n $ZOO_4LW_COMMANDS_WHITELIST ]]; then
        echo "4lw.commands.whitelist=$ZOO_4LW_COMMANDS_WHITELIST" >> "$CONFIG"
    fi

    for cfg_extra_entry in $ZOO_CFG_EXTRA; do
        echo "$cfg_extra_entry" >> "$CONFIG"
    done
fi

# Write myid only if it doesn't exist
if [[ ! -f "$ZOO_DATA_DIR/$ZOO_MY_ID/myid" ]]; then
    echo "${ZOO_MY_ID:-1}" > "$ZOO_DATA_DIR/$ZOO_MY_ID/myid"
fi

exec "$@"
```

builds images:

```bash
docker build -t "registry.zerofinance.net/xpayappimage/zookeeper:3.8.1" .
docker push registry.zerofinance.net/xpayappimage/zookeeper:3.8.1
```

## Loki

What's the Grafana Loki?

Loki is a log aggregation system designed to store and query logs from all your applications and infrastructure.

Documents located in: https://grafana.com/docs/loki/latest/

Configurations of loki k8s: [loki-k8s.zip](/files/Loki-Log-System/loki-k8s.zip)

### Installation

https://grafana.com/docs/loki/latest/fundamentals/overview/#overview

There are losts of way to install Loki, here show it by docker. the other ways please refer to: https://grafana.com/docs/loki/latest/installation/

#### Docker

If you clients are distributed on individual machines, you can use docker:

Configuration:

loki-config.yaml:

For local file:

```yaml
auth_enabled: false

server:
  log_level: error
  http_listen_port: 3100
  grpc_listen_port: 9096
  grpc_server_max_recv_msg_size: 1572864000
  grpc_server_max_send_msg_size: 1572864000

ingester:
  wal:
    enabled: true
    dir: /loki/data/wal
    replay_memory_ceiling: 10G
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
      heartbeat_timeout: 10m
    final_sleep: 0s
  chunk_idle_period: 1h
  max_chunk_age: 2h
  chunk_retain_period: 30s
  chunk_target_size: 1572864

schema_config:
  configs:
    - from: 2023-04-01
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h


storage_config:
  boltdb_shipper:
    active_index_directory: /loki/data/index
    cache_location: /loki/data/boltdb-shipper-cache
    cache_ttl: 24h
    shared_store: filesystem
  filesystem:
    directory: /loki/data/chunks

compactor:
  working_directory: /loki/data/boltdb-shipper-compactor
  shared_store: filesystem

limits_config:
  ingestion_rate_mb: 50
  ingestion_burst_size_mb: 100
  max_streams_per_user: 0
  max_global_streams_per_user: 0
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

table_manager:
  retention_deletes_enabled: true
  retention_period: 168h

#https://grafana.com/docs/loki/latest/configuration/
ruler:
  storage:
    type: local
    local:
      directory: /mnt/config/rules
  rule_path: /loki/data/rules-temp
  alertmanager_url: http://192.168.101.82:9093
  # How frequently to evaluate rules.
  evaluation_interval: 5s
  # How frequently to poll for rule changes.
  poll_interval: 5s
  ring:
    kvstore:
      store: inmemory
  enable_api: true
```

For Aliyun OSS:

```yaml
auth_enabled: false

server:
  log_level: error
  http_listen_port: 3100
  grpc_listen_port: 9096
  grpc_server_max_recv_msg_size: 1572864000
  grpc_server_max_send_msg_size: 1572864000

ingester:
  wal:
    enabled: true
    dir: /loki/data/wal
    replay_memory_ceiling: 10G
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
      heartbeat_timeout: 10m
    final_sleep: 0s
  # chunk_idle_period: 1h
  # max_chunk_age: 2h
  # chunk_retain_period: 30s
  # chunk_target_size: 1572864

schema_config:
  configs:
    - from: 2022-01-01
      index:
        period: 24h
        prefix: index_
      object_store: aws
      schema: v11
      store: boltdb-shipper

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/data/boltdb-shipper-active
    cache_location: /loki/data/boltdb-shipper-cache
    cache_ttl: 24h
    shared_store: s3
  aws:
    s3forcepathstyle: false
    bucketnames: loki-files
    endpoint: https://oss-cn-shenzhen.aliyuncs.com
    access_key_id: xxxx
    secret_access_key: xxxx
    insecure: true

analytics:
  reporting_enabled: false

compactor:
  working_directory: /loki/data/boltdb-shipper-compactor
  shared_store: s3

# table_manager:
#   retention_deletes_enabled: true
#   retention_period: 336h

limits_config:
  ingestion_rate_mb: 50
  ingestion_burst_size_mb: 100
  max_streams_per_user: 0
  max_global_streams_per_user: 0
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

ruler:
  storage:
    type: local
    local:
      directory: /mnt/config/rules
  rule_path: /loki/data/rules-temp
  alertmanager_url: http://192.168.102.82:9093
  ring:
    kvstore:
      store: inmemory
  enable_api: true
```

promtail-config.yaml:

For log files:

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://192.168.80.196:3100/loki/api/v1/push

scrape_configs:
# - job_name: service_log
#   file_sd_configs:
#     - files:
#       - ./config/*.yaml #从config目录下加载配置文件
#       refresh_interval: 1m
- job_name: company-job 
  pipeline_stages:
  - match:
      selector: '{belongs="company", filename=~".*(?:error|tmlog).*"}'
      action: drop
      drop_counter_reason: promtail_noisy_error
  - match:
      selector: '{belongs="company"}'
      stages:
      - regex:
          source: filename
          expression: "^/works/log/(?P<org>.+?)/(?P<env>.+?)/(?P<app_name>.+?)/.+\\.log$"
      - labels:
          org:
          env:
          app_name:
  - match:
      selector: '{org=~".+"}'
      stages:
      - multiline:
          firstline: '^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}'
          max_lines: 500
      - regex:
          expression: "^(?P<time>\\d{4}\\-\\d{2}\\-\\d{2} \\d{1,2}\\:\\d{2}\\:\\d{2}).*"
      - timestamp:
          source: time
          format: '2006-01-02 15:04:05'
          location: Asia/Shanghai
  static_configs:
  - targets:
      - localhost
    labels:
      belongs: company
      __path__: /works/log/**/*.log
```

Recoverying local files automatically:

```yaml
...
scrape_configs:
- job_name: service_log
  file_sd_configs:
    - files:
      - ./config/*.yaml #从config目录下加载配置文件
      refresh_interval: 1m
- job_name: company-job 
...
```

config/pipeline_stages.yaml

```yaml
- targets:
    - localhost
  labels:
    belongs: company
    __path__: /works/log/**/*.log
    #env: {{ENV}}
    #hostname: {{BINDIP}}
    # service_name: var-log-messages
    # log_type: var-log-messages
```

For Kafka:

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://192.168.101.82:3100/loki/api/v1/push

scrape_configs:
  - job_name: kafka
    # file_sd_configs:
    #   - files:
    #     - /mnt/config/config/*.yaml
    #     refresh_interval: 1m
    kafka:
      brokers: 
      - 192.168.80.98:9092
      topics: 
      - dev
      - test
      - uat
      group_id: promtail_davetest
      labels:
        job: kafka
    relabel_configs:
      - action: replace
        source_labels:
          - __meta_kafka_topic
        target_label: topic
      - action: replace
        source_labels:
          - __meta_kafka_partition
        target_label: partition
      - action: replace
        source_labels:
          - __meta_kafka_group_id
        target_label: group
      - action: replace
        source_labels:
          - __meta_kafka_message_key
        target_label: message_key
    pipeline_stages:
      - match:
          selector: '{job="kafka"}'
          stages:
          - json:
              expressions:
                log: log
                filename: filename
          - labels:
              filename:
      - match:
          selector: '{job="kafka", filename=~".*(?:error|tmlog).*"}'
          action: drop
          drop_counter_reason: promtail_noisy_error
      - match:
          selector: '{job="kafka"}'
          stages:
          - regex:
              source: filename
              expression: "^/works/log/(?P<org>.+?)/(?P<env>.+?)/(?P<app_name>.+?)/.+\\.log$"
          - labels:
              org:
              env:
              app_name:
          - output:
              source: log
      - match:
          selector: '{org=~".+"}'
          stages:
          #- multiline:
          #  firstline: '^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}'
          #  max_lines: 500
          - regex:
              #expression: "^(?P<time>\\d{4}\\-\\d{2}\\-\\d{2} \\d{1,2}\\:\\d{2}\\:\\d{2}).+?\\[bizKey=(?P<biz_key>.*?)\\,bizValue=(?P<biz_value>.*?)\\].*"
              expression: "^(?P<time>\\d{4}\\-\\d{2}\\-\\d{2} \\d{1,2}\\:\\d{2}\\:\\d{2}).*"
          #- pack:
          #    labels:
          #      - time
          #      - biz_key
          #- labels:
          #    biz_key:
          #    biz_value:
          - timestamp:
              source: times
              format: '2006-01-02 15:04:05'
              location: Asia/Shanghai

  - job_name: kakfka_payinfo
    # file_sd_configs:
    #   - files:
    #     - /mnt/config/config/*.yaml
    #     refresh_interval: 1m
    kafka:
      brokers: 
      - 192.168.80.98:9092
      topics: 
      - dev
      - test
      - uat
      group_id: promtail_payinfo_davetest
      labels:
        job: kakfka_payinfo
    relabel_configs:
      - action: replace
        source_labels:
          - __meta_kafka_topic
        target_label: topic
      - action: replace
        source_labels:
          - __meta_kafka_partition
        target_label: partition
      - action: replace
        source_labels:
          - __meta_kafka_group_id
        target_label: group
      - action: replace
        source_labels:
          - __meta_kafka_message_key
        target_label: message_key
    pipeline_stages:
      - match:
          selector: '{job="kakfka_payinfo"} !~ ".*(PAYMENT_REFERENCE_LOG|CHECKOUT_PAYMENT_LOG).*"'
          action: drop
          drop_counter_reason: promtail_noisy_error
      - match:
          selector: '{job="kakfka_payinfo"}'
          stages:
          - json:
              expressions:
                log: log
                filename: filename
          - labels:
              filename:
      - match:
          selector: '{job="kakfka_payinfo"}'
          stages:
          - regex:
              source: filename
              expression: "^/works/log/(?P<org>.+?)/(?P<env>.+?)/(?P<app_name>.+?)/.+\\.log$"
          - labels:
              org:
              env:
              app_name:
              payinfo:
          - output:
              source: log
      - match:
          selector: '{job="kakfka_payinfo", app_name="payment-server"} |~ "PAYMENT_REFERENCE_LOG|CHECKOUT_PAYMENT_LOG"'
          stages:
          #- multiline:
          #    firstline: '^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}'
          #  max_lines: 500
          - regex:
              expression: "^(?P<time>\\d{4}\\-\\d{2}\\-\\d{2} \\d{1,2}\\:\\d{2}\\:\\d{2}).*"
          # - pack:
          #     labels:
          #       - time
          # - labels:
          #     time:
          - timestamp:
              source: times
              format: '2006-01-02 15:04:05'
              location: Asia/Shanghai

  - job_name: kafka_monitor
    # file_sd_configs:
    #   - files:
    #     - /mnt/config/config/*.yaml
    #     refresh_interval: 1m
    kafka:
      brokers:
        - 192.168.80.98:9092
      topics:
        - dev
        - test
        - uat
      group_id: promtail_monitor_davetest
      labels:
        job: kafka_monitor
    relabel_configs:
      - action: replace
        source_labels:
          - __meta_kafka_topic
        target_label: topic
      - action: replace
        source_labels:
          - __meta_kafka_partition
        target_label: partition
      - action: replace
        source_labels:
          - __meta_kafka_group_id
        target_label: group
      - action: replace
        source_labels:
          - __meta_kafka_message_key
        target_label: message_key
    pipeline_stages:
      - match:
          selector: '{job="kafka_monitor"}'
          stages:
            - json:
                expressions:
                  log: log
                  filename: filename
            - labels:
                filename:
      - match:
          selector: '{job="kafka_monitor", filename=~".*(?:error|tmlog).*"}'
          action: drop
          drop_counter_reason: promtail_noisy_error
      - match:
          selector: '{job="kafka_monitor"}'
          stages:
            - regex:
                source: filename
                expression: "^/works/log/(?P<org>.+?)/(?P<env>.+?)/(?P<app_name>.+?)/.+\\.log$"
            - labels:
                org:
                env:
                app_name:
            - output:
                source: log
      - match:
          selector: '{org=~".+"}'
          stages:
            #- multiline:
            #  firstline: '^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}'
            #  max_lines: 500
            - regex:
                #[bizGroup=default, bizKey=TRANSFER_MONEY_FAILED, bizDesc=交易异常-订单超时-转账, bizValue={"orderId":"orderNo1234567","time":"2023-04-07 12:40:37"}]
                expression: "^(?P<time>\\d{4}\\-\\d{2}\\-\\d{2} \\d{1,2}\\:\\d{2}\\:\\d{2}).+?\\[bizGroup=(?P<biz_group>.*?)\\,\\s*bizKey=(?P<biz_key>.*?)\\,\\s*bizDesc=(?P<biz_desc>.*?)\\,\\s*bizValue=(?P<biz_value>.*?)\\].*"
            #- pack:
            #    labels:
            #      - time
            #      - biz_key
            - labels:
                biz_group:
                biz_key:
                biz_desc:
                biz_value:
            - timestamp:
                source: times
                format: '2006-01-02 15:04:05'
                location: Asia/Shanghai
```

/etc/grafana/grafana.ini

```yaml
...
domain = logs.company.net

root_url = https://%(domain)s/

[smtp]
enabled = true
host = smtp.exmail.qq.com:465
user = 
# If the password contains # or ; you have to wrap it with triple quotes. Ex """
password = 
;cert_file =
;;key_file =
;skip_verify = true
from_address = 
from_name = Grafana
;# EHLO identity in SMTP dialog (defaults to instance_name)
;;ehlo_identity = dashboard.example.com
# SMTP startTLS policy (defaults to 'OpportunisticStartTLS')
startTLS_policy = StartTLS
```

fluent-bit/fluent-bit.conf

```yaml
[SERVICE]
    #Parsers_File parser.conf # 解析文件位置
    Flush        5           # 5秒写入一次ES
    Daemon       Off
    Log_Level    warn
    parsers_file parsers_multiline.conf

[INPUT]
    Name             tail
    Tag              dev
    path_key         filename
    #read_from_head   true
    multiline.parser multiline-regex
    Exclude_Path     /works/log/*/dev/**/*-error.log
    Path             /works/log/*/dev/**/*.log
    Buffer_Chunk_Size 4096KB
    Buffer_Max_Size   10240KB

[INPUT]
    Name             tail
    Tag              test
    path_key         filename
    #read_from_head   true
    multiline.parser multiline-regex
    Exclude_Path     /works/log/*/test/**/*-error.log
    Path             /works/log/*/test/**/*.log
    Buffer_Chunk_Size 4096KB
    Buffer_Max_Size   10240KB

[INPUT]
    Name             tail
    Tag              selftest
    path_key         filename
    #read_from_head   true
    multiline.parser multiline-regex
    Exclude_Path     /works/log/*/selftest/**/*-error.log
    Path             /works/log/*/selftest/**/*.log
    Buffer_Chunk_Size 4096KB
    Buffer_Max_Size   10240KB

[INPUT]
    Name             tail
    Tag              sandbox
    path_key         filename
    #read_from_head   true
    multiline.parser multiline-regex
    Exclude_Path     /works/log/*/sandbox/**/*-error.log
    Path             /works/log/*/sandbox/**/*.log
    Buffer_Chunk_Size 4096KB
    Buffer_Max_Size   10240KB

[INPUT]
    Name             tail
    Tag              uat
    path_key         filename
    #read_from_head   true
    multiline.parser multiline-regex
    Exclude_Path     /works/log/*/uat/**/*-error.log
    Path             /works/log/*/uat/**/*.log
    Buffer_Chunk_Size 4096KB
    Buffer_Max_Size   10240KB

# [FILTER]
#     name             parser
#     match            *
#     key_name         log
#     parser           named-capture-test

# [FILTER]
#     Name    grep
#     Match   configuration
#     #Exclude log level=INFO 
#     Regex    log =WARN

[OUTPUT]
    Name        kafka
    Match       dev
    Brokers     192.168.80.98:9092
    Topics      dev

[OUTPUT]
    Name        kafka
    Match       test
    Brokers     192.168.80.98:9092
    Topics      test

[OUTPUT]
    Name        kafka
    Match       selftest
    Brokers     192.168.80.98:9092
    Topics      selftest

[OUTPUT]
    Name        kafka
    Match       sandbox
    Brokers     192.168.80.98:9092
    Topics      sandbox

[OUTPUT]
    Name        kafka
    Match       uat
    Brokers     192.168.80.98:9092
    Topics      uat
```

fluent-bit/parsers_multiline.conf(if need)

```yaml
[MULTILINE_PARSER]
    name          multiline-regex
    type          regex
    flush_timeout 3000
    #
    # Regex rules for multiline parsing
    # ---------------------------------
    #
    # configuration hints:
    #
    #  - first state always has the name: start_state
    #  - every field in the rule must be inside double quotes
    #
    # rules |   state name  | regex pattern                  | next state
    # ------|---------------|--------------------------------------------
    rule      "start_state"   "/^\d{4}\-\d{2}\-\d{2} \d{1,2}\:\d{2}\:\d{2}.*/"  "cont"
    rule      "cont"          "/^([a-zA-Z]|\s)+.*/"                     "cont"



#[PARSER]
#    Name named-capture-test
#    Format regex
#    Regex /^(?<date>\d{4}\-\d{2}\-\d{2} \d{1,2}\:\d{2}\:\d{2})\.\d{3}\s+(?<message>.*)/m
```

Kakfa docker-compose.yml

```yaml
#https://segmentfault.com/a/1190000021746086
#https://github.com/wurstmeister/kafka-docker
version: '2'
services:
  zookeeper:
    image: wurstmeister/zookeeper
    volumes:
      - ./data:/data
    ports:
      - 2182:2181

  kafka9094:
    image: wurstmeister/kafka
    ports:
      - 9092:9092
    environment:
      KAFKA_BROKER_ID: 0
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://192.168.80.98:9092
      KAFKA_CREATE_TOPICS: "dev:3:1,test:3:1,selftest:3:1,uat:3:1,sandbox:3:1"   #kafka启动后初始化一个有3个partition(分区)1个副本名的topic
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092
    volumes:
      - ./kafka-logs:/kafka
    depends_on:
      - zookeeper
```

alertmanager-config.yaml

https://yunlzheng.gitbook.io/prometheus-book/parti-prometheus-ji-chu/alert/alert-manager-config

```yaml
global:
  smtp_smarthost: 'smtp.exmail.qq.com:25'
  smtp_from: 'xxx@xxx.com'
  smtp_auth_username: 'xxx@xxx.com'
  smtp_auth_password: 'xxx'
  smtp_require_tls: false
  #该参数定义了当Alertmanager持续多长时间未接收到告警后标记告警状态为resolved（已解决）。该参数的定义可能会影响到告警恢复通知的接收时间，读者可根据自己的实际场景进行定义，其默认值为5分钟
  resolve_timeout: 10m

templates:
- '/etc/alertmanager/config/*-resolved.tmpl'
- 
# 路由分组
#https://blog.csdn.net/bluuusea/article/details/104619235
#https://github.com/prometheus/alertmanager/blob/main/doc/examples/simple.yml
#https://kebingzao.com/2022/11/29/prometheus-4-alertmanager/
#https://zhuanlan.zhihu.com/p/63270049
#https://blog.csdn.net/qq_37843943/article/details/120665690
#https://blog.51cto.com/u_14205795/4561323
route:
  # 该节点中的警报会按'env', 'alertname', 'biz_group', 'biz_key'做 Group，每个分组中最多每group_interval发送一条警报，同样的警报最多repeat_interval发送一次
  # 分组规则，如果满足group_by中包含的标签，则这些报警会合并为一个通知发给receiver
  group_by: ['env', 'alertname', 'biz_group', 'biz_key']
  # 设置等待时间，在此等待时间内如果接收到多个报警，则会合并成一个通知发送给receiver
  group_wait: 30s
  # 收到相同的分组告警通知的时间间隔(上下两组发送告警的间隔时间)，如果满足，则再会查找是否已经满足repeat_interval，如果满足，则会再次发送
  # https://www.dianbanjiu.com/post/alertmanager-%E4%B8%AD%E4%B8%89%E4%B8%AA%E6%97%B6%E9%97%B4%E5%8F%82%E6%95%B0%E4%B8%8A%E7%9A%84%E4%B8%80%E4%BA%9B%E5%9D%91/
  # 再次发送时间在(group_interval+repeat_interval)左右
  group_interval: 5m
  # 发送相同告警的时间间隔，如：4h，表示4小时内不会发送相同的报警
  repeat_interval: 4h
  # 顶级路由配置的接收者（匹配不到子级路由，会使用根路由发送报警）
  receiver: 'emailreceivers'

  # 上面所有的属性都由所有子路由继承，并且可以在每个子路由上进行覆盖。
  routes:
      #用于系统默认BaseException的异常
    - receiver: emailreceivers
      group_by: ['env', 'alertname', 'biz_group', 'biz_key', 'biz_value']
      group_wait: 10s
      group_interval: 1m
      repeat_interval: 3m
      #默认为false。false：配置到满足条件的子节点点后直接返回，true：匹配到子节点后还会继续遍历后续子节点
      continue: false
      matchers:
        - biz_group="XPAY-SYSTEM-ERROR"

      #用于业务告警
    - receiver: alertmanager-webhook
    #- receiver: emailreceivers
    #- receiver: wecomreceivers
      group_by: ['env', 'alertname', 'biz_group', 'biz_key', 'biz_value']
      group_wait: 0s
      group_interval: 1m
      repeat_interval: 2m
      #默认为false。false：配置到满足条件的子节点点后直接返回，true：匹配到子节点后还会继续遍历后续子节点
      continue: false
      matchers:
        - biz_group!~"XPAY-SYSTEM-ERROR"


#定义所有接收者
receivers:
  - name: 'alertmanager-webhook'
    webhook_configs:
      - url: 'http://192.168.101.82:8088/alert'
        send_resolved: true

  - name: 'emailreceivers'
    email_configs:
    - to: 'xxx@xxx.com'
      html: '{{ template "email.to.html" . }}'
      headers: 
        #subject: ' {{ .CommonAnnotations.summary }} {{ if eq .Status "firing" }} DOWN {{ else if eq .Status "resolved" }} UP {{end}}'
        subject: '[{{ .Status }}]{{ .CommonAnnotations.summary }}'
        #subject: '预警通知'
      send_resolved: true

  - name: 'wecomreceivers'
    wechat_configs:
    - send_resolved: true
      corp_id: 'xxx'
      to_user: 'SZ122'
      #to_party: 'SZ122 | SZ097'
      message: '{{ template "wechat.default.message" . }}'
      agent_id: 'xxx'
      api_secret: 'xxx'

# 抑制器配置：抑制是指当某以此告警发出后，可以停止重复发送由此告警引发的其他告警的机制
# https://blog.csdn.net/qq_42883074/article/details/115544031
#当我们前面已经有一个告警了，那么后面的告警规则在触发的时候会先翻一下前面的已经触发的告警，去查看是否有severity: 'critical'的标签
#如果有了，那么去对比['alertname', 'biz_group', 'biz_key']标签是不是相同，如果是的话，
#那么去查看一下自己准备发的告警里标签是否存在severity: 'warning'，如果是，就不告警了
inhibit_rules:
  # 源标签警报触发时抑制含有目标标签的警报
  - source_match:
      # 此处的抑制匹配一定在最上面的route中配置不然，会提示找不key。
      # 前一个告警规则的标签
      severity: 'critical'
    target_match:
      # 目标标签值正则匹配，可以是正则表达式如: ".*MySQL.*"
      # 后面触发告警规则的标签
      severity: 'High'
    # 确保这个配置下的标签内容相同才会抑制，也就是说警报中必须有这三个标签值才会被抑制。
    equal: ['env', 'alertname', 'biz_group', 'biz_key']
```

loki/rules/fake/rules.yaml

```yaml
groups:
  - name: 系统日志
    rules:
      - alert: 系统日志-系统统一错误日志
        #=: exactly equal
        #!=: not equal
        #=~: regex matches
        #!~: regex does not match
        #expr: sum by (env, app_name) (count_over_time({env=~"dev", app_name="account-server"}|unpack|bizKey=~"\\w+"[1m]) >=1)
        #必须大于loki-config.yaml中的"evaluation_interval: 3s"的值
        expr: sum by (env, biz_group, biz_key, biz_desc, biz_value) (count_over_time({biz_group="XPAY-SYSTEM-ERROR",biz_key=~".+",biz_desc=~".+",biz_value=~".+"}[10s]) >=1)
        for: 1s
        labels:
          severity: High
        annotations:
          silenceResolved: "true"
          #emails: "xxx@xxx.com"
          #emailTemplate: "email1"
          #smsPhones: "11111111111,22222222222"
          #ttsPhones: "11111111111,22222222222"
          #wecomUrl: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=111122223333"
          #wecomTemplate: "wecom1"
          #只要捕捉到异常后，直接邮件通知相关对象通知一次
          emails: "xxx@xxx.com"
          emailTemplate: "email1"
          summary: "{{ $labels.biz_desc }}"
          description: "{{ $labels.biz_value }}"
          count: "{{ $value }}"
          
  - name: 支付
    rules:
      - alert: 交易异常
        expr: sum by (env, biz_group, biz_key, biz_desc, biz_value) (count_over_time({biz_group="XPAY-PAYMENT",biz_key=~".+",biz_desc=~".+",biz_value=~".+"}[5m]) >=10)
        for: 1s
        labels:
          severity: High
        annotations:
          silenceResolved: "true"
          #在5min内出现10笔同类型的超时，则直接电话+企业微信通知相关对象按照0min，3min时间间隔通知二次
          ttsPhones: "11111111111,22222222222"
          wecomUrl: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=111122223333"
          wecomTemplate: "wecom1"
          summary: "{{ $labels.biz_desc }}"
          description: "{{ $labels.biz_value }}"
          count: "{{ $value }}"

  - name: 对账
    rules:
      - alert: 外部对账失败
        expr: sum by (env, biz_group, biz_key, biz_desc, biz_value) (count_over_time({biz_group="XPAY-RECONCILICATION",biz_key=~".+",biz_desc=~".+",biz_value=~".+"}[10s]) >=1)
        for: 1s
        labels:
          severity: High
        annotations:
          silenceResolved: "true"
          #只要捕捉到异常后，直接企业微信通知相关对象通知一次
          wecomUrl: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=111122223333"
          wecomTemplate: "wecom1"
          summary: "{{ $labels.biz_desc }}"
          description: "{{ $labels.biz_value }}"
          count: "{{ $value }}"

      - alert: 内部对账失败
        expr: sum by (env, biz_group, biz_key, biz_desc, biz_value) (count_over_time({biz_group="XPAY-RECONCILICATION",biz_key=~".+",biz_desc=~".+",biz_value=~".+"}[10s]) >=1)
        for: 1s
        labels:
          severity: High
        annotations:
          silenceResolved: "true"
          #只要捕捉到异常后，直接企业微信通知相关对象通知一次
          wecomUrl: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=111122223333"
          wecomTemplate: "wecom1"
          summary: "{{ $labels.biz_desc }}"
          description: "{{ $labels.biz_value }}"
          count: "{{ $value }}"

  - name: 结算
    rules:
      - alert: 渠道结算失败
        expr: sum by (env, biz_group, biz_key, biz_desc, biz_value) (count_over_time({biz_group="XPAY-SETTLEMENT",biz_key=~".+",biz_desc=~".+",biz_value=~".+"}[10s]) >=1)
        for: 1s
        labels:
          severity: High
        annotations:
          silenceResolved: "true"
          #只要捕捉到异常后，直接企业微信通知相关对象通知一次
          wecomUrl: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=111122223333"
          wecomTemplate: "wecom1"
          summary: "{{ $labels.biz_desc }}"
          description: "{{ $labels.biz_value }}"
          count: "{{ $value }}"

      - alert: 商户结算失败
        expr: sum by (env, biz_group, biz_key, biz_desc, biz_value) (count_over_time({biz_group="XPAY-SETTLEMENT",biz_key=~".+",biz_desc=~".+",biz_value=~".+"}[10s]) >=1)
        for: 1s
        labels:
          severity: High
        annotations:
          silenceResolved: "true"
          #只要捕捉到异常后，直接企业微信通知相关对象通知一次
          wecomUrl: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=111122223333"
          wecomTemplate: "wecom1"
          summary: "{{ $labels.biz_desc }}"
          description: "{{ $labels.biz_value }}"
          count: "{{ $value }}"
          
      - alert: 服务商结算失败
        expr: sum by (env, biz_group, biz_key, biz_desc, biz_value) (count_over_time({biz_group="XPAY-SETTLEMENT",biz_key=~".+",biz_desc=~".+",biz_value=~".+"}[10s]) >=1)
        for: 1s
        labels:
          severity: High
        annotations:
          silenceResolved: "true"
          #只要捕捉到异常后，直接企业微信通知相关对象通知一次
          wecomUrl: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=111122223333"
          wecomTemplate: "wecom1"
          summary: "{{ $labels.biz_desc }}"
          description: "{{ $labels.biz_value }}"
          count: "{{ $value }}"

  - name: 审批
    rules:
      - alert: 审批失败
        expr: sum by (env, biz_group, biz_key, biz_desc, biz_value) (count_over_time({biz_group="XPAY-APPROVAL",biz_key=~".+",biz_desc=~".+",biz_value=~".+"}[10s]) >=1)
        for: 1s
        labels:
          severity: High
        annotations:
          silenceResolved: "true"
          #只要捕捉到异常后，直接企业微信通知相关对象通知一次
          wecomUrl: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=111122223333"
          wecomTemplate: "wecom1"
          summary: "{{ $labels.biz_desc }}"
          description: "{{ $labels.biz_value }}"
          count: "{{ $value }}"

  - name: 业务阻断
    rules:
      - alert: 业务阻断
        expr: sum by (env, biz_group, biz_key, biz_desc, biz_value) (count_over_time({biz_group="XPAY-BIZ-BLOCK",biz_key=~".+",biz_desc=~".+",biz_value=~".+"}[10s]) >=1)
        for: 1s
        labels:
          severity: High
        annotations:
          silenceResolved: "true"
          #只要捕捉到异常后，直接电话+企业微信通知相关对象
          wecomUrl: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=111122223333"
          wecomTemplate: "wecom1"
          summary: "{{ $labels.biz_desc }}"
          description: "{{ $labels.biz_value }}"
          count: "{{ $value }}"

  - name: 会计
    rules:
      - alert: 会计异常
        expr: sum by (env, biz_group, biz_key, biz_desc, biz_value) (count_over_time({biz_group="XPAY-ACCOUNTING",biz_key=~".+",biz_desc=~".+",biz_value=~".+"}[10s]) >=1)
        for: 1s
        labels:
          severity: High
        annotations:
          silenceResolved: "true"
          #只要捕捉到异常后，直接企业微信通知相关对象通知一次
          wecomUrl: "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=111122223333"
          wecomTemplate: "wecom1"
          summary: "{{ $labels.biz_desc }}"
          description: "{{ $labels.biz_value }}"
          count: "{{ $value }}"
```

config/WebCom-resolved.tmpl

```yaml
{{ define "wechat.default.message" }}
{{- if gt (len .Alerts.Firing) 0 -}}
{{- range $index, $alert := .Alerts -}}
{{- if eq $index 0 -}}
**********[{{ $alert.Status }}]告警通知**********
模块名称: {{ $alert.Labels.alertname }}
预警级别: {{ $alert.Labels.severity }}
故障业务: {{ $alert.Labels.biz_key }}
{{- end }}
=====================
预警名称: {{ $alert.Annotations.summary }}
预警警详情: {{ $alert.Annotations.description }}
错误次数: {{ $alert.Annotations.count  }}次
故障时间: {{ $alert.StartsAt.Local.Format "2006-01-02 15:04:05" }}
{{- end }}
{{- end }}

{{- if gt (len .Alerts.Resolved) 0 -}}
{{- range $index, $alert := .Alerts -}}
{{- if eq $index 0 -}}
**********恢复通知**********
模块名称: {{ $alert.Labels.alertname }}
预警级别: {{ $alert.Labels.severity }}
故障业务: {{ $alert.Labels.biz_key }}
{{- end }}
=====================
预警名称: {{ $alert.Annotations.summary }}
预警警详情: {{ $alert.Annotations.description }}
错误次数: {{ $alert.Annotations.count  }}次
故障时间: {{ $alert.StartsAt.Local.Format "2006-01-02 15:04:05" }}
恢复时间: {{ $alert.EndsAt.Local.Format "2006-01-02 15:04:05" }}
{{- end }}
{{- end }}
{{- end }}
```

config/WebCom.tmpl

```yaml
{{ define "wechat.default.message" }}
{{- if gt (len .Alerts.Firing) 0 -}}
{{- range $index, $alert := .Alerts -}}
{{- if eq $index 0 -}}
**********[{{ $alert.Status }}]告警通知**********
模块名称: {{ $alert.Labels.alertname }}
预警级别: {{ $alert.Labels.severity }}
故障业务: {{ $alert.Labels.biz_key }}
{{- end }}
=====================
预警名称: {{ $alert.Annotations.summary }}
预警警详情: {{ $alert.Annotations.description }}
错误次数: {{ $alert.Annotations.count  }}次
故障时间: {{ $alert.StartsAt.Local.Format "2006-01-02 15:04:05" }}
{{- end }}
{{- end }}
{{- end }}
```

config/Email-resolved.tmpl

```yaml
{{ define "email.to.html" }}
{{- if gt (len .Alerts.Firing) 0 -}}
{{- range $index, $alert := .Alerts -}}
========= ERROR ==========<br>
模块名称: {{ .Labels.alertname }}<br>
预警级别: {{ .Labels.severity }}<br>
故障业务: {{ .Labels.biz_key }}<br>
=====================<br/>
预警名称: {{ .Annotations.summary }}<br>
预警详情: {{ .Annotations.description }}<br>
错误次数: {{ .Annotations.count }}次<br>
故障时间: {{ .StartsAt.Format "2020-01-02 15:04:05"}} <br>
========= END ==========<br>
{{- end }}
{{- end }}
{{- if gt (len .Alerts.Resolved) 0 -}}
{{- range $index, $alert := .Alerts -}}
========= INFO ==========<br>
模块名称: {{ .Labels.alertname }}<br>
预警级别: {{ .Labels.severity }}<br>
故障业务: {{ .Labels.biz_key }}<br>
=====================<br/>
预警名称: {{ .Annotations.summary }}<br>
预警详情: {{ .Annotations.description }}<br>
错误次数: {{ .Annotations.count }}次<br>
故障时间: {{ .StartsAt.Format "2020-01-02 15:04:05"}} <br>
恢复时间：{{ .EndsAt.Format "2006-01-02 15:04:05" }}<br>
========= END ==========<br>
{{- end }}
{{- end }}
{{- end }}
```

config/Email.tmpl

```yaml
{{ define "email.to.html" }}
{{ range .Alerts }}
模块名称: {{ .Labels.alertname }}<br>
预警级别: {{ .Labels.severity }}<br>
故障业务: {{ .Labels.biz_key }}<br>
=====================<br/>
预警名称: {{ .Annotations.summary }}<br>
预警详情: {{ .Annotations.description }}<br>
错误次数: {{ .Annotations.count }}次<br>
故障时间: {{ .StartsAt.Format "2020-01-02 15:04:05"}} <br>
{{ end }}
{{ end }}
```

Installing:

```bash
#loki
mkdir -p /data/loki/data/ /works/conf/loki/
#Getting the loki id from the following command:
#docker exec loki id
#Like: uid=10001(loki) gid=10001(loki) groups=10001(loki)
chown -R 10001.10001 /data/loki/data/ /works/conf/loki/
#Creating the container:
docker run -d --name loki --restart=always \
-v /etc/localtime:/etc/localtime:ro \
-v /data/loki/data:/loki/data \
-v /works/conf/loki:/mnt/config \
-p 3100:3100 -p 7946:7946 -p 9096:9096 grafana/loki:2.8.0 \
-config.file=/mnt/config/loki-config.yaml

#grafana
# docker run -d --name grafana \
# -v /etc/localtime:/etc/localtime:ro \
# -e "GF_SMTP_ENABLED=true" \
# -e "GF_SMTP_HOST=smtp.example.com" \
# -e "GF_SMTP_USER=myuser" \
# -e "GF_SMTP_PASSWORD=mysecret" \
# -p 3000:3000 grafana/grafana:latest
chown -R 10001.10001 /data/grafana/
docker run -d --name grafana9 --restart=always \
-v /etc/localtime:/etc/localtime:ro \
-v /data/grafana/:/var/lib/grafana \
-v /data/grafana/grafana.ini:/etc/grafana/grafana.ini \
--user 10001:10001 \
-p 3000:3000 grafana/grafana-oss:9.3.1

#promtail
docker run -d --name promtail --restart=always \
-v /etc/localtime:/etc/localtime:ro \
-v /works/conf/promtail:/mnt/config \
-v /works/log:/works/log \
grafana/promtail:2.8.0 \
-config.file=/mnt/config/promtail-config.yaml \
-client.external-labels=hostname=${HOSTNAME}

docker run -d --name promtail-monitor --restart=always \
-v /etc/localtime:/etc/localtime:ro \
-v /works/conf/promtail/biz:/mnt/config \
grafana/promtail:2.8.0 \
-config.file=/mnt/config/promtail-config.yaml \
-client.external-labels=hostname=${HOSTNAME}

#fluent-bit
docker run  --name fluent-bit --restart=always --network host -d \
-v /data/fluent-bit/:/fluent-bit/etc \
-v /works/log:/works/log \
fluent/fluent-bit:2.0.8

#kafka
docker-compose up -d
#Test
docker exec -it kafka-kafka9094-1 sh
运行消费者,进行消息的监听
kafka-console-consumer.sh --bootstrap-server 192.168.102.82:9092 --topic account --from-beginning
#docker exec -it kafka_kafka9094_1 kafka-console-consumer.sh --bootstrap-server 192.168.101.82:9092 --topic dev --from-beginning
#docker exec -it kafka_kafka9094_1 kafka-topics.sh --create --bootstrap-server 192.168.101.82:9092 --replication-factor 1 --partitions 3 --topic sandbox

docker exec -it kafka-kafka9094-1 sh
打开一个新的ssh窗口,同样进入kafka的容器中,执行下面这条命令生产消息
kafka-console-producer.sh --broker-list 192.168.102.82:9092 --topic account

#alertmanager
mkdir -p /data/alertmanager/
chown -R 65534:65534 /data/alertmanager/

docker run -d --name alertmanager --restart=always \
-v /data/alertmanager:/etc/alertmanager \
-p 9093:9093 prom/alertmanager:v0.24.0 \
--config.file=/etc/alertmanager/alertmanager-config.yaml \
--web.external-url=http://192.168.80.98:9093 \
--cluster.advertise-address=0.0.0.0:9093 \
--log.level=debug
```

reload alertmanager: curl -XPOST http://am-test.zerofinance.net/-/reload

Cluster Installation:

```bash
#Loki(multiple machines):
mkdir -p /data/loki/data/ /works/conf/loki/
curl -O -L "https://github.com/grafana/loki/releases/download/v2.8.0/loki-linux-amd64.zip"
# extract the binary
unzip "loki-linux-amd64.zip"
# make sure it is executable
chmod a+x "loki-linux-amd64"
./loki-linux-amd64 -config.file=loki-config.yaml

loki-config.yaml:

auth_enabled: false

server:
  log_level: info
  http_listen_port: 3100
  grpc_listen_port: 9096
  grpc_server_max_recv_msg_size: 1572864000
  grpc_server_max_send_msg_size: 1572864000

memberlist:
  join_members: ["192.168.101.82","192.168.80.196"]
  dead_node_reclaim_time: 30s
  gossip_to_dead_nodes_time: 15s
  left_ingesters_timeout: 30s
  bind_addr: ['0.0.0.0']
  bind_port: 7946
  gossip_interval: 2s

#https://grafana.com/blog/2021/02/16/the-essential-config-settings-you-should-use-so-you-wont-drop-logs-in-loki/
#https://mpolinowski.github.io/docs/DevOps/Provisioning/2021-04-07--loki-prometheus-grafana/2021-04-07/
ingester:
  lifecycler:
    join_after: 10s
    observe_period: 5s
    ring:
      replication_factor: 2
      kvstore:
        store: memberlist
    # Duration to sleep before exiting to ensure metrics are scraped
    #final_sleep: 0s
  wal:
    enabled: true
    dir: /loki/data/wal
  # All chunks will be flushed when they hit this age, default is 1h
  max_chunk_age: 1h
  # Any chunk not receiving new logs in this time will be flushed
  chunk_idle_period: 1h
  # Must be greater than index read cache TTL if using an index cache (Default index read cache TTL is 5m)
  chunk_retain_period: 30s
  chunk_encoding: snappy
  # Loki will attempt to build chunks up to 1.5MB, flushing first if chunk_idle_period or max_chunk_age is reached first
  chunk_target_size: 1572864

schema_config:
  configs:
    - from: 2023-04-01
      object_store: aws
      schema: v11
      store: boltdb-shipper
      index:
        period: 24h
        prefix: index_

storage_config:
  boltdb_shipper:
    active_index_directory: /loki/data/boltdb-shipper-active
    cache_location: /loki/data/boltdb-shipper-cache
    # Can be increased for faster performance over longer query periods, uses more disk space
    cache_ttl: 24h
    shared_store: s3
  aws:
    s3forcepathstyle: false
    bucketnames: loki-files
    endpoint: https://oss-cn-hongkong.aliyuncs.com
    access_key_id: LTA11111111111
    secret_access_key: unseba111111111111111111
    insecure: true
  index_queries_cache_config:
    redis:
      endpoint: r-111111111.redis.rds.aliyuncs.com:6379
      password: 111111111
      expiration: 1h
    
chunk_store_config:
  chunk_cache_config:
    redis:
      endpoint: r-111111111.redis.rds.aliyuncs.com:6379
      password: 111111111
      expiration: 1h    
  write_dedupe_cache_config:
    redis:
      endpoint: r-111111111.redis.rds.aliyuncs.com:6379
      password: 111111111
      expiration: 1h

query_range:
  results_cache:
    cache:
      redis:
        endpoint: r-111111111.redis.rds.aliyuncs.com:6379
        password: 111111111
        expiration: 1h
  cache_results: true

compactor:
  working_directory: /loki/data/boltdb-shipper-compactor
  shared_store: s3

limits_config:
  ingestion_rate_mb: 2
  ingestion_burst_size_mb: 4
  max_streams_per_user: 0
  max_global_streams_per_user: 0
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

table_manager:
  retention_deletes_enabled: true
  retention_period: 168h

#https://grafana.com/docs/loki/latest/configuration/
ruler:
  storage:
    type: s3
    s3:
      s3forcepathstyle: false
      bucketnames: loki-files
      endpoint: https://oss-cn-hongkong.aliyuncs.com
      access_key_id: LTA11111111111
      secret_access_key: unseba111111111111111111
      insecure: true
  #rule_path: /loki/data/rules-temp
  alertmanager_url: http://192.168.101.82:9093
  # How frequently to evaluate rules.
  evaluation_interval: 5s
  # How frequently to poll for rule changes.
  poll_interval: 5s
  ring:
    kvstore:
      store: memberlist
  enable_api: true
```

Uninstalling:

```bash
#loki
docker rm -vf loki
/bin/rm -fr /data/loki/data/*
mkdir -p /data/loki/data/
#docker exec loki id
#uid=10001(loki) gid=10001(loki) groups=10001(loki)
chown -R 10001.10001 /data/loki/data/

#promtail
docker rm -vf promtail

#grafana
#docker rm -vf grafana
```

迁移grafana:

https://www.jianshu.com/p/bc37e2fc15e7

#### Collecting type

There is 2 way to collect logs:

```
1: fluent bit--->kafka--->promtail--->loki
                      --->logstash--->ES
2: promtail--->loki
3: fluent bit--->loki
```
Recommended: fluent bit--->kafka--->promtail--->loki

#### docker-compose

Not recommend, just for local study.

```bash
#depend on Linux: https://grafana.com/docs/loki/latest/installation/docker/
#Install with Docker Compose
wget https://raw.githubusercontent.com/grafana/loki/v2.7.0/production/docker-compose.yaml -O docker-compose.yaml
docker-compose -f docker-compose.yaml up
```

The modified docker-compose.yaml as follows:

docker-compose.yaml:

```yaml
version: "3"

networks:
  loki:

services:
  loki:
    image: grafana/loki:2.4.1
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - .:/mnt/config
    ports:
      - "3100:3100"
    command: -config.file=/mnt/config/loki-config.yaml
    networks:
      - loki

  promtail:
    image: grafana/promtail:2.4.1
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - .:/mnt/config
      - /mnt/d/works/log:/works/log
    command: -config.file=/mnt/config/promtail-config.yaml -client.external-labels=hostname=${HOSTNAME}
    networks:
      - loki

  grafana:
    image: grafana/grafana:latest
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /works/loki/docker/grafana.ini:/etc/grafana/grafana.ini
    command: -config.file=/mnt/config/promtail-config.yaml
    ports:
      - "3000:3000"
    networks:
      - loki
```

Starting:

```bash
#Starting:
docker-compose -f docker-compose.yaml up

#Deleting:
docker-compose -f docker-compose.yaml rm -vf
```

When it's started, you can check the status using the following url:

```
http://localhost:3100/ready
http://localhost:3100/metrics
```

Grafana URL is: http://localhost:3000/, default account is admin/admin

#### Grafana Configuration

```bash
env:
  Query: label_values(env)
system:
  Query: label_values({belongs="company", filename=~".*${env}.*"}, filename)
  Regex: /works\/log\/.+?\/.+?\/(.+?)\/.*/
hostname:
  Query: label_values({belongs="company", filename=~".*${env}/${system}.*"}, hostname)
filename:
  Query: label_values({belongs="company", filename=~".*${env}/${system}.*", filename!~".*(?:error|tmlog).*"}, filename)
  Regex: /.*\/(.+\.log)/
search:
  Type: Text box
Log browser:
  {env="${env}", app_name="${system}", hostname=~".*${hostname}.*", filename=~".*${filename}.*"}|~"(?i)$search"
```

## promtail

Promtail is an agent which ships the contents of local logs to a private Grafana Loki instance or Grafana Cloud. It is usually deployed to every machine that has applications needed to be monitored.

More details: https://grafana.com/docs/loki/latest/clients/promtail/

## Configuration

### Promtail Config

All of the rule of collecting logs will be configured in the "promtail-config.yaml"

```
scrape_configs:
- job_name: saas-tenant-management-system
  pipeline_stages:
  - match:
      selector: '{app_name="saas-tenant-management-system"}'
      stages:
      #https://grafana.com/docs/loki/latest/clients/promtail/stages/multiline/
      #Working on collecting the multiline, like exception logs
      - multiline:
          firstline: '^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}'
          max_lines: 500
      #https://grafana.com/docs/loki/latest/clients/promtail/stages/regex/
      - regex:
          expression: "^(?P<timestamp>\\d{4}\\-\\d{2}\\-\\d{2} \\d{1,2}\\:\\d{2}\\:\\d{2})\\.\\d+ .*$"
      #https://grafana.com/docs/loki/latest/fundamentals/labels/
      #Working for the variables of searching.
      #- labels:
      #    time:
      - timestamp:
          format: RFC3339Nano
          source: timestamp
  static_configs:
  - targets:
      - localhost
    labels:
      app_name: saas-tenant-management-system
      belongs: alphatimes
      __path__: /works/log/alphatimes/**/saas-tenant-management-system/**/*.log
......
```

Notice:

If multline fields are configured, it won't appear in the lables of seaching. it conflict witch regex stage. For example:

"loglevel" field configured in regex stage, if you the "loglevel" contain multiline, you wan to search by: "{loglevel="ERROR"}", it won't display the multiline logs, just single log, althought "loglevel" contain multiline logs.

### Grafana Config

Grafana 6.0 and more recent versions have built-in support for Grafana Loki. Use Grafana 6.3 or a more recent version to take advantage of LogQL functionality.

Log into your Grafana instance. If this is your first time running Grafana, the username and password are both defaulted to admin.

In Grafana, go to Configuration > Data Sources via the cog icon on the left sidebar.
Click the big + Add data source button.
Choose Loki from the list.

The http URL field should be the address of your Loki server. For example, when running locally or with Docker using port mapping, the address is likely http://localhost:3100. When running with docker-compose or Kubernetes, the address is likely http://loki:3100.

To see the logs, click Explore on the sidebar, select the Loki datasource in the top-left dropdown, and then choose a log stream using the Log labels button.

#### Variables

Creating a new dashboard named "Loki"(just first time), entering "dashboards settings"(gear icon):

![01.png](/images/Loki-Log-System/01.png)

Env: 
```
Query: label_values(env)
```

![02.png](/images/Loki-Log-System/02.png)

System: 
```
Query: label_values({belongs="company", filename=~".*${env}.*"}, filename)
Regex: /works\/log\/.+?\/.+?\/(.+?)\/.*/
```

![03.png](/images/Loki-Log-System/03.png)

Hostname:
```
Query: label_values({belongs="company", filename=~".*${env}/${system}.*"}, hostname)
```

![04.png](/images/Loki-Log-System/04.png)

Filename:
```
Query: label_values({belongs="company", filename=~".*${env}/${system}.*", filename!~".*(?:error|tmlog).*"}, filename)
Regex: /.*\/(.+\.log)/
```

![10.png](/images/Loki-Log-System/10.png)

Search: 

![05.png](/images/Loki-Log-System/05.png)

#### Log Panel

![06.png](/images/Loki-Log-System/06.png)

![07.png](/images/Loki-Log-System/07.png)

Log browser: 
```
{env="${env}", app_name="${system}", hostname=~".*${hostname}.*", filename=~".*${filename}.*"}|~"(?i)$search"
```

![08.png](/images/Loki-Log-System/08.png)

![09.png](/images/Loki-Log-System/09.png)

## Kubernetes

Using helm to install loki on the k8s environment easyly, but recommend it by customed congratulation:

Notice: It's weird the way of Kubernetes couldn't collection the logs completely, finally I used the docker to deploy.

### Heml

Installing heml:

```bash
#Linux:
#https://helm.sh/docs/intro/install/#from-script
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

#Windows:
#Members of the Helm community have contributed a Helm package build to Chocolatey. This package is generally up to date. run as administrator:
choco install kubernetes-helm
```

Pulling repositories:

```bash
#https://grafana.com/docs/loki/latest/installation/helm/
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
cd /works/loki

kubectl create ns loki

#helm pull grafana/loki-stack
helm pull grafana/grafana
helm pull grafana/loki

helm pull grafana/promtail
tar zxvf promtail-3.11.0.tgz
```

Configure:

```bash
#Create PersistentVolume
cat PersistentVolume.yaml 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: loki-pv-volume
  labels:
    type: local
spec:
  storageClassName: loki
  capacity:
    storage: 30Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/data/loki-data"

kubectl create -f PersistentVolume.yaml

#PersistentVolumeClaim.yaml
cat PersistentVolumeClaim.yaml 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: loki-pv-claim
  namespace: loki
spec:
  storageClassName: loki
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 30Gi

kubectl create -f PersistentVolumeClaim.yaml

#Notice: Since the persistence volume based on local system, make sure hostPath.path is shared with multiple machines that loki may be deployed on. or you can use nfs model of persistence volume.

#Making sure k8s has privilege to access hostPath.path. refer to the following configuration:
securityContext.fsGroup: 10001
  runAsGroup: 10001
  runAsNonRoot: true
  runAsUser: 10001

#chown hostPath.path:
sudo chown -R 10001:10001 /data/data/loki-data/

#configure loki
vim loki/values.yaml
#Enable persistence
persistence:
  enabled: true
  accessModes:
  - ReadWriteOnce
  size: 30Gi
  annotations: {}
  # selector:
  #   matchLabels:
  #     app.kubernetes.io/name: loki
  # subPath: ""
  existingClaim: loki-pv-claim

#configure promtail
vim promtail/values.yaml

extraArgs:
  - -client.external-labels=hostname=$(HOSTNAME)

config:
  ...  
  lokiAddress: http://loki:3100/loki/api/v1/push

extraVolumes:
  - name: journal
    hostPath:
      path: /var/log/journal
  - name: logs
    hostPath:
      path: /works/log

extraVolumeMounts:
  - name: journal
    mountPath: /var/log/journal
    readOnly: true
  - name: logs
    mountPath: /works/log
    readOnly: true

    extraScrapeConfigs: |
      - job_name: company-job 
        pipeline_stages:
        - match:
            selector: '{belongs="company", filename=~".*(?:error|tmlog).*"}'
            action: drop
            drop_counter_reason: promtail_noisy_error
        - match:
            selector: '{belongs="company"}'
            stages:
            - regex:
                source: filename
                expression: "^/works/log/(?P<org>.+?)/(?P<env>.+?)/(?P<app_name>.+?)/.+\\.log$"
            - labels:
                org:
                env:
                app_name:
        - match:
            selector: '{org=~".+"}'
            stages:
            - multiline:
                firstline: '^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}'
                max_lines: 500
            - regex:
                expression: "^(?P<time>\\d{4}\\-\\d{2}\\-\\d{2} \\d{1,2}\\:\\d{2}\\:\\d{2}).*"
            - timestamp:
                source: time
                format: '2006-01-02 15:04:05'
                location: Asia/Shanghai
        static_configs:
        - targets:
            - localhost
          labels:
            belongs: company
            __path__: /works/log/**/*.log
```

### Installation

Installing the revlant components:

```bash
cd /works/loki/
helm upgrade --install loki-grafana grafana/ -n loki
helm upgrade --install loki loki/ -n loki
#helm upgrade --install promtail promtail/ --set "loki.serviceName=loki" -n loki
#If deploying a individual machine, don't need "--set" parameter
#kubectl get nodes --show-labels
#helm upgrade --install promtail promtail/ -n loki --set nodeSelector."kubernetes\.io/hostname"=192.168.80.201
#helm upgrade --install promtail promtail/ -n loki --set nodeSelector."kubernetes\.io/hostname"=k8s-master-cluster
helm upgrade --install promtail promtail/ -n loki

#Waiting all of the pods are ready:
kubectl get pods -n loki -w

#grafana
#Getting the grafana password using this:
kubectl get secret --namespace loki loki-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
#Exposed 3000 port outsize so that you can access it on your browser:
kubectl port-forward --namespace loki service/loki-grafana 3000:80 --address 0.0.0.0
URL: http://192.168.80.98:3000/
Datasource: http://loki:3100/

#Configure grafana

#Loki Kubernetes Logs
k8s logs dashboard:
https://grafana.com/grafana/dashboards/15141

#company Logs
env:
  Query: label_values(env)
system:
  Query: label_values({belongs="company", filename=~".*${env}.*"}, filename)
  Regex: /works\/log\/.+?\/.+?\/(.+?)\/.*/
hostname:
  Query: label_values({belongs="company", filename=~".*${env}/${system}.*"}, hostname)
filename:
  Query: label_values({belongs="company", filename=~".*${env}/${system}.*", filename!~".*(?:error|tmlog).*"}, filename)
  Regex: /.*\/(.+\.log)/
search:
  Type: Text box
Log browser:
  {env="${env}", app_name="${system}", hostname=~".*${hostname}.*", filename=~".*${filename}.*"}|~"(?i)$search"
```

### Uninstallation

Uninstalling the revlant components:

```bash
helm uninstall loki  -n loki
#kubectl -n loki delete pvc storage-loki-0
#rm -fr /data/data/loki-data/loki/
helm uninstall promtail  -n loki
helm uninstall loki-grafana  -n loki
#kubectl -n loki get pvc
kubectl -n loki delete pvc loki-pv-claim
#kubectl -n loki get pv
kubectl delete pv loki-pv-volume
```

## Optimize

https://grafana.com/blog/2021/02/16/the-essential-config-settings-you-should-use-so-you-wont-drop-logs-in-loki/

## Troubleshooting

error: code = ResourceExhausted desc = trying to send message larger than max

- https://blog.csdn.net/qq_41980563/article/details/122186703

429 Too Many Requests Ingestion rate limit exceeded

- https://www.codeleading.com/article/71834625328/

Maximum active stream limit exceeded

- https://izsk.me/2021/03/18/Loki-Prombles/
- https://www.bboy.app/2020/07/08/%E4%BD%BF%E7%94%A8loki%E8%BF%9B%E8%A1%8C%E6%97%A5%E5%BF%97%E6%94%B6%E9%9B%86/

Loki: Bad Request. 400. invalid query, through

- https://zhuanlan.zhihu.com/p/457985915
- https://blog.csdn.net/u010948569/article/details/108387324

insane quantity of files in chunks directory

- https://github.com/grafana/loki/issues/1258

Searching data slowly

This reason may occur by some inappropriate configured labels, using the following command to diagnose:

```
logcli series --analyze-labels '{app_name="hkcash-server"}'
```

You can  this article to see how to avoid this issue:

https://grafana.com/docs/loki/latest/best-practices/

## Alarmmanager

https://www.bilibili.com/read/cv17329220

## Configuration backup

Loki Config: [loki.zip](/files/Loki-Log-System/Loki.zip)

AlertManager Config: [AlertManager.zip](/files/Loki-Log-System/AlertManager.zip)

Grafana Config: [grafana.tgz](/files/Loki-Log-System/grafana.tgz)

## Reference 

- https://grafana.com/docs/loki/latest/getting-started/get-logs-into-loki/
- https://grafana.com/docs/loki/latest/fundamentals/labels/
- https://grafana.com/docs/loki/latest/logql/log_queries/
- https://grafana.com/docs/loki/latest/clients/promtail/stages/multiline/
- https://grafana.com/docs/loki/latest/clients/promtail/stages/regex/
- https://github.com/google/re2/wiki/Syntax
- https://grafana.com/docs/grafana/latest/variables/
- https://grafana.com/docs/grafana/latest/datasources/loki/
- https://www.jianshu.com/p/474a5034a501
- https://www.jianshu.com/p/259a1d656745
- https://www.jianshu.com/p/672173b609f7
- https://www.cnblogs.com/ssgeek/p/11584870.html
- https://grafana.com/docs/loki/latest/installation/helm/
- https://blog.csdn.net/weixin_49366475/article/details/114384817
- https://blog.luxifan.com/blog/post/lucifer/1.%E5%88%9D%E8%AF%86Loki-%E4%B8%80
- https://blog.csdn.net/bluuusea/article/details/104619235
- https://blog.51cto.com/u_14205795/4561323
- https://www.cnblogs.com/punchlinux/p/17035742.html
- https://kebingzao.com/2022/11/29/prometheus-4-alertmanager/
- https://blog.csdn.net/wang7531838/article/details/107809870
- https://blog.51cto.com/u_12965094/2690336
- https://blog.csdn.net/qq_42883074/article/details/115544031
- https://blog.csdn.net/bluuusea/article/details/104619235
- http://www.mydlq.club/article/126/
- https://www.orchome.com/10106
- https://blog.51cto.com/u_14320361/2461666
- https://chenzhonzhou.github.io/2020/07/17/alertmanager-de-gao-jing-mo-ban/
- https://blog.csdn.net/weixin_44911287/article/details/124149964
- https://blog.csdn.net/easylife206/article/details/127581630


kubectl create ns zero-loki
kubectl -n zero-loki create configmap --from-file configmap/loki-config-cluster.yaml loki-config
kubectl -n zero-loki create configmap --from-file configmap/rules.yaml loki-rules

kubectl -n zero-loki describe configmap loki-config
kubectl -n zero-loki describe configmap loki-rules

kubectl -n zero-loki apply -f zero-loki.yml

kubectl -n zero-loki get po,svc -owide
#kubectl -n zero-loki logs -f loki-cluster-57777d6d6-vkbc5
#kubectl -n zero-loki describe po loki-cluster-57777d6d6-8tfgd


>kubectl.exe -n zero-loki exec -it kafka-0 bash
kafka-topics.sh --create --zookeeper "zookeeper-headless:2181" --replication-factor 2 --partitions 3 --topic uat
kafka-console-producer.sh --broker-list "192.168.80.99:9192,192.168.80.99:9292,192.168.80.99:9392" --topic uat
kafka-console-consumer.sh --bootstrap-server "192.168.80.99:9192,192.168.80.99:9292,192.168.80.99:9392" --topic uat --from-beginning
kafka-topics.sh --list --zookeeper "zookeeper-headless:2181"

kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list "192.168.80.99:9192,192.168.80.99:9292,192.168.80.99:9392" --topic uat

kubectl -n xpay-logs run -ti --rm centos-test --image=centos:7 --overrides='{"spec": { "nodeSelector": {"xpay-env": "logs"}}}'