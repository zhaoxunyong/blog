---
title: Linux Shell Script
date: 2022-08-03 10:31:44
categories: ["Linux"]
tags: ["Linux"]
toc: true
---

记录Linux脚本的常用技巧。

<!-- more -->

```bash
#输出多行到屏幕：
cat << USAGE >&2
Usage:
    $WAITFORIT_cmdname host:port [-s] [-t timeout] [-- command args]
    -h HOST | --host=HOST       Host or IP under test
    -p PORT | --port=PORT       TCP port under test
                                Alternatively, you specify the host and port as host:port
    -s | --strict               Only execute subcommand if the test succeeds
    -q | --quiet                Don't output any status messages
    -t TIMEOUT | --timeout=TIMEOUT
                                Timeout in seconds, zero for no timeout
    -- COMMAND ARGS             Execute command with args after the test finishes
USAGE

cat << EOF >&2
This is a test1
This is a test1
EOF

#输出多行到文件：
#追加：
cat >> /tmp/tmp.log << EOF
net.ipv4.tcp_syncookies = 1
EOF
#不追加：
cat > /tmp/tmp.log << EOF
net.ipv4.tcp_syncookies = 1
EOF

```
