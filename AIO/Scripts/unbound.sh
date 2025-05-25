#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
export APT_LISTCHANGES_FRONTEND=none

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
yellow='\e[1m\e[33m'
reset='\e[0m'
white(){
    echo -e "$1"
}
################################用户自定义设置################################
unbound_customize_settings() {
    white "\n自定义设置（以下设置可直接回车使用默认值）"
    unbound_version=$(curl -s https://www.nlnetlabs.nl/downloads/unbound/ | grep -oP 'unbound-\K[0-9]+\.[0-9]+\.[0-9]+(?=\.tar\.gz)' | sort -V | tail -n 1)
    white "unbound 最新版本为: ${yellow}${unbound_version}${reset}"
    read -p "请输入安装的 unbound 版本：（默认最新版，或输入指定版本，如 1.23.0）：" unbound_install_v
    unbound_install_v="${unbound_install_v:-$unbound_version}"
    read -p "输入内网 IPv4 地址：（默认10.10.10.0/24）：" lan_ipv4
    lan_ipv4="${lan_ipv4:-10.10.10.0/24}"
    read -p "输入内网 IPv6 地址：（默认dc00::/64）：" lan_ipv6
    lan_ipv6="${lan_ipv6:-dc00::/64}"   
    read -p "输入Unboud 服务监听端口（默认8053端口）：" ubport
    ubport="${ubport:-8053}"
    # 询问用户输入CPU核心数，同时确保核心数不超过系统总核心数
    total_cpu_cores=$(grep -c '^processor' /proc/cpuinfo)
    while true; do
        read -p "请输入CPU核心数 (当前系统的 CPU 核心总数为 $total_cpu_cores ，最大不可超过 $total_cpu_cores ) [默认$total_cpu_cores]: " cpu_cores
        cpu_cores=${cpu_cores:-$total_cpu_cores}
        if [ "$cpu_cores" -le "$total_cpu_cores" ]; then
            break
        else
            red "输入的 CPU 核心数超过了系统的最大核心数，请重新输入"
        fi
    done
    unbound_settings_run=1
}

redis_customize_settings() {
    redis_version=$(curl -s https://download.redis.io/releases/ | grep -oP 'redis-\K[0-9]+\.[0-9]+\.[0-9]+(?=\.tar\.gz)' | sort -V | tail -n 1)
    white "redis 最新版本为: ${yellow}${redis_version}${reset}"
    read -p "请输入安装的 redis 版本：（默认最新版，或输入指定版本，如 8.0.1）：" redis_install_v
    redis_install_v="${redis_install_v:-$redis_version}"
    redis_settings_run=1
}

mosdns_customize_settings() {
    # read -p "是否会安装 Mosdns ？[Y/n](默认为Y)：" mosdns_running
    # mosdns_running=${mosdns_running:-Y}
    # if [[ "$mosdns_running" =~ ^[Yy]$ ]]; then
        read -p "输入Mosdns IPv4 地址：（默认10.10.10.3）：" mosdns_ipv4
        mosdns_ipv4="${mosdns_ipv4:-10.10.10.3}"
        read -p "请选择 Mosdns运行模式 (默认为2)：1.Fake IP  2.Read IP" mosdns_modle_choose
        mosdns_modle_choose=${mosdns_modle_choose:-2}
        if [ "$mosdns_modle_choose" == "1" ]; then
            mosdns_modle_show="Fake IP"
        elif [ "$mosdns_modle_choose" == "2" ]; then
            mosdns_modle_show="Read IP"
        fi
        read -p "输入 Sing-box 的内网 IPv4 地址：（默认10.10.10.2）：" lan_singbox_ipv4
        lan_singbox_ipv4="${lan_singbox_ipv4:-10.10.10.2}"
        read -p "请输入 Mosdns 日志轮询周期（说人话：定时清理日志周期，默认2）：1.每日  2.每周  3.每月" log_clean
        log_clean=${log_clean:-2} 
        if [ "$log_clean" == "1" ]; then
            clean_show="每日"
            clean_time="daily"
            clean_cron="59 23 * * * /usr/sbin/logrotate -f /etc/logrotate.d/logclean"
        elif [ "$log_clean" == "2" ]; then
            clean_show="每周"
            clean_time="weekly"
            clean_cron="59 23 * * 0 /usr/sbin/logrotate -f /etc/logrotate.d/logclean"
        elif [ "$log_clean" == "3" ]; then
            clean_show="每月"
            clean_time="monthly"
            clean_cron="59 23 28-31 * * [ "$(date +\%d -d tomorrow)" = "01" ] && /usr/sbin/logrotate -f /etc/logrotate.d/logclean"
        fi
        mosdns_settings_run=1
        mosdns_running=Y
    # fi
}
show_customize_settings() {
    clear    
    white "您设定的参数："
    if [[ "$unbound_settings_run" == 1 ]]; then
        white "Unboud 安装版本：${yellow}${unbound_install_v}${reset}"    
        white "内网 IPv4 地址：${yellow}${lan_ipv4}${reset}"
        white "内网 IPv6 地址：${yellow}${lan_ipv6}${reset}"
        white "Unboud 服务监听端口：${yellow}${ubport}${reset}"
    fi
    if [[ "$redis_settings_run" == 1 ]]; then
        white "Redis 安装版本：${yellow}${redis_install_v}${reset}"
    fi    
    if [[ "$mosdns_settings_run" == 1 ]]; then
        white "Mosdns IPv4 地址：${yellow}${mosdns_ipv4}${reset}"
        white "Mosdns 运行模式：${yellow}${mosdns_modle_show}${reset}"
        white "Sing-box IP 地址：${yellow}${lan_singbox_ipv4}${reset}"
        white "日志轮询周期：${yellow}${clean_show}${reset}"    
    fi    
}    
################################ 基础环境设置 ################################
basic_settings() {
    white "配置基础设置并安装依赖..."
    sleep 1
    apt-get update -y && apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || { red "环境更新失败！退出脚本"; exit 1; }
    green "环境更新成功"
    timedatectl set-timezone Asia/Shanghai || { red "时区设置失败！退出脚本"; exit 1; }
    green "时区设置成功"
    ntp_config="NTP=ntp.aliyun.com"
    echo "$ntp_config" | sudo tee -a /etc/systemd/timesyncd.conf > /dev/null
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-timesyncd
    green "已将 NTP 服务器配置为 ntp.aliyun.com"
    if [ -f /etc/systemd/resolved.conf ]; then
        dns_stub_listener=$(grep "^DNSStubListener=" /etc/systemd/resolved.conf)
        if [ -z "$dns_stub_listener" ]; then
            commented_dns_stub_listener=$(grep "^#DNSStubListener=" /etc/systemd/resolved.conf)
            if [ -n "$commented_dns_stub_listener" ]; then
                sed -i 's/^#DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
                systemctl restart systemd-resolved.service
                green "53端口占用已解除"
            else
                green "未找到53端口占用配置，无需操作"
            fi
        elif [ "$dns_stub_listener" = "DNSStubListener=yes" ]; then
            sed -i 's/^DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
            systemctl restart systemd-resolved.service
            green "53端口占用已解除"
        elif [ "$dns_stub_listener" = "DNSStubListener=no" ]; then
            green "53端口未被占用，无需操作"
        fi
    else
        green "/etc/systemd/resolved.conf 不存在，无需操作"
    fi
    # if apt install -y build-essential libssl-dev libexpat1-dev libsodium-dev libevent-dev libhiredis-dev libnghttp2-dev unbound-anchor bison flex libsystemd-dev libjemalloc-dev tcl gcc gcc-13 g++-13 make unzip dos2unix; then
    if apt install -y build-essential libssl-dev libexpat1-dev libsodium-dev libevent-dev libhiredis-dev libnghttp2-dev unbound-anchor bison flex libsystemd-dev libjemalloc-dev tcl gcc make unzip dos2unix; then
        green "依赖安装成功"
    else
        red "依赖安装失败，请检查网络连接和软件包"
        exit 1
fi
}    

################################ 安装unbound ################################
unbound_install() {
    white "${yellow}2秒后开始安装 Unbound ...${reset}"
    sleep 2
    white "正在下载 Unbound ${unbound_install_v} 源码..."
    sleep 1
    if wget https://www.nlnetlabs.nl/downloads/unbound/unbound-${unbound_install_v}.tar.gz -O unbound-${unbound_install_v}.tar.gz; then
        green "Unbound 源码下载成功"
    else
        red "下载 Unbound 源码失败"
        exit 1
    fi

    white "正在解压 Unbound ${redis_install_v} 源码..."
    sleep 1
    if tar -zxvf unbound-${unbound_install_v}.tar.gz; then
        green "Unbound 解压成功"
    else
        red "解压 Unbound 源码失败"
        exit 1
    fi

    cd unbound-${unbound_install_v}/
    white "正在配置 Unbound..."
    sleep 1
    if 	CFLAGS="-flto" CXXFLAGS="-flto" ./configure --enable-subnet --with-libevent --with-libhiredis --enable-cachedb --enable-pie --enable-relro-now --enable-tfo-client --enable-tfo-server --enable-dnscrypt --with-ssl --with-libnghttp2 --enable-systemd; then
        green "Unbound 配置成功"
    else
        red "配置 Unbound 失败"
        exit 1
    fi

    white "正在编译 Unbound..."
    sleep 1
    if make; then
        green "Unbound 编译成功"
    else
        red "编译 Unbound 失败"
        exit 1
    fi

    white "正在安装 Unbound..."
    sleep 1
    if make install; then
        green "Unbound 安装成功"
    else
        red "安装 Unbound 失败"
        exit 1
    fi

    white "创建 Unbound 用户..."
    sleep 1
    if adduser --system --group --no-create-home --disabled-login unbound; then
        green "Unbound 用户创建成功"
    else
        red "创建 Unbound 用户失败"
        exit 1
    fi

    white "初始化 Unbound 控制..."
    sleep 1
    if unbound-control-setup; then
        green "Unbound 控制初始化成功"
    else
        red "初始化 Unbound 控制失败"
        exit 1
    fi

    unbound-anchor

    white "下载根提示文件..."
    sleep 1
    if wget -O /usr/local/etc/unbound/root.hints https://www.internic.net/domain/named.cache; then
        green "根提示文件下载成功"
    else
        red "下载根提示文件失败"
        exit 1
    fi

    white "下载 Unbound 配置文件..."
    sleep 1
    rm -f /usr/local/etc/unbound/unbound.conf
    if wget --quiet --show-progress -O /usr/local/etc/unbound/unbound.conf https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/unbound/unbound-20250515-4.conf ; then
        green "Unbound 配置文件下载成功"
    else
        red "下载 Unbound 配置文件失败"
        exit 1
    fi

    white "修正 Unbound 配置文件..."
    sleep 1
    sed -i "s|access-control: 10.0.0.0/24 allow|access-control: ${lan_ipv4} allow|g" /usr/local/etc/unbound/unbound.conf
    sed -i "s|access-control: dc00::/64 allow|access-control: ${lan_ipv6} allow|g" /usr/local/etc/unbound/unbound.conf
    sed -i "s|port: 8053|port: ${ubport}|g" /usr/local/etc/unbound/unbound.conf
    sed -i "s|num-threads: 4|num-threads: ${cpu_cores}|g" /usr/local/etc/unbound/unbound.conf
    if wget --quiet --show-progress -O /lib/systemd/system/unbound.service https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/unbound/unbound.service; then
        green "Unbound 服务启动文件下载成功"
    else
        red "下载 Unbound 服务启动文件失败"
        exit 1
    fi

    white "配置解除unbound获得更大的文件描述符限制..."
    sleep 1
    if mkdir -p /etc/systemd/system/unbound.service.d; then
        green "/etc/systemd/system/unbound.service.d 创建成功"
    else
        red "/etc/systemd/system/unbound.service.d 创建失败"
        exit 1
    fi

    if wget --quiet --show-progress -O /etc/systemd/system/unbound.service.d/override.conf https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/unbound/override.conf; then
        green "/etc/systemd/system/unbound.service.d/override.conf 配置文件下载成功"
    else
        red "下载 /etc/systemd/system/unbound.service.d/override.conf 配置文件失败"
        exit 1
    fi

    white "重新加载 systemd 服务..."
    if systemctl daemon-reexec; then
        green "systemctl daemon-reexec 执行成功"
    else
        red "systemctl daemon-reexec 执行失败"
        exit 1
    fi

    sleep 1
    if systemctl daemon-reload; then
        green "systemd 服务重载成功"
    else
        red "systemd 重载失败"
        exit 1
    fi

    white "设置开机启用 Unbound 服务..."
    sleep 1
    if systemctl enable unbound; then
        green "Unbound 服务开机启用成功"
    else
        red "开机启用 Unbound 服务失败"
        exit 1
    fi
    green "Unbound 安装完成"
}    
################################ 安装redis ################################
redis_install() {
    white "${yellow}2秒后开始安装 Redis ...${reset}"
    sleep 2    
    cd /root
    white "正在下载 Redis ${redis_install_v} 源码..."
    sleep 1
    if wget https://download.redis.io/releases/redis-${redis_install_v}.tar.gz -O redis-${redis_install_v}.tar.gz; then
        green "Redis 源码下载成功"
    else
        red "下载 Redis 源码失败"
        exit 1
    fi

    white "正在解压 Redis 源码..."
    sleep 1
    if tar -zxvf redis-${redis_install_v}.tar.gz; then
        green "Redis 解压成功"
    else
        red "解压 Redis 源码失败"
        exit 1
    fi

    cd redis-${redis_install_v}/

    white "正在编译 Redis..."
    sleep 1
    # if CC=gcc-13 CXX=g++-13 make; then
    if make; then
        green "Redis 编译成功"
    else
        red "编译 Redis 失败"
        exit 1
    fi

    white "正在安装 Redis..."
    sleep 1
    # if CC=gcc-13 CXX=g++-13 make install; then
    if make install; then
        green "Redis 安装成功"
    else
        red "安装 Redis 失败"
        exit 1
    fi

    white "创建 Redis 配置目录..."
    sleep 1
    if mkdir -p /usr/local/etc/redis/; then
        green "Redis 配置目录创建成功"
    else
        red "创建 Redis 配置目录失败"
        exit 1
    fi

    white "下载 Redis 配置文件..."
    sleep 1
    if wget --quiet --show-progress -O /usr/local/etc/redis/redis.conf https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/redis/redis.conf; then
        green "Redis 配置文件下载成功"
    else
        red "下载 Redis 配置文件失败"
        exit 1
    fi

    white "配置系统内核参数..."
    sleep 1

echo 'net.ipv4.tcp_sack=1
net.ipv4.tcp_fack=1
net.core.rmem_max=67108848
net.core.wmem_max=67108848
net.core.somaxconn=4096
net.ipv4.tcp_max_syn_backlog=4096
net.ipv4.tcp_rmem=16384 16777216 536870912
net.ipv4.tcp_wmem=16384 16777216 536870912
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_adv_win_scale=0
net.ipv4.tcp_moderate_rcvbuf=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_tw_reuse=1
vm.overcommit_memory=1
net.ipv4.udp_mem=65536 131072 262144
net.ipv4.udp_rmem_min=16384
net.ipv4.udp_wmem_min=16384
kernel.panic=-1
vm.swappiness=0' > /etc/sysctl.d/99-unbound.conf

    if sysctl --system; then
        green "系统内核配置成功"
    else
        red "配置系统内核失败"
        exit 1
    fi

    white "下载 Redis 服务文件..."
    sleep 1
    if wget --quiet --show-progress -O /lib/systemd/system/redis.service https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/redis/redis.service; then
        green "Redis 服务文件下载成功"
    else
        red "下载 Redis 服务文件失败"
        exit 1
    fi

    white "配置解除redis获得更大的文件描述符限制..."
    sleep 1
    if mkdir -p /etc/systemd/system/redis-server.service.d; then
        green "/etc/systemd/system/redis-server.service.d 创建成功"
    else
        red "/etc/systemd/system/redis-server.service.d 创建失败"
        exit 1
    fi

    if wget --quiet --show-progress -O /etc/systemd/system/redis-server.service.d/override.conf https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/redis/override.conf; then
        green "/etc/systemd/system/redis-server.service.d/override.conf 配置文件下载成功"
    else
        red "下载 /etc/systemd/system/redis-server.service.d/override.conf 配置文件失败"
        exit 1
    fi

    white "重新加载 systemd 服务..."
    if systemctl daemon-reexec; then
        green "systemctl daemon-reexec 执行成功"
    else
        red "systemctl daemon-reexec 执行失败"
        exit 1
    fi

    sleep 1
    if systemctl daemon-reload; then
        green "systemd 服务重载成功"
    else
        red "systemd 重载失败"
        exit 1
    fi

    white "设置开机启用 redis 服务..."
    sleep 1
    if systemctl enable redis; then
        green "redis 服务开机启用成功"
    else
        red "开机启用 redis 服务失败"
        exit 1
    fi

    green "Redis 安装完成"
}
################################安装 mosdns################################
mosdns_install() {
    white "${yellow}2秒后开始安装 Mosdns ...${reset}"
    sleep 2
    [ ! -d "/mnt/mosdns" ] && mkdir /mnt/mosdns
    cd /mnt/mosdns
    local mosdns_host="https://github.com/IrineSistiana/mosdns/releases/download/v5.3.3/mosdns-linux-amd64.zip"
    white "开始下载 mosdns v5.3.3"
    wget "${mosdns_host}" || { red "下载失败！退出脚本"; exit 1; }
    white "开始安装MosDNS..."
    mkdir /usr/local/etc/mosdns
    unzip mosdns-linux-amd64.zip -d /mnt/mosdns
    cd /mnt/mosdns
    chmod +x mosdns
    cp mosdns /usr/local/bin
    cd /etc/systemd/system/
    touch mosdns.service
cat << 'EOF' > mosdns.service
[Unit]
Description=mosdns daemon, DNS server.
After=network-online.target

[Service]
Type=simple
Restart=always
ExecStart=/usr/local/bin/mosdns start -c /usr/local/etc/mosdns/config.yaml -d /usr/local/etc/mosdns

[Install]
WantedBy=multi-user.target
EOF

    green "MosDNS服务已安装完成"
    white "开始配置MosDNS获得更大的文件描述符限制..."
    mkdir -p /etc/systemd/system/mosdns.service.d
    wget -q -O /etc/systemd/system/mosdns.service.d/override.conf https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/mosdns/override.conf
    systemctl daemon-reexec
    systemctl daemon-reload
    white "开始配置MosDNS规则..."
    mkdir /usr/local/etc/mosdns/rule
    cd /usr/local/etc/mosdns/rule
    wget -q -O /usr/local/etc/mosdns/rule/ddnslist.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/mos_rule/ddnslist.txt
    wget -q -O /usr/local/etc/mosdns/rule/blocklist.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/mos_rule/blocklist.txt
    wget -q -O /usr/local/etc/mosdns/rule/localptr.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/mos_rule/localptr.txt
    wget -q -O /usr/local/etc/mosdns/rule/hosts.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/mos_rule/hosts.txt
    wget -q -O /usr/local/etc/mosdns/rule/chinalist.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/mos_rule/whitelist.txt   
    # wget -q -O /usr/local/etc/mosdns/rule/greylist.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/mos_rule/greylist.txt
    # wget -q -O /usr/local/etc/mosdns/rule/redirect.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/mos_rule/redirect.txt
    # wget -q -O /usr/local/etc/mosdns/rule/adlist.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/mos_rule/adlist.txt
    touch /usr/local/etc/mosdns/rule/{unboundlist.txt,fakelist.txt,proxy_ip.txt,fake_ip.txt}
    green "所有规则文件修改操作已完成"
    white "开始配置MosDNS config文件..."
    rm -rf /usr/local/etc/mosdns/config.yaml
    wget -q -O /usr/local/etc/mosdns/config.yaml https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/mosdns/config20250515r4.yaml
    sed -i "s|10.0.0.6:53|${lan_singbox_ipv4}|g" /usr/local/etc/mosdns/config.yaml
    if [ "$mosdns_modle_choose" == "1" ]; then
        # sed -i "s|- _false      #用fake模式建议为true|- _true      #用fake模式建议为true|g" /usr/local/etc/mosdns/config.yaml
        # sed -i "s|- _true      #用read模式建议为true|- _false      #用read模式建议为true|g" /usr/local/etc/mosdns/config.yaml
        echo "0.0.0.0/0" > /usr/local/etc/mosdns/rule/fake_ip.txt
        echo "" > /usr/local/etc/mosdns/rule/proxy_ip.txt
    elif [ "$mosdns_modle_choose" == "2" ]; then
        echo "0.0.0.0/0" > /usr/local/etc/mosdns/rule/proxy_ip.txt
        echo "" > /usr/local/etc/mosdns/rule/fake_ip.txt
    fi
    wget -q -O /usr/local/etc/mosdns/readme.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/mosdns/readme.txt
    green "MosDNS config文件已配置完成"    
    white "开始配置定时更新规则与清理日志..."
    cd /usr/local/etc/mosdns
    touch {geosite_cn,geoip_cn,geosite_geolocation_noncn,gfw}.txt
    wget -q -O /usr/local/etc/mosdns/install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/mosdns/install.sh
    chmod +x /usr/local/etc/mosdns/install.sh
    /usr/local/etc/mosdns/install.sh
    green "规则更新与日志清理添加完成"
    white "设置mosdns开机自启动"
    systemctl enable mosdns
    green "mosdns开机启动完成"
}
################################ 设置日志轮询 ################################
update_log() {
    wget -q -O /etc/logrotate.d/logclean https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/log_clean
    sed -i "s/daily/${clean_time}/g" /etc/logrotate.d/logclean    
    (crontab -l 2>/dev/null | grep -Fv "$clean_cron"; echo "$clean_cron") | crontab -
}   
################################ 查询转快捷 ################################
quick_check() {
    white "${yellow}查询脚本开始转快速启动...${reset}"
    if [ -z "${mosdns_running}" ]; then
        read -p "是否会安装 Mosdns ？[Y/n](默认为Y)：" mosdns_running
        mosdns_running=${mosdns_running:-Y}
        if [[ "$mosdns_running" =~ ^[Yy]$ ]]; then
            read -p "输入Mosdns IPv4 地址：（默认10.10.10.3）：" mosdns_ipv4
            mosdns_ipv4="${mosdns_ipv4:-10.10.10.3}"
        fi
    fi
    sleep 2
    wget --quiet --show-progress -O /usr/bin/check https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/redis/check.sh
    chmod +x /usr/bin/check
    if [[ "$mosdns_running" =~ ^[Yy]$ ]]; then
        sed -i "s|10.10.10.3|${mosdns_ipv4}|g" /usr/bin/check
    fi        
    green "查询脚本转快捷启动已完成， shell 界面输入 check 即可调用脚本显示 unboun 和 redis 命中率"
}

################################ 查询转快捷 ################################
quick_clean() {
    white "${yellow}缓存清理脚本开始转快速启动...${reset}"
    sleep 2
    wget --quiet --show-progress -O /usr/bin/clean https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/redis/clean.sh
    chmod +x /usr/bin/clean   
    green "查询脚本转快捷启动已完成， shell 界面输入 clean 即可调用脚本清理 unbound 和 redis 缓存"
}
################################ 卸载Unbound及Redis ################################
uninstall() {
    white "${yellow}开始卸载Unbound及Redis...${reset}"
    sleep 2
    systemctl stop redis 
    systemctl stop unbound   
    systemctl disable redis 
    systemctl disable unbound
    rm -f /lib/systemd/system/redis.service /lib/systemd/system/unbound.service /usr/local/bin/redis-* /usr/local/sbin/unbound* 
    rm -rf /usr/local/etc/redis /usr/local/etc/unbound   
    systemctl daemon-reload
    green "卸载Unbound及Redis已完成"
}
################################ Unbound 结束语 ################################
unbound_over_install() {
systemctl restart unbound
rm -f /root/unbound-${unbound_install_v}.tar.gz
rm -rf /root/unbound-${unbound_install_v}
echo "=================================================================="
echo -e "\t\tUnboud 安装完成"
echo -e "\n"
echo -e "运行目录为${yellow}/usr/local/etc${reset}下"
echo -e "此安装不包含快捷查询等快捷脚本，如需使用请使用脚本单独安装"
echo -e "温馨提示:\n本脚本仅在 ubuntu25.04 环境下测试，其他环境未经验证，请自行测试"
echo "=================================================================="
}
################################ Redis 结束语 ################################
redis_over_install() {
systemctl restart redis
rm -f /root/redis-${redis_install_v}.tar.gz
rm -rf /root/redis-${redis_install_v}
echo "=================================================================="
echo -e "\t\tRedis 安装完成"
echo -e "\n"
echo -e "运行目录为${yellow}/usr/local/etc${reset}下"
echo -e "此安装不包含快捷查询等快捷脚本，如需使用请使用脚本单独安装"
echo -e "温馨提示:\n本脚本仅在 ubuntu25.04 环境下测试，其他环境未经验证，请自行测试"
echo "=================================================================="
}
################################ Mosdns 结束语 ################################
mosdns_over_install() {
systemctl restart mosdns
rm -r /mnt/mosdns
echo "=================================================================="
echo -e "\t\tMosdns 安装完成"
echo -e "\n"
echo -e "运行目录为${yellow}/usr/local/etc${reset}下"
echo -e "${yellow}系统已完成安装，如需特殊设置，请在运行前先行\n查阅/usr/local/etc/mosdns/readme.txt文件，并按说明\n配置/usr/local/etc/mosdns/config.yaml后重启mosdns${reset}"
echo -e "温馨提示:\n本脚本仅在 ubuntu25.04 环境下测试，其他环境未经验证，请自行测试"
echo "=================================================================="
}
################################ 结束语 ################################
over_install_all() {
systemctl restart redis
systemctl restart unbound
systemctl restart mosdns
rm -f /root/redis-${redis_install_v}.tar.gz /root/unbound-${unbound_install_v}.tar.gz
rm -rf /root/redis-${redis_install_v} /root/unbound-${unbound_install_v}
rm -r /mnt/mosdns
echo "=================================================================="
echo -e "\t\t Unboud、Redis及Mosdns 安装完成"
echo -e "\n"
echo -e "运行目录均为${yellow}/usr/local/etc${reset}下"
echo -e "检查命中结果可在SSH输入:\n${yellow}check${reset} 查看结果"
echo -e "${yellow}系统已完成安装，如需特殊设置，请在运行前先行\n查阅/usr/local/etc/mosdns/readme.txt文件，并按说明\n配置/usr/local/etc/mosdns/config.yaml后重启mosdns${reset}"
echo -e "温馨提示:\n本脚本仅在 ubuntu25.04 环境下测试，其他环境未经验证，请自行测试"
echo "=================================================================="
}

###########################################################################
###                           Sing-box                                  ###
###########################################################################
################################ 用户自定义设置 ################################
install_mode_choose() {
    while true; do
        clear
        white "请选择sing-box安装模式:"
        white "1. go文件编译模式安装 [默认选项]"
        white "2. 下载二进制文件模式安装"     
        read -p "请选择: " singbox_install_mode_choose
        singbox_install_mode_choose=${singbox_install_mode_choose:-1}
        if [[ "$singbox_install_mode_choose" =~ ^[1-2]$ ]]; then
            break
        else
            red "无效的选项，请输入1或2"
        fi
    done
    # interfaces=$(ip -o link show | awk -F': ' '{print $2}')
    # # 输出物理网卡名称
    # for interface in $interfaces; do
    #     # 检查是否为物理网卡（不包含虚拟、回环等），并排除@符号及其后面的内容
    #     if [[ $interface =~ ^(en|eth).* ]]; then
    #         interface_name=$(echo "$interface" | awk -F'@' '{print $1}')  # 去掉@符号及其后面的内容
    #         echo "您当前的网卡是：$interface_name"
    #         valid_interfaces+=("$interface_name")  # 存储有效的网卡名称
    #     fi
    # done
    # while true; do
    #     # 提示用户选择
    #     read -p "脚本自行检测的是否是您要的网卡？( y [默认选项] /n): " confirm_interface
    #     confirm_interface=${confirm_interface:-y}
    #     if [[ "$confirm_interface" =~ ^[yn]$ ]]; then
    #         break
    #     else
    #         red "无效的选项，请输入y或n"
    #     fi
    # done
    # if [ "$confirm_interface" = "y" ]; then
    #     selected_interface="$interface_name"
    #     white "您选择的网卡是: ${yellow}$selected_interface${reset}"
    # elif [ "$confirm_interface" = "n" ]; then
    #     read -p "请自行输入您的网卡名称: " selected_interface
    #     white "您输入的网卡名称是: ${yellow}$selected_interface${reset}"
    # fi
    while true; do
        white "请选择安装官方 sing-box 版本："
        white "1. 编译最新版 [默认选项]"
        white "2. 编译指定版本"
        read -p "请选择服务: " sb_build_mode
        sb_build_mode=${sb_build_mode:-1}
        if [[ "$sb_build_mode" =~ ^[1-2]$ ]]; then
            break
        else
            red "无效的选项，请输入 1 或 2"
        fi
    done
    if [[ "$sb_build_mode" == "1" ]]; then
        selected_version="latest"
        white "您选择了最新版，将使用版本：$selected_version"
    elif [[ "$sb_build_mode" == "2" ]]; then
        default_version="v1.10.7"
        read -p "请输入要编译的版本号（默认：$default_version）: " input_version
        if [[ -z "$input_version" ]]; then
            selected_version="$default_version"
            white "您选择了默认版本：$selected_version"
            version_num="${selected_version#v}"
            major=$(echo "$version_num" | cut -d. -f1)
            minor=$(echo "$version_num" | cut -d. -f2)
        else
            selected_version="$input_version"
            white "您选择了指定版本：$selected_version"
            version_num="${selected_version#v}"
            major=$(echo "$version_num" | cut -d. -f1)
            minor=$(echo "$version_num" | cut -d. -f2)
        fi
    fi    
    # while true; do
    #     echo "请选择要安装的 tproxy 配置版本："
    #     echo "1) 新版 tproxy 配置"
    #     echo "2) 旧版 tproxy 配置"
    #     read -p "请输入选项 (1 或 2): " tproxy_version
    #     tproxy_version=${tproxy_version:-1}  # 默认选择新版（1）
    #     if [[ "$tproxy_version" == "1" ]]; then
    #         tproxy_name=new
    #         white "已选择：新版 tproxy 配置"
    #         break
    #     elif [[ "$tproxy_version" == "2" ]]; then
    #         tproxy_name=old
    #         white "已选择：旧版 tproxy 配置"
    #         break
    #     else
    #         red "无效的选项，请输入 1 或 2"
    #     fi
    # done
    # 选择节点类型
    while true; do
        white "\n请选择是否需要脚本添加节点:"
        white "1. 脚本添加节点（仅支持brutal和HY2节点） [默认选项]"
        white "2. 自行手动调整"     
        read -p "请选择: " node_basic_choose
        node_basic_choose=${node_basic_choose:-1}
        if [[ "$node_basic_choose" =~ ^[1-2]$ ]]; then
            break
        else
            red "无效的选项，请输入1或2"
        fi
    done
    if [[ "$node_basic_choose" == "1" ]]; then
        clear
        white "\n${yellow}特别声明:\n本脚本功能适用于本脚本安装singbox配置，其他配置请自行测试！！！${reset}\n"    
        # 选择节点类型
        while true; do
            white "请选择需要写入的节点类型 :"
            white "1. vless（brutal协议） [默认选项]"
            white "2. hy2"
            white "3. 后续自行添加节点"
            read -p "请选择: " node_operation
            node_operation=${node_operation:-1}
            if [[ "$node_operation" =~ ^[1-3]$ ]]; then
                break
            else
                red "无效的选项，请输入1、2或3"
            fi
        done
        if [[ "$node_operation" == "1" ]]; then
            #vless
            # 获取节点名称
            read -p "请输入您的 vless 节点（brutal协议）的名称: " vless_tag
            add_tag=$vless_tag
            read -p "请输入您的 vless 节点（brutal协议）的uuid: " vless_uuid
            read -p "请输入您的 vless 节点（brutal协议）的VPS的IP: " vless_server_ip
            while true; do
                read -p "请输入您的 vless 节点的（brutal协议）入站端口： " vless_port
                if [[ "$vless_port" =~ ^[0-9]{1,6}$ ]]; then
                    break
                else
                    red "无效的端口号，请重新输入"
                fi
            done
            # 获取VPS生成证书的域名
            while true; do
                read -p "请输入您的 VPS 生成证书的域名: " vless_domain
                if [[ "$vless_domain" =~ ^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                    break
                else
                    red "无效的域名格式，请重新输入"
                fi
            done
            read -p "请输入您的 vless 节点（brutal协议）的公钥（public_key）: " vless_public_key
            read -p "请输入您的 vless 节点（brutal协议）的short_id: " vless_short_id
            while true; do
                read -p "请输入您的 vless 节点（brutal协议）的上行带宽（仅限数字, 单位：Mbps）[当前网络上行带宽]：" vless_up_mbps
                if [[ "$vless_up_mbps" =~ ^[0-9]{1,6}$ ]]; then
                    break
                else
                    red "无效的上行带宽，请重新输入"
                fi
            done
            while true; do
                read -p "请输入您的 vless 节点（brutal协议）的下行带宽（仅限数字, 单位：Mbps）[当前网络下行带宽和VPS上行带宽取小值]：" vless_down_mbps
                if [[ "$vless_down_mbps" =~ ^[0-9]{1,6}$ ]]; then
                    break
                else
                    red "无效的下行带宽，请重新输入"
                fi
            done
            read -p "请输入您的内网网段(默认为10.10.10.0/24): " lanip_segment
            lanip_segment=${lanip_segment:-10.10.10.0/24}

            clear
            white "您设定的参数："
            white "内网网段：${yellow}${lanip_segment}${reset}"        
            white "节点名称：${yellow}${vless_tag}${reset}"
            white "uuid：${yellow}${vless_uuid}${reset}"
            white "VPS的IP：${yellow}${vless_server_ip}${reset}"
            white "入站端口：${yellow}${vless_port}${reset}"
            white "VPS生成证书的域名：${yellow}${vless_domain}${reset}"
            white "公钥（public_key）：${yellow}${vless_public_key}${reset}"
            white "short_id：${yellow}${vless_short_id}${reset}"
            white "上行带宽：${yellow}${vless_up_mbps}${reset}"
            white "下行带宽：${yellow}${vless_down_mbps}${reset}\n"
            sleep 1
        elif [[ "$node_operation" == "2" ]]; then
            clear
            #hy2
            # 获取节点名称
            read -p "请输入您的 HY2 节点名称: " hy2_pass_tag
            add_tag=$hy2_pass_tag
            read -p "请输入您的 HY2 节点的VPS的IP: " hy2_pass_server_ip
            while true; do
                read -p "请输入您的 HY2 节点的入站端口： " hy2_pass_port
                if [[ "$hy2_pass_port" =~ ^[0-9]{1,6}$ ]]; then
                    break
                else
                    red "无效的端口号，请重新输入"
                fi
            done
            while true; do
                read -p "请输入您的 HY2 节点的上行带宽（仅限数字, 单位：Mbps）[当前网络上行带宽]：" hy2_pass_up_mbps
                if [[ "$hy2_pass_up_mbps" =~ ^[0-9]{1,6}$ ]]; then
                    break
                else
                    red "无效的上行带宽，请重新输入"
                fi
            done
            while true; do
                read -p "请输入您的 HY2 节点的下行带宽（仅限数字, 单位：Mbps）[当前网络下行带宽和VPS上行带宽取小值]：" hy2_pass_down_mbps
                if [[ "$hy2_pass_down_mbps" =~ ^[0-9]{1,6}$ ]]; then
                    break
                else
                    red "无效的下行带宽，请重新输入"
                fi
            done
            read -p "请输入您的 HY2 节点的密码: " hy2_pass_password
            while true; do
                read -p "请输入您的 HY2生成证书的域名（示例及默认为：bing.com）: " hy2_pass_domain
                hy2_pass_domain=${hy2_pass_domain:-bing.com}
                if [[ "$hy2_pass_domain" =~ ^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
                    break
                else
                    red "无效的域名格式，请重新输入"
                fi
            done
            read -p "请输入您的内网网段(默认为10.10.10.0/24): " lanip_segment
            lanip_segment=${lanip_segment:-10.10.10.0/24}

            clear
            white "您设定的参数："
            white "内网网段：${yellow}${lanip_segment}${reset}"  
            white "节点名称：${yellow}${hy2_pass_tag}${reset}"
            white "VPS的IP：${yellow}${hy2_pass_server_ip}${reset}"
            white "入站端口：${yellow}${hy2_pass_port}${reset}"
            white "上行带宽：${yellow}${hy2_pass_up_mbps}${reset}"
            white "下行带宽：${yellow}${hy2_pass_down_mbps}${reset}"
            white "密码：${yellow}${hy2_pass_password}${reset}"
            white "生成证书的域名：${yellow}${hy2_pass_domain}${reset}\n"
            sleep 1
        elif [[ "$node_operation" == "3" ]]; then
            #自行配置
            white "您已选择后续自行添加节点，请关注脚本完成后添加节点"
        fi
    else
        white "${yellow}用户选择自行调整配置文件...${reset}"
    fi
}      

################################ 基础环境设置 ################################
singbox_basic() {
    white "配置基础设置并安装依赖..."
    sleep 1
    apt-get update -y && apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || { red "环境更新失败！退出脚本"; exit 1; }
    green "环境更新成功"
    white "环境依赖安装开始..."
    apt install curl git build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64 -y || { red "环境依赖安装失败！退出脚本"; exit 1; }
    green "依赖安装成功"
    timedatectl set-timezone Asia/Shanghai || { red "时区设置失败！退出脚本"; exit 1; }
    green "时区设置成功"
    ntp_config="NTP=ntp.aliyun.com"
    echo "$ntp_config" | sudo tee -a /etc/systemd/timesyncd.conf > /dev/null
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-timesyncd
    green "已将 NTP 服务器配置为 ntp.aliyun.com"
    if [ -f /etc/systemd/resolved.conf ]; then
        # 检测是否有未注释的 DNSStubListener 行
        dns_stub_listener=$(grep "^DNSStubListener=" /etc/systemd/resolved.conf)
        if [ -z "$dns_stub_listener" ]; then
            # 如果没有找到未注释的 DNSStubListener 行，检查是否有被注释的 DNSStubListener
            commented_dns_stub_listener=$(grep "^#DNSStubListener=" /etc/systemd/resolved.conf)
            if [ -n "$commented_dns_stub_listener" ]; then
                # 如果找到被注释的 DNSStubListener，取消注释并改为 no
                sed -i 's/^#DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
                systemctl restart systemd-resolved.service
                green "53端口占用已解除"
            else
                green "未找到53端口占用配置，无需操作"
            fi
        elif [ "$dns_stub_listener" = "DNSStubListener=yes" ]; then
            # 如果找到 DNSStubListener=yes，则修改为 no
            sed -i 's/^DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
            systemctl restart systemd-resolved.service
            green "53端口占用已解除"
        elif [ "$dns_stub_listener" = "DNSStubListener=no" ]; then
            # 如果 DNSStubListener 已为 no，提示用户无需修改
            green "53端口未被占用，无需操作"
        fi
    else
        green "/etc/systemd/resolved.conf 不存在，无需操作"
    fi
}
################################编译 Sing-Box 的最新版本################################
install_singbox() {
    white "编译Sing-Box 最新版本..."
    sleep 1
    apt -y install curl git build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64
    white "开始编译 Sing-Box ..."
    rm -rf /root/go/bin/*
    curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz -o go1.22.4.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/golang.sh
    source /etc/profile.d/golang.sh
    # go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme "-X 'main.version=1.9.7'" github.com/sagernet/sing-box/cmd/sing-box@latest
    # go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@latest
    if [[ "$build_mode" == "1" ]]; then
        go install -v -tags "with_quic,with_grpc,with_dhcp,with_wireguard,with_utls,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme" github.com/sagernet/sing-box/cmd/sing-box@$selected_version
    elif [[ "$build_mode" == "2" ]]; then
        if [[ "$major" -eq 1 && "$minor" -lt 11 ]]; then
            # 1.10.x 及以下
            go install -v -tags "with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme" github.com/sagernet/sing-box/cmd/sing-box@$selected_version
        else
            # 1.11.0 或更高
            go install -v -tags "with_quic,with_grpc,with_dhcp,with_wireguard,with_utls,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme" github.com/sagernet/sing-box/cmd/sing-box@$selected_version
        fi
    fi
    white "等待检测安装状态"    
    if ! go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@latest; then
        red "Sing-Box 编译失败！退出脚本"
        rm -rf /mnt/singbox.sh    #delete    
        exit 1
    fi
    white "编译完成，准备提取版本信息..."

    # 提取编译库地址和版本号
    singbox_module="github.com/sagernet/sing-box@$selected_version"
    compiled_repo=${singbox_module%@*}    # 模块地址
    compiled_version=$(go list -m $singbox_module 2>/dev/null | awk '{print $2}')  # 实际版本号

    # 输出到文件
    echo -e "编译地址：$compiled_repo\n版本号码：$compiled_version" > /mnt/singbox_build_info.txt
    white "编译信息已输出到 /mnt/singbox_build_info.txt"
    cp $(go env GOPATH)/bin/sing-box /usr/local/bin/
    white "Sing-Box 安装完成"
    mkdir -p /usr/local/etc/sing-box
    mv /mnt/singbox_build_info.txt /usr/local/etc/sing-box
    sleep 1
}
################################二进制文件安装 Sing-Box 的最新版本################################
install_binary_file_singbox() {
    white "下载Sing-Box 最新版本二进制文件..."
    mkdir -p /mnt/singbox && cd /mnt/singbox
    local ARCH_RAW=$(uname -m)
    case "${ARCH_RAW}" in
        x86_64)        ARCH='amd64'  ;;
        x86|i686|i386) ARCH='386'    ;;
        aarch64|arm64) ARCH='arm64'  ;;
        armv7l)        ARCH='armv7'  ;;
        s390x)         ARCH='s390x'  ;;
        *) 
            red "sing-box暂不支持该架构: ${ARCH_RAW}"
            exit 1
        ;;
    esac
    while true; do
        white "请选择安装官方 sing-box 版本："
        white "1. 安装最新版 [默认选项]"
        white "2. 安装指定版本"
        read -p "请选择服务: " sb_build_mode
        sb_build_mode=${sb_build_mode:-1}
        if [[ "$sb_build_mode" =~ ^[1-2]$ ]]; then
            break
        else
            red "无效的选项，请输入 1 或 2"
        fi
    done
    if [[ "$sb_build_mode" == "1" ]]; then
         local singbox_VERSION=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep tag_name | cut -d ":" -f2 | sed 's/[\",v ]//g')
        white "您选择了最新版，将使用版本：$singbox_VERSION"
    elif [[ "$sb_build_mode" == "2" ]]; then
        default_version="v1.10.7"
        read -p "请输入要编译的版本号（默认：$default_version）: " input_version
        if [[ -z "$input_version" ]]; then
            singbox_VERSION=${selected_version//v/}
            white "您选择了默认版本：$singbox_VERSION"
        else
            singbox_VERSION=${selected_version//v/}
            white "您选择了指定版本：$singbox_VERSION"
        fi
    fi   
    wget --quiet --show-progress -O /mnt/singbox/singbox.tar.gz https://github.com/SagerNet/sing-box/releases/download/v${singbox_VERSION}/sing-box-${singbox_VERSION}-linux-${ARCH}.tar.gz
    if [ ! -f "/mnt/singbox/singbox.tar.gz" ]; then
        red "下载最新版sing-box文件失败，请检查网络，保持网络畅通后重新运行脚本"
        rm -rf /mnt/singbox.sh    #delete
        rm -rf /mnt/singbox
        exit 1
    fi
    tar -C /mnt/singbox -xzf /mnt/singbox/singbox.tar.gz
    chown root:root /mnt/singbox/sing-box-${singbox_VERSION}-linux-${ARCH}/sing-box
    mv /mnt/singbox/sing-box-${singbox_VERSION}-linux-${ARCH}/sing-box /usr/local/bin 
    if [ ! -f "/usr/local/bin/sing-box" ]; then
        red "文件移动失败，请检查用户权限"
        rm -rf /mnt/singbox.sh    #delete
        rm -rf /mnt/singbox
        exit 1
    fi
    rm -rf /mnt/singbox
    white "Sing-Box 安装完成"
    mkdir -p /usr/local/etc/sing-box
    sleep 1
}    
################################启动脚本################################
install_config() {
    white "配置系统服务文件"
    sleep 1
    sing_box_service_file="/etc/systemd/system/sing-box.service"
if [ ! -f "$sing_box_service_file" ]; then

    cat << EOF > "$sing_box_service_file"
[Unit]
Description=sing-box service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target

[Service]
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/sing-box run -c /usr/local/etc/sing-box/config.json
Restart=on-failure
RestartSec=1800s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF
    white "sing-box服务创建完成"  
else
    # 如果服务文件已经存在，则给出警告
    white "警告：sing-box服务文件已存在，无需创建"
fi 
    sleep 1
    systemctl daemon-reload 
    if [[ "$node_basic_choose" == "1" ]]; then
        if [[ "$node_operation" == "1" ]]; then
            wget -q -O /usr/local/etc/sing-box/config.json https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/singbox/config_vless.json
            singbox_config_file="/usr/local/etc/sing-box/config.json"
            if [ ! -f "$singbox_config_file" ]; then
                red "错误：配置文件 $singbox_config_file 不存在"
                red "请检查网络可正常访问github后运行脚本"
                rm -rf /mnt/singbox.sh    #delete
                exit 1
            fi
            sed -i "s|vless_tag|${vless_tag}|g" /usr/local/etc/sing-box/config.json
            sed -i "s|vless_uuid|${vless_uuid}|g" /usr/local/etc/sing-box/config.json
            sed -i "s|vless_server_ip|${vless_server_ip}|g" /usr/local/etc/sing-box/config.json
            sed -i "s|vless_port|${vless_port}|g" /usr/local/etc/sing-box/config.json
            sed -i "s|vless_domain|${vless_domain}|g" /usr/local/etc/sing-box/config.json
            sed -i "s|vless_public_key|${vless_public_key}|g" /usr/local/etc/sing-box/config.json
            sed -i "s|vless_short_id|${vless_short_id}|g" /usr/local/etc/sing-box/config.json
            sed -i "s|vless_up_mbps|${vless_up_mbps}|g" /usr/local/etc/sing-box/config.json
            sed -i "s|vless_down_mbps|${vless_down_mbps}|g" /usr/local/etc/sing-box/config.json
        elif [[ "$node_operation" == "2" ]]; then
            wget -q -O /usr/local/etc/sing-box/config.json https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/singbox/config_hy2.json
            singbox_config_file="/usr/local/etc/sing-box/config.json"
            if [ ! -f "$singbox_config_file" ]; then
                red "错误：配置文件 $singbox_config_file 不存在"
                red "请检查网络可正常访问github后运行脚本"
                rm -rf /mnt/singbox.sh    #delete
                exit 1
            fi            
            sed -i "s|hy2_pass_tag|${hy2_pass_tag}|g" /usr/local/etc/sing-box/config.json
            sed -i "s|hy2_pass_server_ip|${hy2_pass_server_ip}|g" /usr/local/etc/sing-box/config.json
            sed -i "s|hy2_pass_port|${hy2_pass_port}|g" /usr/local/etc/sing-box/config.json
            sed -i "s|hy2_pass_up_mbps|${hy2_pass_up_mbps}|g" /usr/local/etc/sing-box/config.json
            sed -i "s|hy2_pass_down_mbps|${hy2_pass_down_mbps}|g" /usr/local/etc/sing-box/config.json
            sed -i "s|hy2_pass_password|${hy2_pass_password}|g" /usr/local/etc/sing-box/config.json
            sed -i "s|hy2_pass_domain|${hy2_pass_domain}|g" /usr/local/etc/sing-box/config.json
        fi
    else
        wget -q -O /usr/local/etc/sing-box/config.json https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/singbox/singbox.json
        singbox_config_file="/usr/local/etc/sing-box/config.json"
        if [ ! -f "$singbox_config_file" ]; then
            red "错误：配置文件 $singbox_config_file 不存在"
            red "请检查网络可正常访问github后运行脚本"
            rm -rf /mnt/singbox.sh    #delete
            exit 1
        fi    
    fi
}
################################安装tproxy################################
install_tproxy() {
    sleep 1
    white "开始创建nftables tproxy转发..."
    sleep 1
    apt install nftables -y
if [ ! -f "/etc/systemd/system/sing-box-router.service" ]; then
    cat <<EOF > "/etc/systemd/system/sing-box-router.service"
[Unit]
Description=sing-box TProxy Rules
After=network.target
Wants=network.target

[Service]
User=root
Type=oneshot
RemainAfterExit=yes
# there must be spaces before and after semicolons
ExecStart=/sbin/ip rule add fwmark 1 table 100 ; /sbin/ip route add local default dev lo table 100 ; /sbin/ip -6 rule add fwmark 1 table 101 ; /sbin/ip -6 route add local ::/0 dev lo table 101
ExecStop=/sbin/ip rule del fwmark 1 table 100 ; /sbin/ip route del local default dev lo table 100 ; /sbin/ip -6 rule del fwmark 1 table 101 ; /sbin/ip -6 route del local ::/0 dev lo table 101

[Install]
WantedBy=multi-user.target
EOF
    green "sing-box-router 服务创建完成"
else
    white "警告：sing-box-router 服务文件已存在，无需创建"
fi
    white "开始写入nftables tproxy规则..."
echo "" > "/etc/nftables.conf"
    if [[ "$tproxy_name" == "old" ]]; then
cat <<EOF > "/etc/nftables.conf"
#!/usr/sbin/nft -f

table inet singbox {
# 原本的 local_ipv4 设置
	 set local_ipv4 {
	 	type ipv4_addr
	 	flags interval
	 	elements = {
			10.10.10.0/24,	 	
			127.0.0.0/8,
	 		169.254.0.0/16,
	 		172.16.0.0/12,
	 		192.168.0.0/16,
	 		240.0.0.0/4
	 	}
	 }

	set local_ipv6 {
		type ipv6_addr
		flags interval
		elements = {
			::ffff:0.0.0.0/96,
			64:ff9b::/96,
			100::/64,
			2001::/32,
			2001:10::/28,
			2001:20::/28,
			2001:db8::/32,
			2002::/16,
			fc00::/7,
			fe80::/10
		}
	}

	chain singbox-tproxy {
		fib daddr type { unspec, local, anycast, multicast } return
		ip daddr @local_ipv4 return
		ip6 daddr @local_ipv6 return
		udp dport { 123 } return
		meta l4proto { tcp, udp } meta mark set 1 tproxy to :7896 accept
	}

	chain singbox-mark {
		fib daddr type { unspec, local, anycast, multicast } return
		ip daddr @local_ipv4 return
		ip6 daddr @local_ipv6 return
		udp dport { 123 } return
		meta mark set 1
	}

	chain mangle-output {
		type route hook output priority mangle; policy accept;
		meta l4proto { tcp, udp } skgid != 1 ct direction original goto singbox-mark
	}

	chain mangle-prerouting {
		type filter hook prerouting priority mangle; policy accept;
		iifname { lo, $selected_interface } meta l4proto { tcp, udp } ct direction original goto singbox-tproxy
	}
}
EOF
    elif [[ "$tproxy_name" == "new" ]]; then
cat <<EOF > "/etc/nftables.conf"
#!/usr/sbin/nft -f
table inet singbox {
	set local_ipv4 {
		type ipv4_addr
		flags interval
		elements = {
			10.10.10.0/24,
			127.0.0.0/8,
			169.254.0.0/16,
			172.16.0.0/12,
			192.168.0.0/16,
			240.0.0.0/4
		}
	}

	set local_ipv6 {
		type ipv6_addr
		flags interval
		elements = {
			::ffff:0.0.0.0/96,
			64:ff9b::/96,
			100::/64,
			2001::/32,
			2001:10::/28,
			2001:20::/28,
			2001:db8::/32,
			2002::/16,
			fc00::/7,
			fe80::/10
		}
	}

	set dns_ipv4 {
		type ipv4_addr
		elements = {
			8.8.8.8,
			8.8.4.4,
			1.1.1.1,
			1.0.0.1
		}
	}

	set dns_ipv6 {
		type ipv6_addr
		elements = {
                2001:4860:4860::8888,
                2001:4860:4860::8844,
		        2606:4700:4700::1111,
		        2606:4700:4700::1001
		}
	}

        set fake_ipv4 {
                type ipv4_addr
                flags interval
                elements = {
                    28.0.0.0/8
                }
        }

        set fake_ipv6 {
                type ipv6_addr
                flags interval
                elements = {
                    f2b0::/18
                }
        }

        chain nat-prerouting {
                type nat hook prerouting priority dstnat; policy accept;
                fib daddr type { unspec, local, anycast, multicast } return
                ip daddr @local_ipv4 return
                ip6 daddr @local_ipv6 return
                udp dport { 123 } return
                ip daddr @dns_ipv4 meta l4proto tcp redirect to :7877
                ip6 daddr @dns_ipv6 meta l4proto tcp redirect to :7877
                iifname { lo, enp6s18 } meta l4proto { tcp } redirect to :7877 
        }

        chain nat-output {
                type nat hook output priority filter; policy accept;
                fib daddr type { unspec, local, anycast, multicast } return
                ip daddr @local_ipv4 return
                ip6 daddr @local_ipv6 return
                udp dport { 123 } return
                ip daddr @fake_ipv4 meta l4proto tcp redirect to :7877
                ip6 daddr @fake_ipv6 meta l4proto tcp redirect to :7877
                ip daddr @dns_ipv4 meta l4proto tcp redirect to :7877
                ip6 daddr @dns_ipv6 meta l4proto tcp redirect to :7877
                iifname { lo, enp6s18 } meta l4proto { tcp } redirect to :7877 

        }

	chain singbox-tproxy {
		fib daddr type { unspec, local, anycast, multicast } return
		ip daddr @local_ipv4 return
		ip6 daddr @local_ipv6 return
		udp dport { 123 } return
		meta l4proto { udp } meta mark set 1 tproxy to :7896 accept
	}

	chain singbox-mark {
		fib daddr type { unspec, local, anycast, multicast } return
		ip daddr @local_ipv4 return
		ip6 daddr @local_ipv6 return
		udp dport { 123 } return
		meta mark set 1
	}

	chain mangle-output {
		type route hook output priority mangle; policy accept;
		meta l4proto { udp } skgid != 1 ct direction original goto singbox-mark
	}

	chain mangle-prerouting {
		type filter hook prerouting priority mangle; policy accept;
                ip daddr @dns_ipv4 meta l4proto {  udp } ct direction original goto singbox-tproxy
                ip6 daddr @dns_ipv6 meta l4proto {  udp } ct direction original goto singbox-tproxy
		iifname { lo, enp6s18 } meta l4proto {  udp } ct direction original goto singbox-tproxy
	}
}
EOF
    fi
    sed -i "s#10.10.10.0/24#${lanip_segment}#g" /etc/nftables.conf
    green "nftables规则写入完成"
    nft flush ruleset
    nft -f /etc/nftables.conf
    systemctl enable --now nftables
    green "Nftables tproxy转发创建完成"
}
################################sing-box安装结束################################
install_sing_box_over() {
    white "开始启动sing-box..."
    if [[ "$node_basic_choose" -eq 2 || "$node_operation" -eq 3 ]]; then
        # systemctl enable sing-box-router
        systemctl enable sing-box
    elif [[ "$node_basic_choose" -eq 1 || "$node_operation" -eq 1 || "$node_operation" -eq 2 ]]; then
        # systemctl enable --now sing-box-router
        systemctl enable --now sing-box
    else
        echo "不满足条件，不执行任何操作"
    fi
    # systemctl enable --now sing-box-router
    systemctl enable --now sing-box
    green "Sing-box启动已完成"
    if [[ "$node_basic_choose" == "1" ]]; then
        systemctl stop sing-box && systemctl daemon-reload && systemctl restart sing-box
        rm -rf /mnt/singbox.sh    #delete       
        local_ip=$(hostname -I | awk '{print $1}')
        echo "=================================================================="
        echo -e "\t\t\tSing-Box 安装完毕"
        echo -e "\n"
        echo -e "singbox运行目录为${yellow}/usr/loacl/etc/sing-box${reset}"
        echo -e "singbox WebUI地址:${yellow}http://$local_ip:9090${reset}"
        echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，已查\n询程序运行状态，如出现\e[1m\e[32m active (running)\e[0m，程序已启动成功"
        echo "=================================================================="
        systemctl status sing-box
    else
        systemctl stop sing-box && systemctl daemon-reload
        rm -rf /mnt/singbox.sh    #delete       
        local_ip=$(hostname -I | awk '{print $1}')
        echo "=================================================================="
        echo -e "\t\t\tSing-Box 安装完毕"
        echo -e "\n"
        echo -e "singbox运行目录为${yellow}/usr/loacl/etc/sing-box${reset}"
        echo -e "singbox WebUI地址:${yellow}http://$local_ip:9090${reset}"
        echo -e "温馨提示:\n本脚本仅在 ubuntu25.04 环境下测试，其他环境未经验证，目前程序未\n运行，请自行修改运行目录下配置文件后运行\e[1m\e[33msystemctl restart sing-box\e[0m\n命令运行程序。"
        echo "=================================================================="
    fi
}

################################ 选项选择 ################################
unbound_choose() {
    clear
    echo "=================================================================="
    echo -e "\t\tUnbound & Redis 相关脚本 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo "请选择要执行的服务："
    echo "=================================================================="
    echo "1. 一键安装 Unboun、Redis及Mosdns  -- CN20250515-5版" 
    echo "2. 独立安装 Unbound"
    echo "3. 独立安装 Redis"
    echo "4. 独立安装 Mosdns"        
    echo "5. 卸载Unbound及Redis"
    echo "6. 创建/更新快速检查日志脚本"
    echo "7. 创建/更新快速清理 ubound 和 redis 缓存脚本"
    echo -e "\t"
    echo "-. 返回上级菜单"          
    echo "0. 退出脚本"        
    read -p "请选择服务: " choice
    case $choice in
        1)
            white "开始一键安装Unboun、Redis及Mosdns  -- CN20250515-5版"
            unbound_customize_settings
            redis_customize_settings
            mosdns_customize_settings
            show_customize_settings
            basic_settings
            unbound_install
            redis_install
            # if [[ "$mosdns_running" =~ ^[Yy]$ ]]; then
                mosdns_install
                update_log
            # fi
            quick_check
            quick_clean
            over_install_all
            ;;
        2)
            white "开始安装Unbound"
            unbound_customize_settings
            show_customize_settings
            basic_settings
            unbound_install
            unbound_over_install
            ;;
        3)
            white "开始安装Redis"
            redis_customize_settings
            show_customize_settings
            basic_settings
            redis_install
            redis_over_install
            ;;
        4)
            white "开始安装mosdns"
            mosdns_customize_settings
            show_customize_settings
            basic_settings
            mosdns_install
            update_log
            mosdns_over_install
            ;;  
        8)
            white "开始安装官方Singbox核心"
            install_mode_choose
            singbox_basic
            if [[ "$singbox_install_mode_choose" == "1" ]]; then 
                install_singbox
            elif [[ "$singbox_install_mode_choose" == "2" ]]; then
                install_binary_file_singbox
            fi
            install_config
            # install_tproxy
            install_sing_box_over
            ;;                                               
        5)
            white "开始一键卸载Unbound及Redis"
            uninstall
            ;;
        6)
            white "开始创建/更新快速检查日志脚本"
            quick_check
            ;;
        7)
            white "开始创建/更新快速清理 ubound 和 redis 缓存脚本"
            quick_clean
            ;;                                
        0)
            red "退出脚本，感谢使用."
            rm -rf /mnt/unbound.sh    #delete             
            ;;
        -)
            white "脚本切换中，请等待..."
            rm -rf /mnt/unbound.sh    #delete       
            wget -q -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
            ;;                            
        *)
            white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            unbound_choose
            ;;
    esac
}
################################ 主脚本 ################################
unbound_choose