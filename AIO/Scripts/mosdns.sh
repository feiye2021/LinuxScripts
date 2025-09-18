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
#配置版本
mosdns_latest_version_PH=mosdns-ph-20250912
mosdns_latest_version_oupavoc=20240930

private_ip=$(ip route get 1.2.3.4 | awk '{print $7}' | head -1)
private_lan=$(echo "$private_ip" | cut -d'.' -f1-3)

################################用户自定义设置################################
mosdns_customize_o() {
    clear
    white "\n自定义设置（以下设置可直接回车使用默认值）"
    read -p "输入sing-box入站IP地址：（默认$private_lan.2）：" uiport
    uiport="${uiport:-$private_lan.2}"
    clear
    read -p "输入sing-box 服务 DNS-IN 监听端口（默认1053端口）：" sbport
    sbport="${sbport:-1053}"
    # 选择是否开启ECS IP
    while true; do
        clear
        white "请选择是否启用${yellow} ECS IP修正 ${reset}DNS 解析:"
        white "1. 启用 [默认选项]"
        white "2. 不启用"
        read -p "请选择: " ECSIP_switch
        ECSIP_switch=${ECSIP_switch:-1}
        if [[ "$ECSIP_switch" =~ ^[1-2]$ ]]; then
            break
        else
            red "无效的选项，请输入1或2"
        fi
    done
    if [[ "$ECSIP_switch" == "1" ]]; then
        clear
        while true; do
            white "请选择是否启用${yellow} ECS IPv6 ${reset}:"
            white "${yellow}注意： 要启用 IPV6 解析必须启用 ECS IPv6 ${reset}:"            
            white "1. 启用 [默认选项]"
            white "2. 不启用"
            read -p "请选择: " ECSIP_IPV6_choose
            ECSIP_IPV6_choose=${ECSIP_IPV6_choose:-1}
            if [[ "$ECSIP_IPV6_choose" =~ ^[1-2]$ ]]; then
                break
            else
                red "无效的选项，请输入1或2"
            fi
        done
        if [[ "$ECSIP_IPV6_choose" == "1" ]]; then
            # clear
            # read -p "输入符合mosdns规则的ECS IPv6地址：（默认2408:8206:2560::1）" ECSIP_IPV6_num
            # ECSIP_IPV6_num=${ECSIP_IPV6_num:-2408:8206:2560::1}
            ECSIP_IPV6_num=$(curl -s https://ipv6.ddnspod.com)
            ECSIP_IP_show="启用 ECS IPv6"
        else
            # clear
            # read -p "输入符合mosdns规则的ECS IPv4地址：（默认123.118.5.30）" ECSIP_IPV4_num
            # ECSIP_IPV4_num="${ECSIP_IPV4_num:-123.118.5.30}"
            ECSIP_IPV4_num=$(curl -s https://ipv4.ddnspod.com)
            ECSIP_IP_show="启用 ECS IPv4"
        fi
    else
        ECSIP_IP_show="不启用 ECS IP解析"
    fi      
    # 选择是否开启阿里Doh
    while true; do
        clear
        white "请选择是否启用${yellow} 阿里云Doh ${reset}DNS 解析:"
        white "1. 启用阿里 Doh 解析"
        white "2. 不启用阿里 Doh 解析 [默认选项]"
        read -p "请选择: " ali_DOH_operation
        ali_DOH_operation=${ali_DOH_operation:-2}
        if [[ "$ali_DOH_operation" =~ ^[1-2]$ ]]; then
            break
        else
            red "无效的选项，请输入1或2"
        fi
    done
    if [[ "$ali_DOH_operation" == "1" ]]; then
        while true; do
        clear
        # 获取DOH解析地址
        white "${yellow}注意：\n下面账号仅需输入数字账号即可，多输会报错！！！${reset}"
        read -p "请输入您的阿里公共DNS会员账号（仅需数字即可，如 112233等 ）： " ali_DOH_num
        if [[ "$ali_DOH_num" =~ ^[0-9]+$ ]]; then
            break
        else
            red "请正确输入阿里公共DNS会员数字账号"
        fi
        done
        mosdns_alidoh_use="启用阿里 Doh 解析"
    elif [[ "$ali_DOH_operation" == "2" ]]; then
        clear
        read -p "输入国内DNS IPV4解析地址：端口[建议使用主路由DHCP下发的DNS地址，避免国内断网]（默认$private_lan.1）：" localport
        localport="${localport:-$private_lan.1}"
        mosdns_alidoh_use="不启用阿里 Doh 解析"
    fi
    # 选择节点类型
    while true; do
        clear
        white "请选择是否启用${yellow} DNS IVP6 ${reset}解析:"
        white "1. 不启用 IVP6解析"
        white "2. 启用 IVP6解析 [默认选项]"
        read -p "请选择: " mosdns_operation
        mosdns_operation=${mosdns_operation:-2}
        if [[ "$mosdns_operation" =~ ^[1-2]$ ]]; then
            break
        else
            red "无效的选项，请输入1或2"
        fi
    done
    if [[ "$mosdns_operation" == "2" ]]; then
        clear
        read -p "请输入您的 国内DNS V6地址： （默认dc00::1001）" local_ivp6
        local_ivp6="${localport:-dc00::1001}"
        mosdns_ipv6_use="启用 IVP6解析"
    elif [[ "$mosdns_operation" == "1" ]]; then
        mosdns_ipv6_use="不启用 IVP6解析"
    fi
    # 选择是否开启表外ADG
    while true; do
        clear
        white "请选择是否启用${yellow} 表外域名 AdguardHome ECS 缓存 ${reset}解析:"
        white "1. 启用"
        white "2. 不启用 [默认选项]"
        read -p "请选择: " mosdns_adg_ecs_choose
        mosdns_adg_ecs_choose=${mosdns_adg_ecs_choose:-2}
        if [[ "$mosdns_adg_ecs_choose" =~ ^[1-2]$ ]]; then
            break
        else
            red "无效的选项，请输入1或2"
        fi
    done    
    if [[ "$mosdns_adg_ecs_choose" == "1" ]]; then
        clear
        read -p "请输入您的 表外域名 AdguardHome ECS 缓存地址： （默认$private_lan.6）" mosdns_adg_ecs_newip
        mosdns_adg_ecs_newip="${mosdns_adg_ecs_newip:-$private_lan.6}"
        mosdns_adg_ecs_ip_use="启用表外域名 AdguardHome ECS 缓存"
    elif [[ "$mosdns_adg_ecs_choose" == "2" ]]; then
        mosdns_adg_ecs_ip_use="不启用表外域名 AdguardHome ECS 缓存"
    fi   

    clear
    white "您设定的参数："
    white "sing-box IPV4 入站：${yellow}${uiport}:${sbport}${reset}"
    white "是否启用 ECS IP：${yellow}${ECSIP_IP_show}${reset}"
    if [[ "$ECSIP_IPV6_choose" == "1" ]]; then    
        white "ECS  IPV6 地址：${yellow}${ECSIP_IPV6_num}${reset}"  
    else   
        white "ECS  IPV4 地址：${yellow}${ECSIP_IPV4_num}${reset}" 
    fi       
    if [[ "$ali_DOH_operation" == "1" ]]; then
        white "是否启用阿里 DOH 解析：${yellow}${mosdns_alidoh_use}${reset}"
        white "阿里 DOH 解析地址：${yellow}https://${ali_DOH_num}.alidns.com/dns-query${reset}"
    else
        white "是否启用阿里 DOH 解析：${yellow}${mosdns_alidoh_use}${reset}"
        white "国内DNS IPV4 解析地址：${yellow}${localport}${reset}"
    fi
    if [[ "$mosdns_operation" == "2" ]]; then
        white "IPV6 解析启用：${yellow}${mosdns_ipv6_use}${reset}"
        white "IPV6 解析地址：${yellow}${local_ivp6}${reset}"    
    else
        white "IPV6 解析启用：${yellow}${mosdns_ipv6_use}${reset}"
    fi
    if [[ "$mosdns_adg_ecs_choose" == "1" ]]; then
        white "表外域名 AdguardHome ECS 缓存：${yellow}${mosdns_adg_ecs_ip_use}${reset}"
        white "表外域名 AdguardHome ECS 缓存 IP 地址：${yellow}${mosdns_adg_ecs_newip}${reset}"    
    else
        white "表外域名 AdguardHome ECS 缓存：${yellow}${mosdns_adg_ecs_ip_use}${reset}" 
    fi
}
################################ 基础环境设置 ################################
basic_settings() {
    white "配置基础设置并安装依赖..."
    sleep 1
    apt-get update -y && apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || { red "环境更新失败！退出脚本"; exit 1; }
    green "环境更新成功"
    white "环境依赖安装开始..."
    apt install curl wget tar gawk sed cron unzip nano sudo vim sshfs net-tools nfs-common bind9-host p7zip-full p7zip-rar -y || { red "环境依赖安装失败！退出脚本"; exit 1; }
    green "mosdns依赖安装成功"
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
################################下载 mosdns################################
download_mosdns_o() {
    mosdns_latest_version=$(curl -sL https://api.github.com/repos/IrineSistiana/mosdns/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$mosdns_latest_version" ]; then
        red "无法获取最新Mosnds版本号,退出脚本"
        exit 1
    fi

    white "开始下载 $mosdns_latest_version"
    wget --quiet --show-progress https://github.com/IrineSistiana/mosdns/releases/download/${mosdns_latest_version}/mosdns-linux-amd64.zip || { red "下载失败！退出脚本"; exit 1; }
    
    white "开始安装MosDNS..."
    unzip mosdns-linux-amd64.zip -d /etc/mosdns
    cd /etc/mosdns
    chmod +x mosdns
    cp mosdns /usr/local/bin
    wget --quiet --show-progress -O /etc/systemd/system/mosdns.service https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/oupavoc/mosdns.service
    green "Mosdns下载并完成"
}
################################# 配置 mosdns ################################
configure_mosdns_o() {
    white "开始配置MosDNS规则..."
    mkdir /etc/mosdns/rule
    cd /etc/mosdns/rule
    wget --quiet --show-progress -O /etc/mosdns/rule/blocklist.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/oupavoc/mos_rule/blocklist.txt
    wget --quiet --show-progress -O /etc/mosdns/rule/localptr.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/oupavoc/mos_rule/localptr.txt
    wget --quiet --show-progress -O /etc/mosdns/rule/greylist.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/oupavoc/mos_rule/greylist.txt
    wget --quiet --show-progress -O /etc/mosdns/rule/whitelist.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/oupavoc/mos_rule/whitelist.txt
    wget --quiet --show-progress -O /etc/mosdns/rule/ddnslist.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/oupavoc/mos_rule/ddnslist.txt
    wget --quiet --show-progress -O /etc/mosdns/rule/hosts.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/oupavoc/mos_rule/hosts.txt
    wget --quiet --show-progress -O /etc/mosdns/rule/redirect.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/oupavoc/mos_rule/redirect.txt
    wget --quiet --show-progress -O /etc/mosdns/rule/adlist.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/oupavoc/mos_rule/adlist.txt
    green "所有规则文件修改操作已完成"
    white "开始配置MosDNS config文件..."
    configure_mosdns_v4_v6_add
    configure_ecsip
    configure_ali_doh
    configure_adg_ecs_use
    green "MosDNS config文件已配置完成"  

    white "开始配置定时更新规则与清理日志..."
    cd /etc/mosdns
    touch {geosite_cn,geoip_cn,geosite_geolocation_noncn,gfw}.txt
    wget --quiet --show-progress -O /etc/mosdns/mos_rule_update.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/oupavoc/mos_rule_update.sh
    chmod +x mos_rule_update.sh
    ./mos_rule_update.sh
    (crontab -l 2>/dev/null; echo "0 0 * * 0 sudo truncate -s 0 /etc/mosdns/mosdns.log && /etc/mosdns/mos_rule_update.sh") | crontab -
    green "定时更新规则与清理日志添加完成"

    white "设置mosdns开机自启动"
    systemctl enable mosdns --now
    green "mosdns开机启动完成"
}

################################ 配置Mosdns V4 \ V6 配置文件 ################################
configure_mosdns_v4_v6_add() {
    if [ -f /etc/mosdns/config.yaml ]; then
        cp /etc/mosdns/config.yaml /etc/mosdns/config-$(date +%Y%m%d).yaml.bak
        white "检测到原有配置文件，已备份为 config-$(date +%Y%m%d).yaml.bak"
    else
        white "配置文件不存在，新建配置文件"
    fi
    wget --quiet --show-progress -O /etc/mosdns/config.yaml https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/oupavoc/mosdns.yaml
    sed -i "s|- addr: 10.10.10.2:5353  # 远程DNS服务器地址ipv4（sing-box IP地址）|- addr: ${uiport}:${sbport}  # 远程DNS服务器地址ipv4（sing-box IP地址）|g" /etc/mosdns/config.yaml
    sed -i "s|- addr: tcp://10.10.10.2:5353  # TCP协议的远程DNS服务器地址ipv4（sing-box IP地址）|- addr: tcp://${uiport}:${sbport}  # TCP协议的远程DNS服务器地址ipv4（sing-box IP地址）|g" /etc/mosdns/config.yaml

    if [[ "$mosdns_operation" == "2" ]]; then
        sed -i "s|#- addr: local_ivp6  #  本地DNS服务器地址ipv6|- addr: ${local_ivp6}  #  本地DNS服务器地址ipv6|g" /etc/mosdns/config.yaml
        sed -i "s|#- addr: tcp://local_ivp6 # TCP协议的本地DNS服务器地址ipv6|- addr: tcp://${local_ivp6}  # TCP协议的本地DNS服务器地址ipv6|g" /etc/mosdns/config.yaml
        sed -i "s|- exec: prefer_ipv4  # ipv4优先|#- exec: prefer_ipv4  # ipv4优先|g" /etc/mosdns/config.yaml
        sed -i "s|concurrent: 2  # 本地DNS并发数，仅用V4改为2，V4&V6最大并发请求数为4|concurrent: 4  # 本地DNS并发数，仅用V4改为2，V4&V6最大并发请求数为4|g" /etc/mosdns/config.yaml
    fi
}
################################ 开启 ECS IP ################################
configure_ecsip() {
    if [[ "$ECSIP_IPV6_choose" == "1" ]]; then
        sed -i "s|preset: 123.118.5.30|preset: ${ECSIP_IPV6_num}|g" /etc/mosdns/config.yaml
        sed -i "s/mask4: 24/mask6: 48/g" /etc/mosdns/config.yaml
    else
        sed -i "s|preset: 123.118.5.30|preset: ${ECSIP_IPV4_num}|g" /etc/mosdns/config.yaml
    fi
}
################################ 开启阿里 DOH ################################
configure_ali_doh() {
    if [[ "$ali_DOH_operation" == "1" ]]; then
        sed -i "s|- addr: 223.5.5.5:53  # 本地DNS服务器地址ipv4|- addr: https://${ali_DOH_num}.alidns.com/dns-query  # 本地DNS服务器地址ipv4|g" /etc/mosdns/config.yaml
        sed -i "s|- addr: tcp://223.5.5.5:53  # TCP协议的本地DNS服务器地址ipv4|#- addr: tcp://223.5.5.5:53  # TCP协议的本地DNS服务器地址ipv4|g" /etc/mosdns/config.yaml
        sed -i "s|# dial_addr: 223.5.5.5|dial_addr: 223.5.5.5|g" /etc/mosdns/config.yaml
    else
        sed -i "s|- addr: 223.5.5.5:53  # 本地DNS服务器地址ipv4|- addr: ${localport}  # 本地DNS服务器地址ipv4|g" /etc/mosdns/config.yaml
        sed -i "s|- addr: tcp://223.5.5.5:53  # TCP协议的本地DNS服务器地址ipv4|- addr: tcp://${localport}  # TCP协议的本地DNS服务器地址ipv4|g" /etc/mosdns/config.yaml
    fi
}
################################ 开启表外域名 AdguardHome ECS 缓存 ################################
configure_adg_ecs_use() {
    if [[ "$mosdns_adg_ecs_choose" == "1" ]]; then
        sed -i "s|- addr: tls://8.8.8.8:853|- addr: ${mosdns_adg_ecs_newip}|g" /etc/mosdns/config.yaml
        sed -i '/- exec: \$ecs_local/ s/^/#/' /etc/mosdns/config.yaml
    fi
}

################################ 更新Mosdns ################################
update_mosdns() {
    FILE="/usr/local/bin/mosdns"
    if [ ! -f "$FILE" ]; then
        red "未检测到 mosdns 程序文件，请检查mosdns是否安装"
        rm -rf /mnt/mosdns.sh    #delete  
        exit 1
    else
        white "已安装 mosdns ，开始备份原程序..."
        
        BACKUP_FILE="/usr/local/bin/mosdns.bak"
        cp "$FILE" "$BACKUP_FILE"
        white "已备份 mosdns 程序文件至 ${yellow}$BACKUP_FILE${reset}\n当前系统版本号为："
        mosdns version
        
        white "\n查询最新版本号，请稍候..."
        LATEST_VERSION=$(curl -s https://github.com/IrineSistiana/mosdns/releases | grep -oP '\/IrineSistiana\/mosdns\/releases\/tag\/\K[^/"]+' | head -n 1)
        
        if [ -z "$LATEST_VERSION" ]; then
            red "未能获取到最新版本号，请检查网络或网址是否有效"
            rm -rf /mnt/mosdns.sh    #delete  
            exit 1
        fi
        
        white "最新版本号为: ${yellow}$LATEST_VERSION${reset}"
    fi

    mosdns_host="https://github.com/IrineSistiana/mosdns/releases/download/$LATEST_VERSION/mosdns-linux-amd64.zip"

    white "开始下载 mosdns ${yellow}$LATEST_VERSION${reset}"
    wget -q --show-progress "${mosdns_host}" || { red "下载失败！退出脚本"; exit 1; }

    systemctl stop mosdns

    white "\n开始更新MosDNS..."
    unzip -o mosdns-linux-amd64.zip -d /mnt/mosdns
    chmod +x /mnt/mosdns
    cp /mnt/mosdns/mosdns /usr/local/bin
    rm -rf mosdns-linux-amd64.zip
    rm -rf /mnt/mosdns

    systemctl daemon-reload && systemctl start mosdns
    rm -rf /mnt/mosdns.sh    #delete  
    sleep 1
    echo -e "\n"
    echo "=================================================================="
    echo -e "\t\t\tMosdns 升级完成"
    echo -e "\t"
    echo -e "Mosdns 原程序文件已生成备份\n路径为: ${yellow}$BACKUP_FILE${reset}\n如配置出错需恢复，请自行恢复"
    echo -e "更新后版本号为："
    mosdns version
    echo -e "温馨提示:\n本脚本仅在 ubuntu25.04 环境下测试，其他环境未经验证，正在\n查询程序运行状态，如出现\e[1m\e[32m active (running)\e[0m，程序已启动成功"
    echo "=================================================================="
    sleep 2
    systemctl status mosdns
}
################################ 卸载Mosdns ################################
del_mosdns() {
    white "停止MosDNS服务并删除相关文件..."
    systemctl stop mosdns || exit 1
    systemctl disable mosdns || exit 1
    rm /etc/systemd/system/mosdns.service || exit 1
    if [[ -d "/cus" ]]; then
        rm -rf /cus || exit 1
    fi    
    if [[ -d "/etc/mosdns" ]]; then
        rm -rf /etc/mosdns || exit 1
        (crontab -l 2>/dev/null | grep -v 'truncate -s 0 /etc/mosdns/mosdns.log && /etc/mosdns/mos_rule_update.sh') | crontab - || exit 1
    fi
    if [[ -f "/usr/local/bin/mosdns" ]]; then
        rm -r /usr/local/bin/mosdns || exit 1
    fi
    green "卸载Mosdns已完成"
}

################################ Mosdns安装结束 ################################
install_complete_o() {
    systemctl restart mosdns
    sudo rm -r /mnt/mosdns || exit 1
    rm -rf /mnt/mosdns.sh    #delete       
echo "=================================================================="
echo -e "\t\tMosdns Οὐρανός版 安装完成"
echo -e "\n"
echo -e "Mosdns运行目录为${yellow}/etc/mosdns${reset}"
echo -e "温馨提示:\n本脚本仅在 ubuntu25.04 环境下测试，其他环境未经验证，正在\n查询程序运行状态，如出现\e[1m\e[32m active (running)\e[0m，程序已启动成功。"
echo "=================================================================="
sleep 2
systemctl status mosdns
}
 
##################################### 阿里自动更新公共DNS IP 绑定 ########################################
alidns_update_ip() {
    clear
    white "${yellow}温馨提示：\n本脚本需先行在Ali公共DNS处创建IP绑定，获取IP更新链接后方可使用！！！${reset}\n"
    white "${yellow}温馨提示：\n本脚本需先行在Ali公共DNS处创建IP绑定，获取IP更新链接后方可使用！！！${reset}\n"
    white "${yellow}温馨提示：\n本脚本需先行在Ali公共DNS处创建IP绑定，获取IP更新链接后方可使用！！！${reset}\n"

    read -p "请输入完整的IP更新链接（如：https://client.ip.v4.hichina.com/u/client—number/api-key）: " alidns_update_url

    while true; do
        white "请选择更新的时间单位："
        white "1. ${yellow}分${reset}"
        white "2. ${yellow}小时${reset}"
        white "3. ${yellow}天${reset}"
        read -p "请选择（默认1）: " alidns_update_time_interval_type
        alidns_update_time_interval_type="${alidns_update_time_interval_type:-1}"
        if [[ $alidns_update_time_interval_type =~ ^[1-3]$ ]]; then
            break
        else
            red "输入选定的时间单位版本数字不正确，请重新输入"
        fi
    done
        while true; do
        read -p "请输入更新时间间隔数字[默认为5]: " alidns_update_time_interval_num
        alidns_update_time_interval_num="${alidns_update_time_interval_num:-5}"
        if [[ $alidns_update_time_interval_num =~ ^([1-9]|[1-5][0-9]|60)$ ]]; then
            break
        else
            red "输入数字不正确，需在1-60以内，请重新输入"
        fi
    done
    case $alidns_update_time_interval_type in
        1) alidns_update_time_interval="*/${alidns_update_time_interval_num} * * * *" ;;
        2) alidns_update_time_interval="0 */${alidns_update_time_interval_num} * * *" ;;
        3) alidns_update_time_interval="0 0 */${alidns_update_time_interval_num} * *" ;;
    esac

    if [ ! -d /opt/alidns_ip_date/log ]; then
        mkdir -p /opt/alidns_ip_date/log
    fi

    if [ ! -f /opt/alidns_ip_date/ip.txt ]; then
        touch /opt/alidns_ip_date/ip.txt
    fi

    if [ ! -f /opt/alidns_ip_date/log/log.txt ]; then
        touch /opt/alidns_ip_date/log/log.txt
    fi

    if ! command -v jq &> /dev/null; then
        white "jq 未安装，安装 jq ..."
        apt install jq -y
    fi

    wget --quiet --show-progress -O /opt/alidns_ip_date/alidns_ip_update.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/alidns_ip_update.sh

    sed -i "s|https://www.baidu.com|${alidns_update_url}|g" /opt/alidns_ip_date/alidns_ip_update.sh

    chmod +x /opt/alidns_ip_date/alidns_ip_update.sh

    green "脚本已创建完成"

    (crontab -l 2>/dev/null; echo "${alidns_update_time_interval} /opt/alidns_ip_date/alidns_ip_update.sh") | crontab -

    green "定时任务已设置完成"

    echo "=================================================================="
    echo -e "\t\t阿里公共DNS IP变动更新脚本配置完毕"
    echo -e "\n"
    echo -e "脚本运行目录\n${yellow}/opt/alidns_ip_date${reset}"
    echo -e "更新日志目录\n${yellow}/opt/alidns_ip_date/log${reset}"    
    echo -e "温馨提示:\n本脚本仅在 ubuntu25.04 环境下测试，其他环境未经验证"
    echo "=================================================================="
}

################################用户自定义设置-- PH ################################
mosdns_customize_ph() {
    clear
    white "\n自定义设置（以下设置可直接回车使用默认值）"
    read -p "输入sing-box IP地址：（默认$private_lan.2）：" uiport
    uiport="${uiport:-$private_lan.2}"
    clear
    read -p "输入sing-box 服务 FakeIP 监听端口（默认6115端口）：" sbport
    sbport="${sbport:-6115}"
    clear
    read -p "输入sing-box sock5入站地址：（默认$private_lan.2:7890）：" sb_sock
    sb_sock="${sb_sock:-$private_lan.2:7890}"   
    clear 
    read -p "输入本地运营商 DNS 地址：（默认202.106.0.20）：" isp_dns
    isp_dns="${isp_dns:-202.106.0.20}"
    clear
    while true; do
        white "请选择是否启用${yellow} IPv6 ${reset}:"       
        white "1. 启用 [默认选项]"
        white "2. 不启用"
        read -p "请选择: " ECSIP_IPV6_choose
        ECSIP_IPV6_choose=${ECSIP_IPV6_choose:-1}
        if [[ "$ECSIP_IPV6_choose" =~ ^[1-2]$ ]]; then
            break
        else
            red "无效的选项，请输入1或2"
        fi
    done
    if [[ "$ECSIP_IPV6_choose" == "1" ]]; then
        # clear
        # read -p "输入本地 IPv6 公网地址：（默认2408:8206:2560::1）" ECSIP_num
        # ECSIP_num=${ECSIP_num:-2408:8206:2560::1}
        # ECSIP_num=$(curl -6 -s http://v6.66666.host:66/ip | grep -oP '(?<=当前IP：)[a-fA-F0-9:]+')
        ECSIP_num=$(curl -s https://ipv6.ddnspod.com)
        ECSIP_IP_show="启用 IPv6"
    else
        # clear
        # read -p "输入本地 IPv4 公网地址：（默认123.118.5.30）" ECSIP_num
        # ECSIP_num="${ECSIP_num:-123.118.5.30}"
        ECSIP_num=$(curl -s https://ipv4.ddnspod.com)
        ECSIP_IP_show="启用 IPv4"
    fi
    clear
    while true; do
        white "请选择是否启用${yellow} 阿里公共DNS私有账户解析 ${reset}:"       
        white "1. 启用 [默认选项]"
        white "2. 不启用"
        read -p "请选择: " ali_private_chose
        ali_private_chose=${ali_private_chose:-1}
        if [[ "$ali_private_chose" =~ ^[1-2]$ ]]; then
            break
        else
            red "无效的选项，请输入1或2"
        fi
    done
    if [[ "$ali_private_chose" == "1" ]]; then
        clear
        read -p "输入阿里account_id：" ali_private_account_id
        clear
        read -p "输入阿里access_key_id：" ali_private_access_key_id
        clear
        read -p "输入阿里access_key_secret：" ali_private_access_key_secret
        ali_private_chose_show="启用阿里公共DNS私有账户解析"
    else
        ali_private_chose_show="不启用阿里公共DNS私有账户解析"
    fi
    clear
    white "您设定的参数："
    white "sing-box Fake IP 监听入站：${yellow}${uiport}:${sbport}${reset}"
    white "sing-box sock5入站地址：${yellow}${sb_sock}${reset}"
    white "本地运营商 DNS 地址：${yellow}${isp_dns}${reset}"
    white "是否启用 IPv6 ：${yellow}${ECSIP_IP_show}${reset}"
    white "是否启用阿里公共DNS私有账户解析：${yellow}${ali_private_chose_show}${reset}"
}

################################下载 mosdns -- PH ################################
download_mosdns_ph() {
    [ ! -d "/cus" ] && mkdir -p /cus/bin 
    cd /cus
    white "开始下载 ${mosdns_latest_version_PH}"
    wget --quiet --show-progress https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/PH/${mosdns_latest_version_PH}.zip  || { red "下载失败！退出脚本"; exit 1; }
    white "开始安装MosDNS..."
    7z x /cus/${mosdns_latest_version_PH}.zip -o/cus
    cd /cus/mosdns
    chmod +x mosdns
    cp mosdns /cus/bin
    wget --quiet --show-progress -O /etc/systemd/system/mosdns.service https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/PH/mosdns.service
    if [[ "$ali_private_chose" == "1" ]]; then
        wget --quiet --show-progress -O /cus/mosdns/sub_config/forward_local.yaml https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/PH/forward_local.yaml
    fi
    green "Mosdns下载并完成"
}
################################# 配置 mosdns -- PH ################################
configure_mosdns_ph() {
    sed -i 's|- addr: "udp://127.0.0.1:7874"|- addr: "udp://'"${uiport}:${sbport}"'"|g' /cus/mosdns/sub_config/forward_1.yaml
    sed -i 's|- addr: "202.102.128.68"|- addr: "'"${isp_dns}"'"|g' /cus/mosdns/sub_config/forward_local.yaml

    if [[ "$ali_private_chose" == "1" ]]; then    
        sed -i 's|account_id: "111111"|account_id: "'"${ali_private_account_id}"'"|g' /cus/mosdns/sub_config/forward_local.yaml
        sed -i 's|access_key_id: "222222"|access_key_id: "'"${ali_private_access_key_id}"'"|g' /cus/mosdns/sub_config/forward_local.yaml
        sed -i 's|access_key_secret: "333333"|access_key_secret: "'"${ali_private_access_key_secret}"'"|g' /cus/mosdns/sub_config/forward_local.yaml
    fi

    sed -i 's|socks5: "127.0.0.1:7891"|socks5: "'"${sb_sock}"'"|g' /cus/mosdns/sub_config/forward_nocn_ecs.yaml
    sed -i 's|- exec: ecs 2408:8214:213::1  #使用自己的公网IP，无须更新|- exec: ecs '"${ECSIP_num}"'  #使用自己的公网IP，无须更新|g' /cus/mosdns/sub_config/forward_nocn_ecs.yaml
    sed -i 's|socks5: "127.0.0.1:7891"|socks5: "'"${sb_sock}"'"|g' /cus/mosdns/sub_config/forward_nocn.yaml

    sed -i 's|socks5: "127.0.0.1:7891"|socks5: "'"${sb_sock}"'"|g' /cus/mosdns/sub_config/rule_set.yaml
    sed -i 's|socks5: "127.0.0.1:7891"|socks5: "'"${sb_sock}"'"|g' /cus/mosdns/sub_config/adguard.yaml

    green "Mosdns配置修订完成"
    
    white "设置mosdns开机自启动"
    systemctl enable mosdns --now
    green "mosdns开机启动完成"
}
################################ Mosdns安装结束 -- PH  ################################
install_complete_ph() {
    systemctl restart mosdns
    rm -rf /mnt/mosdns.sh    #delete       
echo "=================================================================="
echo -e "\t\tMosdns ${mosdns_latest_version_PH} 安装完成"
echo -e "\n"
echo -e "Mosdns运行目录为${yellow}/cus/mosdns${reset}"
echo -e "温馨提示:\n本脚本仅在 ubuntu25.04 环境下测试，其他环境未经验证，正在\n查询程序运行状态，如出现\e[1m\e[32m active (running)\e[0m，程序已启动成功。"
echo "=================================================================="
sleep 2
systemctl status mosdns
}
################################下载 mosdns -- PH ################################
update_download_mosdns_ph() {
    white "开始下载 ${mosdns_latest_version_PH}"
    cd /mnt
    wget --quiet --show-progress https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/PH/${mosdns_latest_version_PH}.zip  || { red "下载失败！退出脚本"; exit 1; }
    wget --quiet --show-progress https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/PH/mosdns.service
    if [[ "$ali_private_chose" == "1" ]]; then
        wget --quiet --show-progress https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns/PH/forward_local.yaml
    fi

    del_mosdns

    white "开始安装MosDNS..."
    [ ! -d "/cus" ] && mkdir -p /cus/bin
    7z x /mnt/${mosdns_latest_version_PH}.zip -o/cus
    cd /cus/mosdns
    chmod +x mosdns
    cp mosdns /cus/bin
    mv /mnt/mosdns.service /etc/systemd/system/mosdns.service
    mv /mnt/forward_local.yaml /cus/mosdns/sub_config/forward_local.yaml
    green "Mosdns下载并完成"
}
################################ MosDNS选择 ################################
mosdns_choose() {
    clear
    echo "=================================================================="
    echo -e "\t\tMosDNS 相关脚本 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo "请选择要执行的服务："
    echo "=================================================================="
    white "1. 安装Mosdns -- ${yellow}Οὐρανός版${reset} （最新配置:${yellow}${mosdns_latest_version_oupavoc}${reset}）"
    white "2. 安装Mosdns -- ${yellow}PH版${reset} （最新配置:${yellow}${mosdns_latest_version_PH}${reset}）"
    echo "3. 更新Mosdns -- Οὐρανός版"
    white "4. 更新Mosdns -- ${yellow}${mosdns_latest_version_PH}${reset}"    
    echo "5. 卸载Mosdns"
    # echo "5. 阿里公共DNS定时更新绑定IP脚本"

    echo -e "\t"
    echo "-. 返回上级菜单"          
    echo "0. 退出脚本"        
    read -p "请选择服务: " choice
    case $choice in
        1)
            white "安装Mosdns -- ${yellow}Οὐρανός版${reset} （最新配置:${yellow}${mosdns_latest_version_oupavoc}${reset}）"
            [ ! -d "/mnt/mosdns" ] && mkdir /mnt/mosdns
            cd /mnt/mosdns
            mosdns_customize_o || exit 1
            basic_settings || exit 1
            download_mosdns_o || exit 1
            configure_mosdns_o || exit 1
            install_complete_o
            ;;
        2)
            white "安装Mosdns -- ${yellow}PH版${reset} （最新配置:${yellow}${mosdns_latest_version_PH}${reset}）"
            mosdns_customize_ph || exit 1
            basic_settings || exit 1
            download_mosdns_ph || exit 1
            configure_mosdns_ph || exit 1
            install_complete_ph || exit 1
            ;;
        3)
            white "更新Mosdns -- Οὐρανός版"
            update_mosdns || exit 1
            ;; 
        4)
            white "更新Mosdns -- ${yellow}${mosdns_latest_version_PH}版${reset}"
            mosdns_customize_ph || exit 1
            basic_settings || exit 1
            update_download_mosdns_ph || exit 1
            configure_mosdns_ph || exit 1
            install_complete_ph || exit 1
            rm -rf /mnt/mosdns.sh    #delete                
            ;;                          
        5)
            white "卸载Mosdns"
            del_mosdns || exit 1
            rm -rf /mnt/mosdns.sh    #delete                
            ;;
        6)
            white "创建阿里公共DNS定时更新绑定IP脚本"
            alidns_update_ip
            ;;
            
        0)
            red "退出脚本，感谢使用."
            rm -rf /mnt/mosdns.sh    #delete             
            ;;
        -)
            white "脚本切换中，请等待..."
            rm -rf /mnt/mosdns.sh    #delete       
            wget --quiet --show-progress -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
            ;;                            
        *)
            white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            mosdns_choose
            ;;
    esac
}

################################ 主程序 ################################
mosdns_choose