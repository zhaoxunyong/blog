https://github.com/logfellow/logstash-logback-encoder
https://blog.csdn.net/wo541075754/article/details/109193354
https://docs.spring.io/spring-cloud-sleuth/docs/2.2.8.RELEASE/reference/html/
https://juejin.cn/post/7125081980059942920
https://juejin.cn/post/6888510459108917256
https://blog.csdn.net/z69183787/article/details/109321037
https://blog.51cto.com/guzt/5709218
https://www.qikqiak.com/k8strain2/logging/loki/logql/
https://juejin.cn/post/6878188974645444621
https://www.cnblogs.com/xiangsikai/p/11289966.html
https://blog.csdn.net/qq_37843943/article/details/120665690
https://yunlzheng.gitbook.io/prometheus-book/parti-prometheus-ji-chu/alert/prometheus-alert-rule
https://www.modb.pro/db/417835
https://www.bilibili.com/video/BV1nY4y137nv/
https://blog.csdn.net/qq_30422457/article/details/103908161
https://www.qikqiak.com/k8strain2/logging/loki/alert/
https://grafana.com/docs/loki/latest/rules/
https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
https://cloud.tencent.com/developer/article/1839408
https://yunlzheng.gitbook.io/prometheus-book/parti-prometheus-ji-chu/alert/alert-manager-use-receiver/alert-with-wechat
https://github.com/logfellow/logstash-logback-encoder#masking
https://docs.fluentbit.io/manual/pipeline/outputs/kafka
https://segmentfault.com/a/1190000021746086
https://huweicai.com/fluent-bit/


docker run -ti cr.fluentbit.io/fluent/fluent-bit:2.0 \
  -i cpu -o kafka -p brokers=192.168.102.82:9092 -p topics=kafeidou

docker run -ti cr.fluentbit.io/fluent/fluent-bit:2.0 \
  -i cpu -o stdout -f 1

#log必须是linux下的，否则监控不到文件变动
docker run  --name fluent-bit --network --restart=always host -d \
-v /mnt/d/Developer/Loki/fluent-bit/:/fluent-bit/etc \
-v /works/log/xpay:/works/log/xpay/dev \
cr.fluentbit.io/fluent/fluent-bit:2.0

1: fluent bit--->kafka--->promtail--->loki
                      --->ES
2: promtail--->loki
3: fluent bit--->loki


docker rm -vf loki
sudo rm -fr /data/loki/data/*
sudo mkdir -p /data/loki/data/
sudo chown -R 10001.10001 /data/loki/data/

#promtail
docker rm -vf promtail

#grafana
#docker rm -vf grafana


docker run -d --name loki --restart=always \
-v /etc/localtime:/etc/localtime:ro \
-v /data/loki/data:/loki/data \
-v /mnt/d/Developer/Loki:/mnt/config \
-p 3100:3100 grafana/loki:2.7.0 \
-config.file=/mnt/config/loki-config.yaml


docker run -d --name promtail --restart=always \
-v /etc/localtime:/etc/localtime:ro \
-v /mnt/d/Developer/Loki:/mnt/config \
-v /mnt/d/works/log/xpay:/works/log/xpay/dev \
grafana/promtail:2.7.0 \
-config.file=/mnt/config/promtail-config.yaml \
-client.external-labels=hostname=${HOSTNAME}


docker run -d --name grafana --restart=always \
-v /etc/localtime:/etc/localtime:ro \
-v /mnt/d/Developer/Loki/grafana.ini:/etc/grafana/grafana.ini \
-p 3000:3000 grafana/grafana-oss:9.3.1

docker run -d --name alertmanager --restart=always \
-v /mnt/d/Developer/Loki:/etc/alertmanager \
-p 9093:9093 prom/alertmanager:v0.24.0 \
--config.file=/etc/alertmanager/alertmanager-config.yaml

docker run -d --name prometheus --restart=always \
-v /mnt/d/Developer/Loki/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml \
-p 9090:9090 prom/prometheus

alarmmanager:
docker run -d --name alertmanager --restart=always \
-v /mnt/d/Developer/Loki:/etc/alertmanager \
-p 9093:9093 prom/alertmanager:v0.24.0 \

alertmanager-config.yaml:
global:
  smtp_smarthost: 'smtp.exmail.qq.com:25'
  smtp_from: 'notify@zerofinance.com'
  smtp_auth_username: 'notify@zerofinance.com'
  smtp_auth_password: 'NotAeasy8396*'
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
    - to: 'dave.zhao@zerofinance.com'
      send_resolved: false
  - name: allreceivers
    webhook_configs:
      - url: http://192.168.102.82:8080/adapter/wx
        send_resolved: false
    #webhook_configs:
    #  - url: 'http://127.0.0.1:5001/'
  - name: 'wecomreceivers'
    wechat_configs:
    - send_resolved: false
      corp_id: 'aaaaaaaaaaaaaaaaa'
      to_user: 'SZ122'
      #to_party: 'SZ122 | SZ097'
      message: '{{ template "wechat.default.message" . }}'
      agent_id: '1000008'
      api_secret: 'sssssssssss'
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']

config/WebCom.tmpl:
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


config/WebCom.tmpl:
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


kafka:
https://segmentfault.com/a/1190000021746086
https://github.com/wurstmeister/kafka-docker
docker-compose.yml
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
      KAFKA_CREATE_TOPICS: "account:3:0,configuration:3:0"   #kafka启动后初始化一个有2个partition(分区)0个副本名叫kafeidou的topic
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092
    volumes:
      - ./kafka-logs:/kafka
    depends_on:
      - zookeeper

docker exec -it kafka-kafka9094-1 sh
运行消费者,进行消息的监听
kafka-console-consumer.sh --bootstrap-server 192.168.102.82:9092 --topic account --from-beginning

docker exec -it kafka-kafka9094-1 sh
打开一个新的ssh窗口,同样进入kafka的容器中,执行下面这条命令生产消息
kafka-console-producer.sh --broker-list 192.168.102.82:9092 --topic account


docker run --name webhook-adapter -p 8080:80 -d guyongquan/webhook-adapter --adapter=/app/prometheusalert/wx.js=/wx=https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=d612b43e-6809-409d-87f3-99ea6eec4815

http://localhost:3100/ready
http://localhost:3100/metrics
http://localhost:3000/

Loki datasource: 
http://192.168.102.82:3100/

alarmmanager:
http://192.168.102.82:9093/

export LOKI_ADDR=http://192.168.102.82:3100/
./logcli series --analyze-labels '{job="kafka"}'


account-server:3:0,configuration-server:3:0,external-server:3:0,merchant-server:3:0,operation-server:3:0,transaction-server:3:0,order-server:3:0,payme
nt-server:3:0,xpay-external-gateway:3:0,xpay-gateway:3:0

X-Pay各个环境：
--------------------------------------------------------------------------
192.168.63.200：
192.168.64.200：
Mount的目录，配置文件就在这个目录下：
docker run  --name fluent-bit --restart=always --network host -d \
-v /data/fluent-bit/:/fluent-bit/etc \
-v /works/log:/works/log \
cr.fluentbit.io/fluent/fluent-bit:2.0

192.168.80.196：
docker run -d --name promtail --restart=always \
-v /etc/localtime:/etc/localtime:ro \
-v /data/promtail:/mnt/config \
grafana/promtail:2.7.0 \
-config.file=/mnt/config/promtail-config.yaml \
-client.external-labels=hostname=${HOSTNAME}

192.168.80.98:for payment info
docker run -d --name promtail --restart=always \
-v /etc/localtime:/etc/localtime:ro \
-v /data/promtail:/mnt/config \
grafana/promtail:2.7.0 \
-config.file=/mnt/config/promtail-config.yaml \
-client.external-labels=hostname=${HOSTNAME}

192.168.80.196：
docker run -d --name grafana9 --restart=always \
-v /etc/localtime:/etc/localtime:ro \
-v /data/grafana/:/var/lib/grafana \
-v /data/grafana/grafana.ini:/etc/grafana/grafana.ini \
-p 3000:3000 grafana/grafana-oss:9.3.1

迁移grafana:
https://www.jianshu.com/p/bc37e2fc15e7

kafka:
192.168.80.98


docker run -d --name alertmanager --restart=always \
-v /data/alertmanager:/etc/alertmanager \
-p 9093:9093 prom/alertmanager:v0.24.0 \
--config.file=/etc/alertmanager/alertmanager-config.yaml