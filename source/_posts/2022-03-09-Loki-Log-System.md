---
title: Loki Log System
date: 2022-03-09 16:04:26
categories: ["Log"]
tags: ["Log"]
toc: true
---

This article recorded how to install and configure Log System based on Loki developing by Grafana.

<!-- more -->

## Loki

What's the Grafana Loki?

Loki is a log aggregation system designed to store and query logs from all your applications and infrastructure.

Documents located in: https://grafana.com/docs/loki/latest/

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
    - from: 2022-01-01
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
  retention_period: 336h
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
  - url: http://192.168.102.82:3100/loki/api/v1/push

scrape_configs:
  - job_name: kafka
    # file_sd_configs:
    #   - files:
    #     - /mnt/config/config/*.yaml
    #     refresh_interval: 1m
    kafka:
      brokers: 
      - 192.168.102.82:9092
      topics: 
      - account
      - configuration
      group_id: promtail-account
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
          - multiline:
              firstline: '^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}'
              max_lines: 500
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
```

For collectiing specific contexts:

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://192.168.80.196:3100/loki/api/v1/push

scrape_configs:
  - job_name: kakafka_payinfo2
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
      group_id: promtail_payinfo2
      labels:
        job: kakafka_payinfo2
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
          selector: '{job="kakafka_payinfo2"} !~ ".*PAYMENT_REFERENCE_LOG.*"'
          action: drop
          drop_counter_reason: promtail_noisy_error
      - match:
          selector: '{job="kakafka_payinfo2"}'
          stages:
          - json:
              expressions:
                log: log
                filename: filename
          - labels:
              filename:
      - match:
          selector: '{job="kakafka_payinfo2"}'
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
          selector: '{job="kakafka_payinfo2", app_name="payment-server"} |~ "PAYMENT_REFERENCE_LOG"'
          stages:
          - multiline:
              firstline: '^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}'
              max_lines: 500
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
    Parsers_File parser.conf # 解析文件位置
    Flush        5           # 5秒写入一次ES
    Daemon       Off
    Log_Level    debug
    parsers_file parsers_multiline.conf

[INPUT]
    Name             tail
    Tag              dev
    path_key         filename
    #read_from_head   true
    #multiline.parser multiline-regex-test
    Path             /works/log/xpay/dev/*/*.log
    Buffer_Chunk_Size 320KB
    Buffer_Max_Size   520KB

[INPUT]
    Name             tail
    Tag              test
    path_key         filename
    #read_from_head   true
    #multiline.parser multiline-regex-test
    Path             /works/log/xpay/test/*/*.log
    Buffer_Chunk_Size 320KB
    Buffer_Max_Size   520KB


[INPUT]
    Name             tail
    Tag              uat
    path_key         filename
    #read_from_head   true
    #multiline.parser multiline-regex-test
    Path             /works/log/xpay/uat/*/*.log
    Buffer_Chunk_Size 320KB
    Buffer_Max_Size   520KB

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
    Match       uat
    Brokers     192.168.80.98:9092
    Topics      uat
```

fluent-bit/parsers_multiline.conf(if need)

```yaml
[MULTILINE_PARSER]
    name          multiline-regex-test
    type          regex
    flush_timeout 1000
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
    rule      "cont"          "/^[\sa-zA-Z]+.*/"                     "cont"



[PARSER]
    Name named-capture-test
    Format regex
    Regex /^(?<date>\d{4}\-\d{2}\-\d{2} \d{1,2}\:\d{2}\:\d{2})\.\d{3}\s+(?<message>.*)/m
```

Kakfa docker-compose.yml

```yaml
#https://segmentfault.com/a/1190000021746086
#https://github.com/wurstmeister/kafka-docker
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
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://192.168.102.82:9092
      KAFKA_CREATE_TOPICS: "dev:3:0,test:3:0,uat:3:0"   #kafka启动后初始化一个有2个partition(分区)0个副本名的topic
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092
    volumes:
      - ./kafka-logs:/kafka
    depends_on:
      - zookeeper
```

alertmanager-config.yaml

```yaml
global:
  smtp_smarthost: 'smtp.exmail.qq.com:25'
  smtp_from: 'xxx@xxx'
  smtp_auth_username: 'xxx@xxx'
  smtp_auth_password: 'xxx*'
  smtp_require_tls: false
  resolve_timeout: 10m
templates:
- '/etc/alertmanager/config/*.tmpl'
route:
  group_by: ['alertname']
  group_wait: 3s
  group_interval: 5s
  repeat_interval: 10s
  #receiver: 'web.hook'
  receiver: 'wecomreceivers'
  # routes:
  # - receiver: 'wechat'
  #   continue: true
receivers:
  - name: 'web.hook'
    email_configs:
    - to: 'xxx@xxx'
      send_resolved: true
  - name: allreceivers
    webhook_configs:
      - url: http://192.168.102.82:8080/adapter/wx
        send_resolved: true
    #webhook_configs:
    #  - url: 'http://127.0.0.1:5001/'
  - name: 'wecomreceivers'
    wechat_configs:
    - send_resolved: true
      corp_id: 'xxx'
      to_user: 'SZ122'
      #to_party: 'SZ122 | SZ097'
      message: '{{ template "wechat.default.message" . }}'
      agent_id: 'xxx'
      api_secret: 'xxx'
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
```

loki/rules/fake/rules.yaml

```yaml
groups:
    - name: service OutOfMemoryError
      rules:
        # 关键字监控
        - alert: loki check words error
          expr: sum by (org, env, app_name) (count_over_time({env=~"\\w+"} |= "level=ERROR" [1m]) > 1)
          #用于表示只有当触发条件持续一段时间后才发送告警。在等待期间新产生告警的状态为pending。
          for: 5s
          labels:
            severity: critical
          annotations:
            description: '{{$labels.env}} {{$labels.hostname}} file {{$labels.filename}} has  {{ $value }} error'
            summary: java has error
```

config/WebCom.tmpl

```yaml
{{ define "wechat.default.message" }}
{{- if gt (len .Alerts.Firing) 0 -}}
{{- range $index, $alert := .Alerts -}}
{{- if eq $index 0 -}}
**********告警通知**********
告警类型: {{ $alert.Labels.alertname }}
告警级别: {{ $alert.Labels.severity }}
{{- end }}
=====================
告警主题: {{ $alert.Annotations.summary }}
告警详情: {{ $alert.Annotations.description }}
故障时间: {{ $alert.StartsAt.Local }}
{{ if gt (len $alert.Labels.instance) 0 -}}故障实例: {{ $alert.Labels.instance }}{{- end -}}
{{- end }}
{{- end }}

{{- if gt (len .Alerts.Resolved) 0 -}}
{{- range $index, $alert := .Alerts -}}
{{- if eq $index 0 -}}
**********恢复通知**********
告警类型: {{ $alert.Labels.alertname }}
告警级别: {{ $alert.Labels.severity }}
{{- end }}
=====================
告警主题: {{ $alert.Annotations.summary }}
告警详情: {{ $alert.Annotations.description }}
故障时间: {{ $alert.StartsAt.Local }}
恢复时间: {{ $alert.EndsAt.Local }}
{{ if gt (len $alert.Labels.instance) 0 -}}故障实例: {{ $alert.Labels.instance }}{{- end -}}
{{- end }}
{{- end }}
{{- end }}
```




Loki Config: [loki.zip](/files/Loki-Log-System/Loki.zip)

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
-p 3100:3100 grafana/loki:2.7.0 \
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
grafana/promtail:2.7.0 \
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
#docker exec -it kafka-kafka9094-1 kafka-console-consumer.sh --bootstrap-server 192.168.101.82:9092 --topic dev --from-beginning

docker exec -it kafka-kafka9094-1 sh
打开一个新的ssh窗口,同样进入kafka的容器中,执行下面这条命令生产消息
kafka-console-producer.sh --broker-list 192.168.102.82:9092 --topic account

#alertmanager
chown -R 65534:65534 /data/alertmanager/

docker run -d --name alertmanager --restart=always \
-v /data/alertmanager:/etc/alertmanager \
-p 9093:9093 prom/alertmanager:v0.24.0 \
--config.file=/etc/alertmanager/alertmanager-config.yaml
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

```shell
wget https://github.com/prometheus/alertmanager/releases/download/v0.24.0/alertmanager-0.24.0.linux-amd64.tar.gz

```

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