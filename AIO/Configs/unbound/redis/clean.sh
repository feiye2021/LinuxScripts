#!/bin/bash
clear
rm -rf /mnt/main_install.sh
# 检查是否为root用户执行
[[ $EUID -ne 0 ]] && echo -e "错误：必须使用root用户运行此脚本！\n" && exit 1
#颜色
red(){
    echo -e "\e[31m$1\e[0m"
}
green(){
    echo -e "\n\e[1m\e[37m\e[42m$1\e[0m\n"
}
yellow(){
     echo -e "\e[1m\e[33m$1\e[0m\n"
}   
white(){
    echo -e "$1"
}


white "开始清空 Unbound 缓存..."
if unbound-control flush_infra all | grep -q "ok"; then
    green "Unbound 缓存清空成功"
else
    red "Unbound 缓存清空失败"
    exit 1
fi

white "开始执行 redis-cli FLUSHALL..."
if redis-cli FLUSHALL | grep -q "OK"; then
    green " Redis FLUSHALL 成功"
else
    red " Redis FLUSHALL 失败"
    exit 1
fi

white "检测 redis 当前数据库键数量..."
KEYS_COUNT=$(redis-cli DBSIZE)
yellow "当前数据库键数量: $KEYS_COUNT"

if [[ "$KEYS_COUNT" -eq 0 ]]; then
    green "Redis 当前数据库已清空"
else
    red "Redis 当前数据库未清空，剩余键数量: $KEYS_COUNT"
    exit 1
fi

white "重启 Unbound 服务..."
if systemctl restart unbound; then
    green "Unbound 服务已重启"
else
    red "无法重启 Unbound 服务"
    exit 1
fi

# 检测 Redis 运行的服务名
if systemctl is-active --quiet redis; then
    redis_service_name="redis"
elif systemctl is-active --quiet redis-server; then
    redis_service_name="redis-server"
else
    redis_service_name="redis-server"
fi

white "重启 Redis 服务..."
if systemctl restart $redis_service_name; then
    green "Redis 服务已重启"
else
    red "无法重启 Redis 服务"
    exit 1
fi

yellow "所有操作已完成，缓存清理并服务重启成功"
