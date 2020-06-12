#!/bin/bash

ssh dev@192.168.80.94 "docker start master1"
ssh dev@192.168.80.94 "docker start utility"

ssh dev@192.168.80.97 "docker start master2"
ssh dev@192.168.80.97 "docker start gateway1" 

ssh dev@192.168.80.99 "docker start master3" 
ssh dev@192.168.80.99 "docker start kylin" 

ssh dev@192.168.80.201 "docker start dn1" 
ssh dev@192.168.80.201 "docker start dn2" 
ssh dev@192.168.80.201 "docker start dn3" 
ssh dev@192.168.80.98 "docker start dn4"

ssh kylin@kylin "kylin.sh start" 
