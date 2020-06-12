#!/bin/bash

ssh dev@192.168.80.94 "docker stop master1"
ssh dev@192.168.80.94 "docker stop utility"

ssh dev@192.168.80.97 "docker stop master2"
ssh dev@192.168.80.97 "docker stop gateway1" 

ssh dev@192.168.80.99 "docker stop master3" 
ssh dev@192.168.80.99 "docker stop kylin" 

ssh dev@192.168.80.201 "docker stop dn1" 
ssh dev@192.168.80.201 "docker stop dn2" 
ssh dev@192.168.80.201 "docker stop dn3" 
ssh dev@192.168.80.98 "docker stop dn4"

ssh kylin@kylin "kylin.sh stop" 
