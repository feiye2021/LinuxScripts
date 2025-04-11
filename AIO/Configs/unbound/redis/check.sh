#!/bin/bash

# variables
msg="$(unbound-control -c /usr/local/etc/unbound/unbound.conf stats_noreset)"
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
    local service="$1"
    local status=$(systemctl is-active "$service")
    local state=""
    if [ "$status" = "active" ]; then
        state="运行中"
    else
        state="未运行"
    fi

    local since_raw=$(systemctl show "$service" -p ActiveEnterTimestamp | cut -d'=' -f2-)
    local since_epoch=$(date -d "$since_raw" +%s 2>/dev/null)
    local now_epoch=$(date +%s)
    local since_cn="未知时间"
    local ago_cn="未知时长"

    if [ -n "$since_epoch" ]; then
        local diff=$((now_epoch - since_epoch))
        local days=$((diff / 86400))
        local hours=$(( (diff % 86400) / 3600 ))
        local minutes=$(( (diff % 3600) / 60 ))

        # 格式化启动时间
        since_cn=$(date -d "@$since_epoch" "+%Y年%-m月%-d日 %H:%M:%S")

        # 格式化已运行时长
        ago_cn=""
        [ "$days" -gt 0 ] && ago_cn="${ago_cn}${days}天"
        [ "$hours" -gt 0 ] && ago_cn="${ago_cn}${hours}小时"
        [ "$minutes" -gt 0 ] && ago_cn="${ago_cn}${minutes}分钟"
        [ -z "$ago_cn" ] && ago_cn="不到1分钟"
    fi

    echo "状态：${state}，自 ${since_cn} 起，已运行 ${ago_cn}"
}

echo ""

echo -n "Unbound 服务状态："
echo "$(translate_status unbound)"
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
echo "$(translate_status redis)"
echo "-------------------------"
echo "数据库大小：$rDbSize 条记录"
echo "键空间命中率：$rPerc%"
echo "键空间命中次数：$rHits"
echo "键空间未命中次数：$rMisses"
echo "已用内存：$(echo "$rStats" | grep 'used_memory_human' | cut -d':' -f2)"
echo "常驻内存：$(echo "$rStats" | grep 'used_memory_rss_human' | cut -d':' -f2)"
echo "内存使用峰值：$(echo "$rStats" | grep 'used_memory_peak_human' | cut -d':' -f2)"
