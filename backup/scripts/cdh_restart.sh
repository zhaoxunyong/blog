#!/bin/bash

ssh dev@192.168.80.94 "docker restart master1"
ssh dev@192.168.80.94 "docker restart utility"

ssh dev@192.168.80.97 "docker restart master2"
ssh dev@192.168.80.97 "docker restart gateway1" 

ssh dev@192.168.80.99 "docker restart master3" 
ssh dev@192.168.80.99 "docker restart kylin" 

ssh dev@192.168.80.201 "docker restart dn1" 
ssh dev@192.168.80.201 "docker restart dn2" 
ssh dev@192.168.80.201 "docker restart dn3" 
ssh dev@192.168.80.98 "docker restart dn4"

ssh kylin@kylin "kylin.sh stop"
ssh kylin@kylin "kylin.sh start" 
