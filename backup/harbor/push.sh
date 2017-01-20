#!/bin/sh
imgs=$(docker images|awk '{print $1":"$2}')
for img in $imgs
do
  docker tag $img registry.gcalls.cn/harbor/$img
  docker push registry.gcalls.cn/harbor/$img
  docker rmi registry.gcalls.cn/harbor/$img
done
