#!/bin/sh
# 生成apiserver私钥
openssl genrsa -out apiserver-key.pem 2048
# 生成签署请求
openssl req -new -key apiserver-key.pem -out apiserver.csr -subj "/CN=kube-apiserver" -config openssl.cnf
# 使用自建 CA 签署
openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 365 -extensions v3_req -extfile openssl.cnf

# 生成 node1 私钥
openssl genrsa -out node1-worker-key.pem 2048
# 生成 签署请求
openssl req -new -key node1-worker-key.pem -out node1-worker.csr -subj "/CN=node1" -config worker-openssl.cnf
# 使用自建 CA 签署
openssl x509 -req -in node1-worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out node1-worker.pem -days 365 -extensions v3_req -extfile worker-openssl.cnf

# 生成 node2 私钥
openssl genrsa -out node2-worker-key.pem 2048
# 生成 签署请求
openssl req -new -key node2-worker-key.pem -out node2-worker.csr -subj "/CN=node2" -config worker-openssl.cnf
# 使用自建 CA 签署
openssl x509 -req -in node2-worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out node2-worker.pem -days 365 -extensions v3_req -extfile worker-openssl.cnf

# 签署一个集群管理证书
openssl genrsa -out admin-key.pem 2048
openssl req -new -key admin-key.pem -out admin.csr -subj "/CN=kube-admin"
openssl x509 -req -in admin.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out admin.pem -days 365
