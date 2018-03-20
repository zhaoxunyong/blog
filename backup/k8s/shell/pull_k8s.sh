#!/bin/sh
imgs=$(cat k8s.list)
for img in $imgs
do
  docker pull 172.28.3.96:5000/$img
  docker tag 172.28.3.96:5000/$img $img
  docker rmi 172.28.3.96:5000/$img
done
