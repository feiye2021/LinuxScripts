#!/bin/bash

# ========= 颜色定义 =========
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
RED="\e[1;31m"
GRAY="\e[1;90m"
RESET="\e[0m"

# ========= 命中率加颜色输出 =========
color_rate() {
    local val="$1"
    if [[ "$val" == "暂无缓存查询记录" ]]; then
        echo -e "${GRAY}${val}${RESET}"
    else
        local num=$(echo "$val" | tr -d '%')
        if [ "$num" -ge 70 ]; then
            echo -e "${GREEN}${val}${RESET}"
        elif [ "$num" -ge 50 ]; then
            echo -e "${YELLOW}${val}${RESET}"
        else
            echo -e "${RED}${val}${RESET}"
        fi
    fi
}

# ========= 服务状态输出 =========
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

        since_cn=$(date -d "@$since_epoch" "+%Y年%-m月%-d日 %H:%M:%S")
        ago_cn=""
        [ "$days" -gt 0 ] && ago_cn="${ago_cn}${days}天"
        [ "$hours" -gt 0 ] && ago_cn="${ago_cn}${hours}小时"
        [ "$minutes" -gt 0 ] && ago_cn="${ago_cn}${minutes}分钟"
        [ -z "$ago_cn" ] && ago_cn="不到1分钟"
    fi

    echo "状态：${state}，自 ${since_cn} 起，已运行 ${ago_cn}"
}

echo ""

# ========= Unbound =========
msg="$(unbound-control -c /usr/local/etc/unbound/unbound.conf stats_noreset)"
filters="total.num.queries=|total.num.cachehits|total.num.cachemiss|total.num.prefetch|total.num.recursivereplies|total.num.expired|total.recursion"

uStats="$(echo "$msg" | grep -E "$filters")"
uHits=$(echo "$uStats" | grep 'total.num.cachehits=' | cut -c 21-)
uTotal=$(echo "$uStats" | grep total.num.queries= | cut -c 19-)
if [ "$uTotal" -eq 0 ]; then
    uPerc="暂无缓存查询记录"
else
    uPerc="$(echo "$uHits/$uTotal*100" | bc -l | awk '{printf "%d", $1}')%"
fi

echo -n "Unbound 服务状态："
echo "$(translate_status unbound)"
echo "—— 缓存数据 ——"
printf "缓存命中率         : %s\n" "$(color_rate "$uPerc")"
printf "查询总数           : %s\n" "$uTotal"
printf "缓存命中次数       : %s\n" "$uHits"
printf "缓存未命中次数     : %s\n" "$(echo "$uStats" | grep 'total.num.cachemiss=' | cut -c 21-)"
printf "预取次数           : %s\n" "$(echo "$uStats" | grep 'total.num.prefetch=' | cut -c 20-)"
printf "过期条目数         : %s\n" "$(echo "$uStats" | grep 'total.num.expired=' | cut -c 20-)"
printf "递归回复次数       : %s\n" "$(echo "$uStats" | grep 'total.num.recursivereplies=' | cut -c 28-)"
printf "平均递归时间       : %s 秒\n" "$(echo "$uStats" | grep 'total.recursion.time.avg=' | cut -c 26-)"
printf "中位递归时间       : %s 秒\n" "$(echo "$uStats" | grep 'total.recursion.time.median=' | cut -c 29-)"
echo ""

# ========= Redis =========
rStats="$(redis-cli info memory | grep 'used.*human')"
rDbSize="$(redis-cli dbsize)"
rInfo="$(redis-cli info stats)"
rHits="$(echo "$rInfo" | grep 'keyspace_hits' | cut -d':' -f2 | tr -d '\r')"
rMisses="$(echo "$rInfo" | grep 'keyspace_misses' | cut -d':' -f2 | tr -d '\r')"
if [ "$rHits" -eq 0 ] && [ "$rMisses" -eq 0 ]; then
    rPerc="暂无缓存查询记录"
else
    rPerc="$(echo "$rHits/($rHits + $rMisses)*100" | bc -l | awk '{printf "%d", $1}')%"
fi

echo -n "Redis 服务状态："
echo "$(translate_status redis)"
echo "—— 缓存数据 ——"
printf "键空间命中率       : %s\n" "$(color_rate "$rPerc")"
printf "数据库大小         : %s 条记录\n" "$rDbSize"
printf "键空间命中次数     : %s\n" "$rHits"
printf "键空间未命中次数   : %s\n" "$rMisses"
printf "已用内存           : %s\n" "$(echo "$rStats" | grep 'used_memory_human' | cut -d':' -f2)"
printf "常驻内存           : %s\n" "$(echo "$rStats" | grep 'used_memory_rss_human' | cut -d':' -f2)"
printf "内存使用峰值       : %s\n" "$(echo "$rStats" | grep 'used_memory_peak_human' | cut -d':' -f2)"
echo ""

# ========= Mosdns =========
output=$(curl -s http://10.10.10.3:8338/metrics)
mHit=$(echo "$output" | grep 'mosdns_cache_hit_total{tag="lazy_cache"}' | awk '{print $2}')
mLazy=$(echo "$output" | grep 'mosdns_cache_lazy_hit_total{tag="lazy_cache"}' | awk '{print $2}')
mQuery=$(echo "$output" | grep 'mosdns_cache_query_total{tag="lazy_cache"}' | awk '{print $2}')
mMiss=$(echo "$mQuery - $mHit - $mLazy" | bc)
mSize=$(echo "$output" | grep 'mosdns_cache_size_current{tag="lazy_cache"}' | awk '{print $2}')
mErr=$(echo "$output" | grep 'mosdns_metrics_collector_err_total{name="metrics"}' | awk '{print $2}')
mTotal=$(echo "$output" | grep 'mosdns_metrics_collector_query_total{name="metrics"}' | awk '{print $2}')

if [ "$mQuery" -eq 0 ]; then
    mRate="暂无缓存查询记录"
else
    mRate="$(echo "scale=2; 100*($mHit+$mLazy)/$mQuery" | bc | awk '{printf "%d", $1}')%"
fi

echo -n "Mosdns 服务状态："
echo "$(translate_status mosdns)"
echo "—— 缓存数据 ——"
printf "命中率             : %s\n" "$(color_rate "$mRate")"
printf "缓存查询总数       : %s\n" "$mQuery"
printf "命中次数           : %s\n" "$mHit"
printf "懒命中次数         : %s\n" "$mLazy"
printf "未命中次数         : %s\n" "$mMiss"
printf "当前缓存项目数量   : %s\n" "$mSize"
echo ""
echo "—— Metrics 状态 ——"
printf "metrics 查询总数   : %s\n" "$mTotal"
printf "metrics 错误次数   : %s\n" "$mErr"
