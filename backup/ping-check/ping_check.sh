#!/bin/bash

#The max time when ping a certain ip
maxTime=90
#Each of max count when ping
pingMaxCount=3

#Backup logs file
# [[ ! -d bak ]] && mkdir bak
# if [[ -f $logfile ]]; then
#     mv $logfile bak/ping_record_`date '+%Y%m%d%H%M%S'`.txt
# fi
logfile=ping_fail_`date '+%Y%m%d%H%M%S'`.log

function pingIp() {
    ip=$1
    now=`date '+%Y-%m-%d %H:%M:%S'`
    echo "[$now] Ready to ping $ip for ${pingMaxCount} times..."
    times=`ping $ip -n ${pingMaxCount}|grep "TTL="|awk '{print $5}'|awk -F '=' '{print $2}'|sed 's;ms;;g'`
    isOk="true"
    now=`date '+%Y-%m-%d %H:%M:%S'`
    totalTimes=0
    countTimes=0
    for time in $times
    do
        totalTimes=$((totalTimes+$time))
        countTimes=$((countTimes+1))
        echo "[$now] Ping Time: ${time}ms."
    done

    if [[ $countTimes == ${pingMaxCount} ]]; then
        averageTime=$(($totalTimes/$pingMaxCount))
        echo "[$now] Average Of $pingMaxCount Times: ${averageTime}ms."
        value=$(($averageTime - $maxTime))
        if [[ $value > 0 ]]; then
          echo "[$now] [Warn] [$ip] Your network's having some troubles when ping $ip. Average Times is: ${averageTime}ms." |tee -a $logfile
        fi
    else
        echo "[$now] [Error] [$ip] Your network's having timeouts when ping $ip." |tee -a $logfile
    fi
}

count=1
while true
do
    now=`date '+%Y-%m-%d %H:%M:%S'`
    echo "------------------$count times at ${now}---------------------------"
    pingIp 159.138.103.38 $count
    pingIp 159.138.100.135 $count
    pingIp 159.138.107.68 $count
    # pingIp 223.5.5.5 $count
    sleep 1
    count=$((count+1))
done
