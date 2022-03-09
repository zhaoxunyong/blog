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

### Overview

https://grafana.com/docs/loki/latest/fundamentals/overview/#overview

### Installation

There are losts of way to install Loki, here just show it by docker. the other ways please refer to: https://grafana.com/docs/loki/latest/installation/

```bash
#depend on Linux: https://grafana.com/docs/loki/latest/installation/docker/
#Install with Docker Compose
wget https://raw.githubusercontent.com/grafana/loki/v2.4.2/production/docker-compose.yaml -O docker-compose.yaml
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
      - .:/mnt/config
    ports:
      - "3100:3100"
    command: -config.file=/mnt/config/loki-config.yaml
    networks:
      - loki

  promtail:
    image: grafana/promtail:2.4.1
    volumes:
      - .:/mnt/config
      - /mnt/d/works/log:/works/log
    command: -config.file=/mnt/config/promtail-config.yaml
    networks:
      - loki

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    networks:
      - loki
```

loki-config.yaml:

```yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  path_prefix: /tmp/loki
  storage:
    filesystem:
      chunks_directory: /tmp/loki/chunks
      rules_directory: /tmp/loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

ruler:
  alertmanager_url: http://localhost:9093
```

promtail-config.yaml:

```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
- job_name: stms
  pipeline_stages:
  - match:
      selector: '{job="stms_logs"}'
      stages:
      - multiline:
          firstline: '^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}'
          max_lines: 10000
      - regex:
          expression: "^(?P<time>\\d{4}\\-\\d{2}\\-\\d{2} \\d{1,2}\\:\\d{2}\\:\\d{2})\\.\\d+ (?P<message>(.*))$"
      - labels:
          time:
          message:
  static_configs:
  - targets:
      - 192.168.3.2
    labels:
      job: stms_logs
      env: dev
      host: 192.168.3.2
      __path__: /works/log/saas/saas-tenant-management-system/**/*.log
- job_name: slbs
  pipeline_stages:
  - match:
      selector: '{job="slbs_logs"}'
      stages:
      - multiline:
          firstline: '^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}'
          max_lines: 10000
      - regex:
          expression: "^(?P<time>\\d{4}\\-\\d{2}\\-\\d{2} \\d{1,2}\\:\\d{2}\\:\\d{2})\\.\\d+ (?P<message>(.*))$"
      - labels:
          time:
          message:
  static_configs:
  - targets:
      - 192.168.3.3
    labels:
      job: slbs_logs
      env: dev
      host: 192.168.3.3
      __path__: /works/log/saas/saas-loan-business-system/**/*.log
- job_name: notify
  pipeline_stages:
  - match:
      selector: '{job="notify_logs"}'
      stages:
      - multiline:
          firstline: '^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}'
          max_lines: 10000
      - regex:
          expression: "^(?P<time>\\d{4}\\-\\d{2}\\-\\d{2} \\d{1,2}\\:\\d{2}\\:\\d{2})\\.\\d+ (?P<message>(.*))$"
      - labels:
          time:
          message:
  static_configs:
  - targets:
      - 192.168.3.4
    labels:
      job: notify_logs
      env: dev
      host: 192.168.3.4
      __path__: /works/log/saas/saas-notify-system/**/*.log
```

Loki Config: [loki.zip](/files/Loki-Log-System/Loki.zip)

### Starting

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

## promtail

Promtail is an agent which ships the contents of local logs to a private Grafana Loki instance or Grafana Cloud. It is usually deployed to every machine that has applications needed to be monitored.

More details: https://grafana.com/docs/loki/latest/clients/promtail/

## Configuration

### Promtail Config

All of the rule of collecting logs will be configured in the "promtail-config.yaml"

```
scrape_configs:
- job_name: stms
  pipeline_stages:
  - match:
      selector: '{job="stms_logs"}'
      stages:
      #https://grafana.com/docs/loki/latest/clients/promtail/stages/multiline/
      #Working on collecting the multiline, like exception logs
      - multiline:
          firstline: '^\d{4}-\d{2}-\d{2} \d{1,2}:\d{2}:\d{2}'
          max_lines: 10000
      #https://grafana.com/docs/loki/latest/clients/promtail/stages/regex/
      - regex:
          expression: "^(?P<time>\\d{4}\\-\\d{2}\\-\\d{2} \\d{1,2}\\:\\d{2}\\:\\d{2})\\.\\d+ (?P<message>(.*))$"
      #https://grafana.com/docs/loki/latest/fundamentals/labels/
      #Working for the variables of searching.
      - labels:
          time:
          message:
  static_configs:
  - targets:
      - 192.168.3.2
    labels:
      job: stms_logs
      env: dev
      host: 192.168.3.2
      __path__: /works/log/saas/saas-tenant-management-system/**/*.log
- job_name: slbs
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

Query: label_values(env)

![02.png](/images/Loki-Log-System/02.png)

System: 

Query: label_values(job)
#cut the "_logs"
Regex: ^(.+?)_logs$  

![03.png](/images/Loki-Log-System/03.png)

Host: https://github.com/grafana/grafana/issues/25205#issuecomment-782217006

Query: label_values({job="${system}_logs"},  host)

![04.png](/images/Loki-Log-System/04.png)

Search: 

![05.png](/images/Loki-Log-System/05.png)

#### Log Panel

![06.png](/images/Loki-Log-System/06.png)

![07.png](/images/Loki-Log-System/07.png)

![08.png](/images/Loki-Log-System/08.png)

![09.png](/images/Loki-Log-System/09.png)




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

