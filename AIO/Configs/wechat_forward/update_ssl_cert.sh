#!/bin/bash

export COLUMNS=200

# 日志路径
log_file="/mnt/nginx-ssl.txt"
current_date=$(date +"%Y-%m-%d")

# 函数：计算证书到期剩余天数
calculate_days_left() {
    local cert_date=$1
    local expiry_days_left=$(( ($(date -d "$cert_date" +%s) - $(date -d "$current_date" +%s)) / 86400 ))
    echo $expiry_days_left
}

# 函数：更新单个证书
renew_certificate() {
    local domain=$1
    local max_retries=1
    local retry_count=0
    
    echo "[$current_date] 开始更新域名 $domain 的证书..." >> "$log_file"
    
    # 停止nginx服务
    systemctl stop nginx.service
    
    while [ $retry_count -le $max_retries ]; do
        # 尝试更新证书
        ~/.acme.sh/acme.sh --renew -d "$domain" --force
        
        # 检查更新后的证书到期时间
        local new_cert_expiry=$(~/.acme.sh/acme.sh --list | grep "$domain" | awk '{print $6}' | cut -d 'T' -f 1)
        local new_days_left=$(calculate_days_left "$new_cert_expiry")
        
        if [ $new_days_left -gt 5 ]; then
            echo "[$current_date] 域名 $domain 证书更新成功，新到期日期为：$new_cert_expiry" >> "$log_file"
            systemctl restart nginx.service
            return 0
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -le $max_retries ]; then
                echo "[$current_date] 域名 $domain 更新尝试失败，正在重试...（剩余重试次数：$((max_retries - retry_count + 1))）" >> "$log_file"
            fi
        fi
    done
    
    # 所有重试都失败
    echo "[$current_date] 域名 $domain 更新多次失败，请手动检查。" >> "$log_file"
    systemctl restart nginx.service
    return 1
}

# 主逻辑
echo "[$current_date] 开始检查所有证书..." >> "$log_file"

# 获取所有证书信息，跳过表头
cert_info=$(~/.acme.sh/acme.sh --list | tail -n +2)

# 检查是否有证书
if [ -z "$cert_info" ]; then
    echo "[$current_date] 未找到任何证书。" >> "$log_file"
    exit 0
fi

# 标记是否需要重启nginx
nginx_restarted=false
certs_to_renew=()

# 遍历所有证书
while IFS= read -r line; do
    # 提取域名和到期时间
    domain=$(echo "$line" | awk '{print $1}')
    cert_expiry_date=$(echo "$line" | awk '{print $6}' | cut -d 'T' -f 1)
    
    # 跳过空行或无效行
    if [ -z "$domain" ] || [ -z "$cert_expiry_date" ]; then
        continue
    fi
    
    # 计算剩余天数
    expiry_days_left=$(calculate_days_left "$cert_expiry_date")
    
    echo "[$current_date] 检查域名：$domain，到期日期：$cert_expiry_date，剩余天数：$expiry_days_left" >> "$log_file"
    
    # 检查是否需要更新
    if [ $expiry_days_left -le 5 ]; then
        echo "[$current_date] 域名 $domain 证书将在 $expiry_days_left 天内到期，加入更新队列。" >> "$log_file"
        certs_to_renew+=("$domain")
    else
        echo "[$current_date] 域名 $domain 证书未在 5 天内到期，无需更新。" >> "$log_file"
    fi
done <<< "$cert_info"

# 执行证书更新
if [ ${#certs_to_renew[@]} -gt 0 ]; then
    echo "[$current_date] 发现 ${#certs_to_renew[@]} 个证书需要更新：${certs_to_renew[*]}" >> "$log_file"
    
    for domain in "${certs_to_renew[@]}"; do
        renew_certificate "$domain"
    done
else
    echo "[$current_date] 所有证书都在有效期内，无需更新。" >> "$log_file"
fi

echo "[$current_date] 证书检查和更新任务完成。" >> "$log_file"
exit 0