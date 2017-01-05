#!/bin/sh
kubectl create -f frontend-service.yaml 
kubectl create -f redis-slave-service.yaml 
kubectl create -f redis-master-service.yaml 
kubectl create -f legacy/frontend-controller.yaml 
kubectl create -f legacy/redis-slave-controller.yaml 
kubectl create -f legacy/redis-master-controller.yaml
