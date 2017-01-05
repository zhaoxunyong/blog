#!/bin/sh
imgs=$(docker images|awk '{print $1":"$2}')
for img in $imgs
do
  docker tag $img 172.28.3.96:5000/$img
  docker push 172.28.3.96:5000/$img
  docker rmi 172.28.3.96:5000/$img
done
