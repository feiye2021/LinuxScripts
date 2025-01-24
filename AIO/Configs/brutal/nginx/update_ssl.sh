#!/bin/bash
# 注意替换nginx_ssl_domain为节点SSL域名

export COLUMNS=200

# 获取证书到期时间
cert_expiry_date=$(~/.acme.sh/acme.sh --list | tail -n 1 | awk '{print $6}' | cut -d 'T' -f 1)
current_date=$(date +"%Y-%m-%d")
expiry_days_left=$(( ($(date -d "$cert_expiry_date" +%s) - $(date -d "$current_date" +%s)) / 86400 ))

# 日志路径
log_file="/mnt/nginx-ssl.txt"

# 更新证书
if [ $expiry_days_left -le 5 ]; then
    echo "[$current_date] 证书将在 $expiry_days_left 天内到期，开始更新证书..." >> "$log_file"
    systemctl stop nginx.service
    ~/.acme.sh/acme.sh --renew -d nginx_ssl_domain --force
    cert_expiry_date=$(~/.acme.sh/acme.sh --list | tail -n 1 | awk '{print $6}' | cut -d 'T' -f 1)
    expiry_days_left=$(( ($(date -d "$cert_expiry_date" +%s) - $(date -d "$current_date" +%s)) / 86400 ))

    retries=1

    # 校验更新
    while [ $expiry_days_left -le 5 ] && [ $retries -gt 0 ]; do
        echo "[$current_date] 更新尝试失败，正在重试...（剩余重试次数：$retries）" >> "$log_file"
        ~/.acme.sh/acme.sh --renew -d nginx_ssl_domain --force
        cert_expiry_date=$(~/.acme.sh/acme.sh --list | tail -n 1 | awk '{print $6}' | cut -d 'T' -f 1)
        expiry_days_left=$(( ($(date -d "$cert_expiry_date" +%s) - $(date -d "$current_date" +%s)) / 86400 ))
        retries=$((retries - 1))
    done

    systemctl restart nginx.service

# 输出日志
    if [ $expiry_days_left -le 5 ]; then
        echo "[$current_date] 更新多次失败，请手动检查。" >> "$log_file"
    else
        echo "[$current_date] 证书更新成功，新到期日期为：$cert_expiry_date" >> "$log_file"
    fi
else
    echo "[$current_date] 证书未在 5 天内到期，当前到期日期为：$cert_expiry_date" >> "$log_file"
fi

exit 0