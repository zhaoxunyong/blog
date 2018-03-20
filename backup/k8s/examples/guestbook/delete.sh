#!/bin/sh
kubectl delete -f frontend-service.yaml 
kubectl delete -f redis-slave-service.yaml 
kubectl delete -f redis-master-service.yaml 
kubectl delete -f legacy/frontend-controller.yaml 
kubectl delete -f legacy/redis-slave-controller.yaml 
kubectl delete -f legacy/redis-master-controller.yaml
