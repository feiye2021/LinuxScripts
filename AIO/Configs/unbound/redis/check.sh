#!/bin/bash
unbound-control stats_noreset  | egrep 'total.num.cachehits|total.num.cachemiss' >> /root/cache.txt
redis-cli INFO stats | egrep 'keyspace_hits|keyspace_misses' >> /root/cache.txt
dos2unix /root/cache.txt
unbound_hits=`cat /root/cache.txt | grep 'total.num.cachehits' | cut -d '=' -f 2`
unbound_miss=`cat /root/cache.txt | grep 'total.num.cachemiss' | cut -d '=' -f 2`
redis_hits=`cat /root/cache.txt | grep 'keyspace_hits' | cut -d ':' -f 2`
redis_miss=`cat /root/cache.txt | grep 'keyspace_misses' | cut -d ':' -f 2`
unbound_result=$(echo "scale=2; ($unbound_hits / ($unbound_hits + $unbound_miss)) * 100" | bc)
redis_result=$(echo "scale=2; ($redis_hits / ($redis_hits + $redis_miss)) * 100" | bc)
echo "unbound命中率：$unbound_result%"
echo "redis命中率：$redis_result%"
echo -e "\n\n\n"
cat /root/cache.txt
rm /root/cache.txt
