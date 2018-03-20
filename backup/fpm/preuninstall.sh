#!/bin/sh
if [ $1 -eq 0 ] ; then
        # Package removal, not upgrade
        systemctl --no-reload disable etcd.service  || :
        systemctl stop etcd.service  || :
fi
