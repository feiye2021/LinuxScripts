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
    read -p "输入内网 IPv4 地址：（默认10.10.10.0/24）：" lan_ipv4
    lan_ipv4="${lan_ipv4:-10.10.10.0/24}"
    read -p "输入内网 IPv6 地址：（默认dc00::/64）：" lan_ipv6
    lan_ipv6="${lan_ipv6:-dc00::/64}"   
    read -p "输入Unboud 服务监听端口（默认53端口）：" ubport
    ubport="${ubport:-53}"
    read -p "是否会安装 Mosdns 配合 Fake IP 方案使用？[y/N](默认为N)：" install_mosdns
    install_mosdns=${install_mosdns:-N}
    if [[ "$install_mosdns" =~ ^[Yy]$ ]]; then
        read -p "输入Mosdns IPv4 地址：（默认10.10.10.3）：" mosdns_ipv4
        mosdns_ipv4="${mosdns_ipv4:-10.10.10.3}"
    fi
    clear    
    white "您设定的参数："
    white "内网 IPv4 地址：${yellow}${lan_ipv4}${reset}"
    white "内网 IPv6 地址：${yellow}${lan_ipv6}${reset}"
    white "Unboud 服务监听端口：${yellow}${ubport}${reset}"
    if [[ "$install_mosdns" =~ ^[Yy]$ ]]; then
        white "Mosdns IPv4 地址：${yellow}${mosdns_ipv4}${reset}"
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
    if apt install -y build-essential libssl-dev libexpat1-dev libsodium-dev libevent-dev libhiredis-dev libnghttp2-dev unbound-anchor bison flex libsystemd-dev libjemalloc-dev tcl gcc make dos2unix; then
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
    white "正在下载 Unbound 1.22.0 源码..."
    sleep 1
    if wget https://www.nlnetlabs.nl/downloads/unbound/unbound-1.22.0.tar.gz -O unbound-1.22.0.tar.gz; then
        green "Unbound 源码下载成功"
    else
        red "下载 Unbound 源码失败"
        exit 1
    fi

    white "正在解压 Unbound 1.22.0 源码..."
    sleep 1
    if tar -zxvf unbound-1.22.0.tar.gz; then
        green "Unbound 解压成功"
    else
        red "解压 Unbound 源码失败"
        exit 1
    fi

    cd unbound-1.22.0/
    white "正在配置 Unbound..."
    sleep 1
    if ./configure --enable-subnet --with-libevent --with-libhiredis --enable-cachedb --enable-pie --enable-relro-now --enable-tfo-client --enable-tfo-server --enable-dnscrypt --with-ssl --with-libnghttp2 --enable-systemd; then
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
    if wget --quiet --show-progress -O /usr/local/etc/unbound/unbound.conf https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/unbound/unbound.conf; then
        green "Unbound 配置文件下载成功"
    else
        red "下载 Unbound 配置文件失败"
        exit 1
    fi

    white "修正 Unbound 配置文件..."
    sleep 1
    sed -i "s|access-control: 10.0.0.0/24 allow|access-control: ${lan_ipv4} allow|g" /usr/local/etc/unbound/unbound.conf
    sed -i "s|access-control: dc00::/64 allow|access-control: ${lan_ipv6} allow|g" /usr/local/etc/unbound/unbound.conf
    sed -i "s|port: 53|port: ${ubport}|g" /usr/local/etc/unbound/unbound.conf

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
    white "正在下载 Redis 源码..."
    sleep 1
    if wget https://download.redis.io/releases/redis-7.4.2.tar.gz -O redis-7.4.2.tar.gz; then
        green "Redis 源码下载成功"
    else
        red "下载 Redis 源码失败"
        exit 1
    fi

    white "正在解压 Redis 源码..."
    sleep 1
    if tar -zxvf redis-7.4.2.tar.gz; then
        green "Redis 解压成功"
    else
        red "解压 Redis 源码失败"
        exit 1
    fi

    cd redis-7.4.2/

    white "正在编译 Redis..."
    sleep 1
    if make; then
        green "Redis 编译成功"
    else
        red "编译 Redis 失败"
        exit 1
    fi

    white "正在安装 Redis..."
    sleep 1
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
    echo 'net.core.rmem_max=16777216' >> /etc/sysctl.conf
    echo 'net.core.wmem_max=16777216' >> /etc/sysctl.conf
    echo 'net.core.somaxconn=4096' >> /etc/sysctl.conf
    echo 'net.ipv4.udp_mem=65536 131072 262144' >> /etc/sysctl.conf
    echo 'net.ipv4.tcp_tw_reuse=1' >> /etc/sysctl.conf
    echo 'vm.overcommit_memory=1' >> /etc/sysctl.conf

    if sysctl -p; then
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
################################ 查询转快捷 ################################
quick_check() {
    white "${yellow}查询脚本开始转快速启动...${reset}"
    if [ -z "${install_mosdns}" ]; then
        read -p "是否会安装 Mosdns 配合 Fake IP 方案使用？[y/N](默认为N)：" install_mosdns
        install_mosdns=${install_mosdns:-N}
        if [[ "$install_mosdns" =~ ^[Yy]$ ]]; then
            read -p "输入Mosdns IPv4 地址：（默认10.10.10.3）：" mosdns_ipv4
            mosdns_ipv4="${mosdns_ipv4:-10.10.10.3}"
        fi
    fi
    sleep 2
    wget --quiet --show-progress -O /usr/bin/check https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/unbound/redis/check.sh
    chmod +x /usr/bin/check
    if [[ "$install_mosdns" =~ ^[Yy]$ ]]; then
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
################################ 结束语 ################################
over_install() {
systemctl restart redis
systemctl restart unbound
rm -f /root/redis-7.4.2.tar.gz /root/unbound-1.22.0.tar.gz
rm -rf /root/redis-7.4.2 /root/unbound-1.22.0 
echo "=================================================================="
echo -e "\t\tUnboud及Redis安装完成"
echo -e "\n"
echo -e "运行目录为${yellow}/usr/local/etc${reset}下"
echo -e "检查命中结果可在SSH输入:\n${yellow}check${reset} 查看结果"
echo -e "温馨提示:\n本脚本仅在 ubuntu24.01 环境下测试，其他环境未经验证，请自行测试"
echo "=================================================================="
}
################################ 选项选择 ################################
unbound_choose() {
    clear
    echo "=================================================================="
    echo -e "\t\tUnbound & Redis 相关脚本 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo "请选择要执行的服务："
    echo "=================================================================="
    echo "1. 一键安装Unbound及Redis-CN20250424"
    echo "2. 卸载Unbound及Redis"
    echo "3. 创建/更新快速检查日志脚本"    
    echo "4. 创建/更新快速清理 ubound 和 redis 缓存脚本"       
    echo -e "\t"
    echo "-. 返回上级菜单"          
    echo "0. 退出脚本"        
    read -p "请选择服务: " choice
    case $choice in
        1)
            white "开始一键安装Unbound及Redis-CN20250424"
            unbound_customize_settings
            basic_settings
            unbound_install
            redis_install
            quick_check
            quick_clean
            over_install
            ;;
        2)
            white "开始一键卸载Unbound及Redis"
            uninstall
            ;;
        3)
            white "开始创建/更新快速检查日志脚本"
            quick_check
            ;;
        4)
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