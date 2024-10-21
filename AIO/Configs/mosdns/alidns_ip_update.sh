#!/bin/bash

if [ ! -f /opt/alidns_ip_dateip.txt ]; then
    touch /opt/alidns_ip_date/ip.txt
fi
if [ ! -f /opt/alidns_ip_date/log/log.txt ]; then
    touch /opt/alidns_ip_date/log/log.txt
fi

current_ip=$(curl -s 4.ipw.cn)

stored_ip=$(cat /opt/alidns_ip_date/ip.txt)

if [ "$current_ip" != "$stored_ip" ]; then
    curl https://www.baidu.com
    echo "$current_ip" > /opt/alidns_ip_date/ip.txt
    echo "$(date '+%Y-%m-%d %H:%M:%S') IP有变化，当前IP为$current_ip，已更新" >> /opt/alidns_ip_date/log/log.txt
else
    echo "IP无变动，无需配置"
    echo "$(date '+%Y-%m-%d %H:%M:%S') IP未变化，无需更新" >> /opt/alidns_ip_date/log/log.txt
fi
