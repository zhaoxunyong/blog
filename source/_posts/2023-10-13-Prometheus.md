---
title: Prometheus
date: 2023-10-13 11:38:15
categories: ["Linux", "Prometheus"]
tags: ["Linux", "Prometheus"]
toc: true
---


<!-- more -->

## Installation

```bash
mkdir -p /works/config/prometheus
chown -R 10001:10001 /data/prometheus/prometheus-data/
cp -a prometheus.yml prometheus.rules.yml /works/config/prometheus/

docker run -d --name prometheus \
    --user 10001 -p 9090:9090 \
    -v /works/config/prometheus:/etc/prometheus \
    -v /data/prometheus/prometheus-data:/prometheus \
    prom/prometheus:v2.47.1
```