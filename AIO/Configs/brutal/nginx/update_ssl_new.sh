#!/bin/bash

export COLUMNS=200

# 日志路径
log_file="/mnt/nginx-ssl.txt"
temp_log_file="/tmp/nginx-ssl-temp.txt"
current_date=$(date +"%Y-%m-%d")

write_log() {
    local message=$1
    echo "$message" >> "$temp_log_file"
}

calculate_days_left() {
    local cert_date=$1
    local expiry_days_left=$(( ($(date -d "$cert_date" +%s) - $(date -d "$current_date" +%s)) / 86400 ))
    echo $expiry_days_left
}

renew_certificate() {
    local domain=$1
    local max_retries=1
    local retry_count=0
    
    write_log "[$current_date] 开始更新域名 $domain 的证书..."
    
    systemctl stop nginx.service
    
    while [ $retry_count -le $max_retries ]; do
        ~/.acme.sh/acme.sh --renew -d "$domain" --force
        
        local new_cert_expiry=$(~/.acme.sh/acme.sh --list | grep "$domain" | awk '{print $6}' | cut -d 'T' -f 1)
        local new_days_left=$(calculate_days_left "$new_cert_expiry")
        
        if [ $new_days_left -gt 5 ]; then
            write_log "[$current_date] 域名 $domain 证书更新成功，新到期日期为：$new_cert_expiry"
            systemctl restart nginx.service
            return 0
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -le $max_retries ]; then
                write_log "[$current_date] 域名 $domain 更新尝试失败，正在重试...（剩余重试次数：$((max_retries - retry_count + 1))）"
            fi
        fi
    done
    
    write_log "[$current_date] 域名 $domain 更新多次失败，请手动检查。"
    systemctl restart nginx.service
    return 1
}

> "$temp_log_file"

write_log "[$current_date] 开始检查所有证书..."

cert_info=$(~/.acme.sh/acme.sh --list | tail -n +2)

if [ -z "$cert_info" ]; then
    write_log "[$current_date] 未找到任何证书。"
    if [ -f "$log_file" ]; then
        cat "$temp_log_file" "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file"
    else
        mv "$temp_log_file" "$log_file"
    fi
    exit 0
fi

nginx_restarted=false
certs_to_renew=()

while IFS= read -r line; do
    domain=$(echo "$line" | awk '{print $1}')
    cert_expiry_date=$(echo "$line" | awk '{print $6}' | cut -d 'T' -f 1)
    
    if [ -z "$domain" ] || [ -z "$cert_expiry_date" ]; then
        continue
    fi
    
    expiry_days_left=$(calculate_days_left "$cert_expiry_date")
    
    write_log "[$current_date] 检查域名：$domain，到期日期：$cert_expiry_date，剩余天数：$expiry_days_left"
    
    if [ $expiry_days_left -le 5 ]; then
        write_log "[$current_date] 域名 $domain 证书将在 $expiry_days_left 天内到期，加入更新队列。"
        certs_to_renew+=("$domain")
    else
        write_log "[$current_date] 域名 $domain 证书未在 5 天内到期，无需更新。"
    fi
done <<< "$cert_info"

if [ ${#certs_to_renew[@]} -gt 0 ]; then
    write_log "[$current_date] 发现 ${#certs_to_renew[@]} 个证书需要更新：${certs_to_renew[*]}"
    
    for domain in "${certs_to_renew[@]}"; do
        renew_certificate "$domain"
    done
else
    write_log "[$current_date] 所有证书都在有效期内，无需更新。"
fi

write_log "[$current_date] 证书检查和更新任务完成。"

if [ -f "$log_file" ]; then
    cat "$temp_log_file" "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file"
else
    mv "$temp_log_file" "$log_file"
fi

rm -f "$temp_log_file"

exit 0