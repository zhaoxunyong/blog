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

Query: label_values({job="${system}_logs"}, host)

![04.png](/images/Loki-Log-System/04.png)

Filename:

Query: label_values({job="${system}_logs"}, filename)
Regex: /.*\/(.+\.log)/

![10.png](/images/Loki-Log-System/10.png)

Search: 

![05.png](/images/Loki-Log-System/05.png)

#### Log Panel

![06.png](/images/Loki-Log-System/06.png)

![07.png](/images/Loki-Log-System/07.png)

Log browser: {env="$env", job="${system}_logs", host=~".*${host}", filename=~".*${filename}"}|~"(?i)$search"

![08.png](/images/Loki-Log-System/08.png)

![09.png](/images/Loki-Log-System/09.png)

## Kubernetes

Using helm to install loki on the k8s environment easyly, but recommend it by customed congratulation:

Installing heml:

```bash
#https://helm.sh/docs/intro/install/#from-script
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
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
      - job_name: journal
        journal:
          path: /var/log/journal
          max_age: 12h
          labels:
            job: systemd-journal
        relabel_configs:
          - source_labels: ['__journal__systemd_unit']
            target_label: 'unit'
          - source_labels: ['__journal__hostname']
            target_label: 'hostname'
            
      - job_name: app-gateway-dev
        pipeline_stages:
        - match:
            selector: '{app_name="app-gateway-dev"}'
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
            - localhost
          labels:
            app_name: app-gateway-dev
            env: dev
            __path__: /works/log/hkcash/dev/app-gateway/*.log
```

Installing the revlant components:

```bash
cd /works/loki/
helm upgrade --install loki-grafana grafana/ -n loki
helm upgrade --install loki loki/ -n loki
helm upgrade --install promtail promtail/ --set "loki.serviceName=loki" -n loki

#Waiting all of the pods are ready:
kubectl get pods -n loki -w

#grafana
#Getting the grafana password using this:
kubectl get secret --namespace loki loki-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
#Exposed 3000 port outsize so that you can access it on your browser:
kubectl port-forward --namespace loki service/loki-grafana 3000:80 --address 0.0.0.0
URL: http://192.168.80.98:3000/
Datasource: http://loki:3100/
k8s logs dashboard:
https://grafana.com/grafana/dashboards/15141
#Configure grafana
env:	
  label_values(env)		
system:	
  Query: label_values(app_name)
  Regex: ^(.+?)-${env}$
filename:	
  Query: label_values({app_name="${system}-${env}"}, filename)
Log browser:
  {env="$env", app_name="${system}-${env}", filename=~"${filename}"}|~"(?i)$search"
```

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