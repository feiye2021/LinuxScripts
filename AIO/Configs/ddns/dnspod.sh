#!/bin/bash
logfile="/mnt/ddns/log.txt"

ipaddr=$(curl -s 4.ipw.cn)

recordip=$(dig +short DDNS_ALL_DOMAIN)

if [ "$ipaddr" != "$recordip" ]; then
    echo -e "\n$(date '+%Y-%m-%d %H:%M:%S')" >> $logfile
    echo -e "\n[DDNS_ALL_DOMAIN] 公网IP为$ipaddr" >> $logfile
    echo "[DDNS_ALL_DOMAIN] DNS记录的IP为$recordip" >> $logfile
    echo "[DDNS_ALL_DOMAIN] IP需要更新, 正在更新到$ipaddr" >> $logfile
    
    response=$(curl -s -X POST https://dnsapi.cn/Record.Ddns -d "login_token=DDNS_token&format=json&domain=DDNS_domain&sub_domain=DDNS_subdomain&record_id=DDNS_recordid&record_line_id=0&value=$ipaddr")

    if [[ $response == *"\"code\":\"1\""* ]]; then
        echo "[DDNS_ALL_DOMAIN] IP更新成功: $ipaddr" >> $logfile
    else
        echo "[DDNS_ALL_DOMAIN] IP更新失败: $response" >> $logfile
    fi
#else
#    echo "[DDNS_ALL_DOMAIN] $(date '+%Y-%m-%d %H:%M:%S') IP未变化，无需更新" >> $logfile
fi