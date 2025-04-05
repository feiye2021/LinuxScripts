#!/bin/bash

# variables
msg="$(unbound-control -c /etc/unbound/unbound.conf stats_noreset)"
filters="total.num.queries=|total.num.cachehits|total.num.cachemiss|total.num.prefetch|total.num.recursivereplies|total.num.expired|total.recursion"

uStats="$(echo "$msg" | grep -E "$filters")"
uPerc="$(echo "$(echo "$uStats" | grep 'total.num.cachehits=' | cut -c 21-)/$(echo "$uStats" | grep total.num.queries= | cut -c 19-)" | bc -l | awk '{printf "%d", $1*100}')"

rStats="$(redis-cli info memory | grep 'used.*human')"
rDbSize="$(redis-cli dbsize)"
rInfo="$(redis-cli info stats)"
rHits="$(echo "$rInfo" | grep 'keyspace_hits' | cut -d':' -f2 | tr -d '\r')"
rMisses="$(echo "$rInfo" | grep 'keyspace_misses' | cut -d':' -f2 | tr -d '\r')"
if [ "$rHits" -eq 0 ] && [ "$rMisses" -eq 0 ]; then
    rPerc="0"
else
    rPerc="$(echo "scale=2; $rHits/($rHits + $rMisses)*100" | bc | awk '{printf "%d", $1}')"
fi

# 函数：将服务状态转换为中文
translate_status() {
    local status_line="$1"
    local state=$(echo "$status_line" | grep -o "active (running)" || echo "inactive")
    local since=$(echo "$status_line" | grep -o "since [A-Za-z]\{3\} [0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}" | sed 's/since //')
    local ago=$(echo "$status_line" | grep -o ";.*ago" | sed 's/; //;s/ ago//')

    if [ "$state" = "active (running)" ]; then
        state="运行中"
    else
        state="未运行"
    fi

    # 翻译日期时间
    local date_time="$since"
    if [ -n "$date_time" ]; then
        local weekday=$(echo "$date_time" | cut -d' ' -f1)  
        local date=$(echo "$date_time" | cut -d' ' -f2)    
        local time=$(echo "$date_time" | cut -d' ' -f3)   
        local year=$(echo "$date" | cut -d'-' -f1)
        local month=$(echo "$date" | cut -d'-' -f2 | sed 's/^0//')  
        local day=$(echo "$date" | cut -d'-' -f3 | sed 's/^0//')    
        local since_cn="${year}年${month}月${day}日 ${time}"
    else
        local since_cn="未知时间"
    fi

    local ago_cn=""
    if [ -n "$ago" ]; then
        local hours=$(echo "$ago" | grep -o "[0-9]\+h" | sed 's/h//')
        local minutes=$(echo "$ago" | grep -o "[0-9]\+m" | sed 's/m//')
        local seconds=$(echo "$ago" | grep -o "[0-9]\+s" | sed 's/s//')
        [ -n "$hours" ] && ago_cn="${ago_cn}${hours}小时"
        [ -n "$minutes" ] && ago_cn="${ago_cn}${minutes}分钟"
        [ -n "$seconds" ] && ago_cn="${ago_cn}${seconds}秒"
        ago_cn=$(echo "$ago_cn" | sed 's/^\s*//')  
    else
        ago_cn="未知时长"
    fi

    echo "状态：${state}，自 ${since_cn} 起，已运行 ${ago_cn}"
}

# messages
echo ""

echo -n "Unbound 服务状态："
uStatus=$(systemctl status unbound | grep "Active:" | head -n 1 | sed 's/Active://')
echo "$(translate_status "$uStatus")"
echo "-------------------------"
echo "缓存命中率：$uPerc%"
echo "查询总数：$(echo "$uStats" | grep 'total.num.queries=' | cut -c 19-)"
echo "缓存命中次数：$(echo "$uStats" | grep 'total.num.cachehits=' | cut -c 21-)"
echo "缓存未命中次数：$(echo "$uStats" | grep 'total.num.cachemiss=' | cut -c 21-)"
echo "预取次数：$(echo "$uStats" | grep 'total.num.prefetch=' | cut -c 20-)"
echo "过期条目数：$(echo "$uStats" | grep 'total.num.expired=' | cut -c 20-)"
echo "递归回复次数：$(echo "$uStats" | grep 'total.num.recursivereplies=' | cut -c 28-)"
echo "平均递归时间：$(echo "$uStats" | grep 'total.recursion.time.avg=' | cut -c 26-) 秒"
echo "中位递归时间：$(echo "$uStats" | grep 'total.recursion.time.median=' | cut -c 29-) 秒"
echo ""

echo -n "Redis 服务状态："
rStatus=$(systemctl status redis | grep "Active:" | head -n 1 | sed 's/Active://')
echo "$(translate_status "$rStatus")"
echo "-------------------------"
echo "数据库大小：$rDbSize 条记录"
echo "键空间命中率：$rPerc%"
echo "键空间命中次数：$rHits"
echo "键空间未命中次数：$rMisses"
echo "已用内存：$(echo "$rStats" | grep 'used_memory_human' | cut -d':' -f2)"
echo "常驻内存：$(echo "$rStats" | grep 'used_memory_rss_human' | cut -d':' -f2)"
echo "内存使用峰值：$(echo "$rStats" | grep 'used_memory_peak_human' | cut -d':' -f2)"