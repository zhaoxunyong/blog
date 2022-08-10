---
title: Linux Shell Script
date: 2022-08-03 10:31:44
categories: ["Linux"]
tags: ["Linux"]
toc: true
---

记录Linux脚本的常用技巧。

<!-- more -->

## cat

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

#同时输出日志与文件
./ping_check.sh |& tee -a ping_full.log

```

### SED

https://coolshell.cn/articles/9104.html

### 插入换行

```bash
sed $'s;AAA;\\\nAAA;g' my.txt
```

### 多个匹配

```bash
sed '1,3s/my/your/g; 3,$s/This/That/g' my.txt

sed -e '1,3s/my/your/g' -e '3,$s/This/That/g' my.txt
```

我们可以使用&来当做被匹配的变量，然后可以在基本左右加点东西：

```bash
cat my.txt
This is my cat, my cat's name is betty
This is my dog, my dog's name is frank
This is my fish, my fish's name is george
This is my goat, my goat's name is adam

$ sed 's/my/[&]/g' my.txt
This is [my] cat, [my] cat's name is betty
This is [my] dog, [my] dog's name is frank
This is [my] fish, [my] fish's name is george
This is [my] goat, [my] goat's name is adam
```

### 圆括号匹配

```bash
cat my.txt
This is my cat, my cat's name is betty
This is my dog, my dog's name is frank
This is my fish, my fish's name is george
This is my goat, my goat's name is adam

sed 's/This is my \([^,&]*\),.*is \(.*\)/\1:\2/g' my.txt
cat:betty
dog:frank
fish:george
goat:adam

正则为：This is my ([^,]*),.*is (.*)
匹配为：This is my (cat),……….is (betty)

然后：\1就是cat，\2就是betty
```

也就是：
&匹配所有的内容；
\1匹配到的第一个 \\ ( \\)中的内容；
\2匹配到的第二个\\ ( \\)内容。

## 参考

- https://www.yiibai.com/sed/sed_regular_expressions.html
- https://coolshell.cn/articles/9104.html