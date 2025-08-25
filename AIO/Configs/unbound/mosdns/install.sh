#!/bin/bash
#判断是否有mosdns_install目录，如没有就创建
if [ ! -d "/opt/mosdns_install" ]; then
        mkdir -p /opt/mosdns_install
fi
curl -s https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt > /opt/mosdns_install/geosite_cn.txt
curl -s https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/proxy-list.txt > /opt/mosdns_install/geosite_no_cn.txt
curl -s https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt > /opt/mosdns_install/gfw.txt
# curl -s https://file.bairuo.net/iplist/output/Aggregated_ChinaAllNetwork_IPv4.txt > /opt/mosdns_install/ChinaAllNetwork_IPv4.txt
# curl -s https://file.bairuo.net/iplist/output/Aggregated_ChinaAllNetwork_IPv6.txt > /opt/mosdns_install/ChinaAllNetwork_IPv6.txt
# curl -s https://file.bairuo.net/iplist/output/Aggregated_ChinaEducation_IPv4.txt > /opt/mosdns_install/ChinaEducation_IPv4.txt
# curl -s https://file.bairuo.net/iplist/output/Aggregated_ChinaEducation_IPv6.txt > /opt/mosdns_install/ChinaEducation_IPv6.txt
# curl -s https://file.bairuo.net/iplist/output/Aggregated_ChinaMobile_IPv4.txt > /opt/mosdns_install/ChinaMobile_IPv4.txt
# curl -s https://file.bairuo.net/iplist/output/Aggregated_ChinaMobile_IPv6.txt > /opt/mosdns_install/ChinaMobile_IPv6.txt
# curl -s https://file.bairuo.net/iplist/output/Aggregated_ChinaSciences_IPv4.txt > /opt/mosdns_install/ChinaSciences_IPv4.txt
# curl -s https://file.bairuo.net/iplist/output/Aggregated_ChinaSciences_IPv6.txt > /opt/mosdns_install/ChinaSciences_IPv6.txt
# curl -s https://file.bairuo.net/iplist/output/Aggregated_ChinaTelecom_IPv4.txt > /opt/mosdns_install/ChinaTelecom_IPv4.txt
# curl -s https://file.bairuo.net/iplist/output/Aggregated_ChinaTelecom_IPv6.txt > /opt/mosdns_install/ChinaTelecom_IPv6.txt
# curl -s https://file.bairuo.net/iplist/output/Aggregated_ChinaUnicom_IPv4.txt > /opt/mosdns_install/ChinaUnicom_IPv4.txt
# curl -s https://file.bairuo.net/iplist/output/Aggregated_ChinaUnicom_IPv6.txt > /opt/mosdns_install/ChinaUnicom_IPv6.txt

# 中国电信
curl -s https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/chinanet.txt > /opt/mosdns_install/ChinaTelecom_IPv4.txt
curl -s https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/chinanet6.txt > /opt/mosdns_install/ChinaTelecom_IPv6.txt

# 中国联通
curl -s https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/unicom.txt > /opt/mosdns_install/ChinaUnicom_IPv4.txt
curl -s https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/unicom6.txt > /opt/mosdns_install/ChinaUnicom_IPv6.txt

# 中国移动
curl -s https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/cmcc.txt > /opt/mosdns_install/ChinaMobile_IPv4.txt
curl -s https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/cmcc6.txt > /opt/mosdns_install/ChinaMobile_IPv6.txt

# 教育网
curl -s https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/cernet.txt > /opt/mosdns_install/ChinaEducation_IPv4.txt
curl -s https://raw.githubusercontent.com/gaoyifan/china-operator-ip/ip-lists/cernet6.txt > /opt/mosdns_install/ChinaEducation_IPv6.txt

# 中国所有网络
curl -s http://www.ipdeny.com/ipblocks/data/aggregated/cn-aggregated.zone > /opt/mosdns_install/ChinaAllNetwork_IPv4.txt
curl -s http://www.ipdeny.com/ipv6/ipaddresses/aggregated/cn-aggregated.zone > /opt/mosdns_install/ChinaAllNetwork_IPv6.txt


for file in /opt/mosdns_install/*; do
  if [ -f "$file" ] && [ -s "$file" ]; then
    echo "$file 下载成功"
  else
    echo "$file 下载失败，删除文件"
    rm "$file"
  fi
done
other1=`ls /opt/mosdns_install | egrep 'IPv4|IPv6' | wc -l`
if [ "$other1" -eq '12' ]; then
    cat /opt/mosdns_install/*IPv4.txt > /opt/mosdns_install/geoip_cn.txt
    cat /opt/mosdns_install/*IPv6.txt >> /opt/mosdns_install/geoip_cn.txt
    echo 'geoip_cn.txt文件生成成功'
else
    echo 'geoip文件少于12个无法生成geoip_cn.txt文件'
fi
find /opt/mosdns_install -type f ! -name "*IPv4*" ! -name "*IPv6*" -exec cp {} /usr/local/etc/mosdns \;
systemctl restart mosdns.service
other2=`ls /opt/mosdns_install | egrep -v 'IPv4|IPv6'`
echo "已替换文件,并重启mosdns服务"
echo "$other2"
