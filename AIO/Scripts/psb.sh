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

private_ip=$(ip route get 1.2.3.4 | awk '{print $7}' | head -1)
private_lan=$(echo "$private_ip" | cut -d'.' -f1-3)

################################ 基础环境设置 ################################
basic_settings() {
    white "配置基础设置并安装依赖..."
    sleep 1
    apt-get update -y && apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || { red "环境更新失败！退出脚本"; exit 1; }
    green "环境更新成功"
    white "环境依赖安装开始..."
    apt install curl git build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64 jq p7zip-full p7zip-rar dos2unix -y || { red "环境依赖安装失败！退出脚本"; exit 1; }
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
    lanip_segment=$private_lan.0/24
}

################################ VPS节点设置 ################################
custom_VPS_settings() {
    while true; do
        clear
        white "\n请选择是否需要脚本添加节点:"
        white "1. 脚本添加节点 [默认选项]"
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
            white "3. 其他节点，自行手动配置"
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

            clear
            white "您设定的参数："     
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

            clear
            white "您设定的参数："
            white "节点名称：${yellow}${hy2_pass_tag}${reset}"
            white "VPS的IP：${yellow}${hy2_pass_server_ip}${reset}"
            white "入站端口：${yellow}${hy2_pass_port}${reset}"
            white "上行带宽：${yellow}${hy2_pass_up_mbps}${reset}"
            white "下行带宽：${yellow}${hy2_pass_down_mbps}${reset}"
            white "密码：${yellow}${hy2_pass_password}${reset}"
            white "生成证书的域名：${yellow}${hy2_pass_domain}${reset}\n"
            sleep 1
        elif [[ "$node_operation" == "3" ]]; then
            white "${yellow}您的节点不在脚本支持配置范围，请脚本运行完成后自行配置出站节点...${reset}"
        fi
    else
        white "${yellow}用户选择自行调整配置文件...${reset}"
    fi
}
################################sing-box安装结束################################
install_sing_box_over() {
    if [[ "$node_basic_choose" == "1" && "$node_operation" != "3" ]]; then
        systemctl stop sing-box && systemctl daemon-reload && systemctl restart sing-box
        rm -rf /mnt/psb.sh    #delete       
        local_ip=$(hostname -I | awk '{print $1}')
        echo "=================================================================="
        echo -e "\t\t\tSing-Box ${yellow}${intall_mode_Classification}${reset} 安装完毕"
        echo -e "\n"
        echo -e "singbox运行目录为${yellow}/usr/loacl/etc/sing-box${reset}"
        echo -e "singbox WebUI地址:${yellow}http://$local_ip:9090${reset}"
        echo -e "温馨提示:\n本脚本仅在 ubuntu25.04 环境下测试，其他环境未经验证，已查\n询程序运行状态，如出现\e[1m\e[32m active (running)\e[0m，程序已启动成功"
        echo "=================================================================="
        systemctl status sing-box
    else
        systemctl stop sing-box && systemctl daemon-reload
        rm -rf /mnt/psb.sh    #delete       
        local_ip=$(hostname -I | awk '{print $1}')
        echo "=================================================================="
        echo -e "\t\t\tSing-Box ${yellow}${intall_mode_Classification}${reset} 安装完毕"
        echo -e "\n"
        echo -e "singbox运行目录为${yellow}/usr/loacl/etc/sing-box${reset}"
        echo -e "singbox WebUI地址:${yellow}http://$local_ip:9090${reset}"
        echo -e "温馨提示:\n本脚本仅在 ubuntu25.04 环境下测试，其他环境未经验证，目前程序未\n运行，请自行修改运行目录下配置文件后运行\e[1m\e[33msystemctl restart sing-box\e[0m\n命令运行程序。"
        echo "=================================================================="
    fi
}

##############################################################################
####                                                                      ####
####                             Οὐρανός版                                ####
####                                                                      ####
##############################################################################

################################ 用户自定义设置 ################################
custom_settings_o() {
    interfaces=$(ip -o link show | awk -F': ' '{print $2}')
    # 输出物理网卡名称
    for interface in $interfaces; do
        # 检查是否为物理网卡（不包含虚拟、回环等），并排除@符号及其后面的内容
        if [[ $interface =~ ^(en|eth).* ]]; then
            interface_name=$(echo "$interface" | awk -F'@' '{print $1}')  # 去掉@符号及其后面的内容
            echo "您当前的网卡是：$interface_name"
            valid_interfaces+=("$interface_name")  # 存储有效的网卡名称
        fi
    done
    while true; do
        # 提示用户选择
        read -p "脚本自行检测的是否是您要的网卡？( y [默认选项] /n): " confirm_interface
        confirm_interface=${confirm_interface:-y}
        if [[ "$confirm_interface" =~ ^[yn]$ ]]; then
            break
        else
            red "无效的选项，请输入y或n"
        fi
    done
    if [ "$confirm_interface" = "y" ]; then
        selected_interface="$interface_name"
        white "您选择的网卡是: ${yellow}$selected_interface${reset}"
    elif [ "$confirm_interface" = "n" ]; then
        read -p "请自行输入您的网卡名称: " selected_interface
        white "您输入的网卡名称是: ${yellow}$selected_interface${reset}"
    fi
    
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
    custom_VPS_settings
}

################################安装 Sing-Box -- Οὐρανός版################################
install_singbox_o() {
    ARCH_RAW=$(uname -m)
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
    selected_version=v1.10.7
    mkdir -p /mnt/singbox /usr/local/etc/singbox
    cd /mnt/singbox
    if [[ "$singbox_install_mode_choose" == "1" ]]; then 
        white "开始编译 Sing-Box $selected_version ..."
        rm -rf /root/go/bin/*
        rm -rf /mnt/singbox/go/bin/*
        go_version=$(curl -s https://go.dev/VERSION?m=text | head -1)
        curl -L "https://go.dev/dl/${go_version}.linux-${ARCH}.tar.gz" -o "${go_version}.linux-${ARCH}.tar.gz"
        sudo tar -C /usr/local -xzf "${go_version}.linux-${ARCH}.tar.gz"
        echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/golang.sh
        source /etc/profile.d/golang.sh
        go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@$selected_version
        white "检测编译结果...."
        if ! go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@$selected_version; then
            red "Sing-Box 编译失败！退出脚本"
            rm -rf /mnt/psb.sh    #delete    
            exit 1
        fi
        white "编译完成，准备提取版本信息..."

        # 提取编译库地址和版本号
        singbox_module="github.com/sagernet/sing-box@$selected_version"
        compiled_repo=${singbox_module%@*}
        compiled_version=$(go list -m $singbox_module 2>/dev/null | awk '{print $2}')

        # 输出到文件
        echo -e "编译地址：$compiled_repo\n版本号码：$compiled_version" > /usr/local/etc/singbox/singbox_build_info.txt
        white "编译信息已输出到 /mnt/singbox_build_info.txt"
        cp $(go env GOPATH)/bin/sing-box /usr/local/bin/
        white "Sing-Box 安装完成"
    elif [[ "$singbox_install_mode_choose" == "2" ]]; then
        white "下载Sing-Box $selected_version ..."
        selected_version=1.10.7
        wget --quiet --show-progress -O /mnt/singbox/singbox.tar.gz https://github.com/SagerNet/sing-box/releases/download/v${selected_version}/sing-box-${selected_version}-linux-${ARCH}.tar.gz
        if [ ! -f "/mnt/singbox/singbox.tar.gz" ]; then
            red "下载版sing-box文件失败，请检查网络，保持网络畅通后重新运行脚本"
            rm -rf /mnt/psb.sh    #delete
            rm -rf /mnt/singbox
            exit 1
        fi
        tar -C /mnt/singbox -xzf /mnt/singbox/singbox.tar.gz
        chown root:root /mnt/singbox/sing-box-${selected_version}-linux-${ARCH}/sing-box
        mv /mnt/singbox/sing-box-${selected_version}-linux-${ARCH}/sing-box /usr/local/bin 
        if [ ! -f "/usr/local/bin/sing-box" ]; then
            red "文件移动失败，请检查用户权限"
            rm -rf /mnt/psb.sh    #delete
            rm -rf /mnt/singbox
            exit 1
        fi
        white "Sing-Box 安装完成"
    fi

    wget --quiet --show-progress -O /etc/systemd/system/sing-box.service https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO//Configs/singbox/oupavoc/sing-box.service
    if [ ! -f "/etc/systemd/system/sing-box.service" ]; then
        red "错误：启动文件 /etc/systemd/system/sing-box.service 不存在"
        red "请检查网络可正常访问github后运行脚本"
        rm -rf /mnt/psb.sh    #delete
        exit 1
    fi  
}
################################写入配置文件################################
install_config_o() {
    if [[ "$node_basic_choose" == "1" ]]; then
        if [[ "$node_operation" == "1" ]]; then
            wget --quiet --show-progress -O /usr/local/etc/singbox/config.json https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/singbox/oupavoc/config_vless.json
            singbox_config_file="/usr/local/etc/singbox/config.json"
            if [ ! -f "$singbox_config_file" ]; then
                red "错误：配置文件 $singbox_config_file 不存在"
                red "请检查网络可正常访问github后运行脚本"
                rm -rf /mnt/psb.sh    #delete
                exit 1
            fi
            sed -i "s|vless_tag|${vless_tag}|g" /usr/local/etc/singbox/config.json
            sed -i "s|vless_uuid|${vless_uuid}|g" /usr/local/etc/singbox/config.json
            sed -i "s|vless_server_ip|${vless_server_ip}|g" /usr/local/etc/singbox/config.json
            sed -i "s|vless_port|${vless_port}|g" /usr/local/etc/singbox/config.json
            sed -i "s|vless_domain|${vless_domain}|g" /usr/local/etc/singbox/config.json
            sed -i "s|vless_public_key|${vless_public_key}|g" /usr/local/etc/singbox/config.json
            sed -i "s|vless_short_id|${vless_short_id}|g" /usr/local/etc/singbox/config.json
            sed -i "s|vless_up_mbps|${vless_up_mbps}|g" /usr/local/etc/singbox/config.json
            sed -i "s|vless_down_mbps|${vless_down_mbps}|g" /usr/local/etc/singbox/config.json
        elif [[ "$node_operation" == "2" ]]; then
            wget --quiet --show-progress -O /usr/local/etc/singbox/config.json https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/singbox/oupavoc/config_hy2.json
            singbox_config_file="/usr/local/etc/singbox/config.json"
            if [ ! -f "$singbox_config_file" ]; then
                red "错误：配置文件 $singbox_config_file 不存在"
                red "请检查网络可正常访问github后运行脚本"
                rm -rf /mnt/psb.sh    #delete
                exit 1
            fi            
            sed -i "s|hy2_pass_tag|${hy2_pass_tag}|g" /usr/local/etc/singbox/config.json
            sed -i "s|hy2_pass_server_ip|${hy2_pass_server_ip}|g" /usr/local/etc/singbox/config.json
            sed -i "s|hy2_pass_port|${hy2_pass_port}|g" /usr/local/etc/singbox/config.json
            sed -i "s|hy2_pass_up_mbps|${hy2_pass_up_mbps}|g" /usr/local/etc/singbox/config.json
            sed -i "s|hy2_pass_down_mbps|${hy2_pass_down_mbps}|g" /usr/local/etc/singbox/config.json
            sed -i "s|hy2_pass_password|${hy2_pass_password}|g" /usr/local/etc/singbox/config.json
            sed -i "s|hy2_pass_domain|${hy2_pass_domain}|g" /usr/local/etc/singbox/config.json
        fi
    else
        wget --quiet --show-progress -O /usr/local/etc/singbox/config.json https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/singbox/oupavoc/singbox.json
        singbox_config_file="/usr/local/etc/singbox/config.json"
        if [ ! -f "$singbox_config_file" ]; then
            red "错误：配置文件 $singbox_config_file 不存在"
            red "请检查网络可正常访问github后运行脚本"
            rm -rf /mnt/psb.sh    #delete
            exit 1
        fi    
    fi
}
################################安装tproxy################################
install_tproxy_o() {
    white "开始创建nftables tproxy转发..."
    apt install nftables -y
    if [ ! -f "/etc/systemd/system/sing-box-router.service" ]; then
        white "未找到 sing-box-router 服务文件，开始创建...." 
        wget --quiet --show-progress -O /etc/systemd/system/sing-box-router.service https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/singbox/oupavoc/sing-box-router.service
        green "sing-box-router 服务创建完成"
    else

        white "警告：sing-box-router 服务文件已存在，重新创建...."
        rm -rf /etc/systemd/system/sing-box-router.service
        wget --quiet --show-progress -O /etc/systemd/system/sing-box-router.service https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/singbox/oupavoc/sing-box-router.service
        green "sing-box-router 服务重新创建完成"
    fi
    if [ ! -f "/etc/systemd/system/sing-box-router.service" ]; then
        red "错误：启动文件 /etc/systemd/system/sing-box-router.service 不存在"
        red "请检查网络可正常访问github后运行脚本"
        rm -rf /mnt/psb.sh    #delete
        exit 1
    fi  

    white "开始写入nftables tproxy规则..."
    rm -rf /etc/nftables.conf
    wget --quiet --show-progress -O /etc/nftables.conf https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/singbox/oupavoc/nftables.conf
    if [ ! -f "/etc/nftables.conf" ]; then
        red "错误：启动文件 /etc/nftables.conf 不存在"
        red "请检查网络可正常访问github后运行脚本"
        rm -rf /mnt/psb.sh    #delete
        exit 1
    fi 

    sed -i "s|10.10.10.0/24|${lanip_segment}|g" /etc/nftables.conf
    sed -i "s|ens18|${selected_interface}|g" /etc/nftables.conf
    dos2unix /etc/nftables.conf
    green "nftables规则写入完成"

    nft flush ruleset
    nft -f /etc/nftables.conf
    systemctl enable --now nftables
    green "Nftables tproxy转发创建完成"

    white "开始启动sing-box..."
    systemctl enable --now sing-box-router
    if [[ "$node_basic_choose" == "1" && "$node_operation" != "3" ]]; then
        systemctl enable --now sing-box
    else
        systemctl enable sing-box
    fi  
    green "Sing-box启动已完成"
}

################################回家配置脚本 -- O ################################
install_home_o() {
    sleep 1
    white "hysteria2 回家 自签证书"
    if [[ -z "${hy2home_tag}" ]] || [[ -z "${hyport}" ]] || [[ -z "${hy2_password}" ]]; then
        while [[ -z "${hy2home_domain}" ]]; do
            read -p "请输入回家的DDNS域名: " hy2home_domain
            if [[ $hy2home_domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                break
            else
                red "域名格式不正确，请重新输入"
            fi
        done
        # 获取节点名称
        while [[ -z "${hy2home_tag}" ]]; do
            read -p "请输入您的 HY2 节点名称 (默认名称：hy2-in): " hy2home_tag
            hy2home_tag=${hy2home_tag:-hy2-in}
        done
        
        # 获取端口号
        while [[ -z "${hyport}" ]]; do
            read -p "请输入您的 HY2 回家节点的入站端口： " hyport
            if [[ ! "$hyport" =~ ^[0-9]{1,5}$ ]] || [[ "$hyport" -lt 1 ]] || [[ "$hyport" -gt 65535 ]]; then
                red "无效的端口号，请输入 1-65535 之间的数字"
                hyport=""
            fi
        done
        while [[ -z "${hy2_password}" ]]; do
        read -p "请输入您的 HY2 节点的密码: " hy2_password
        if [[ -z "${hy2_password}" ]]; then
            red "密码不能为空，请重新输入"
        fi
        done
    fi
    white "hysteria2 回家 自签证书"
    white "开始创建证书存放目录"
    mkdir -p /usr/local/etc/singbox/hysteria 
    white "自签bing.com证书100年"
    openssl ecparam -genkey -name prime256v1 -out /usr/local/etc/singbox/hysteria/private.key && openssl req -new -x509 -days 36500 -key /usr/local/etc/singbox/hysteria/private.key -out /usr/local/etc/singbox/hysteria/cert.pem -subj "/CN=bing.com"
    white "开始生成配置文件"
    # 检查sb配置文件是否存在
    config_file="/usr/local/etc/singbox/config.json"
    if [ ! -f "$config_file" ]; then
        echo -e "\e[31m错误：配置文件 $config_file 不存在.\e[0m"
        echo -e "\e[31m请选择检查singbox或者创建config.json脚本.\e[0m"
        rm -rf /mnt/psb.sh    #delete    
        exit 1
    fi   
    hy_config='{
      "type": "hysteria2",
      "tag": "'"${hy2home_tag}"'",
      "listen": "::",
      "listen_port": '"${hyport}"',
      "sniff": true,
      "sniff_override_destination": false,
      "sniff_timeout": "100ms",
      "users": [
        {
          "password": "'"${hy2_password}"'"
        }
      ],
      "ignore_client_bandwidth": true,
      "tls": {
        "enabled": true,
        "alpn": [
          "h3"
        ],
        "certificate_path": "/usr/local/etc/singbox/hysteria/cert.pem",
        "key_path": "/usr/local/etc/singbox/hysteria/private.key"
      }
    },'
    line_num=$(grep -n 'inbounds' /usr/local/etc/singbox/config.json | cut -d ":" -f 1)
    # 如果找到了行号，则在其后面插入 JSON 字符串，否则不进行任何操作
    if [ ! -z "$line_num" ]; then
        # 将文件分成两部分，然后在中间插入新的 JSON 字符串
        head -n "$line_num" /usr/local/etc/singbox/config.json > tmpfile
        echo "$hy_config" >> tmpfile
        tail -n +$(($line_num + 1)) /usr/local/etc/singbox/config.json >> tmpfile
        mv tmpfile /usr/local/etc/singbox/config.json
    fi
    green "HY2回家配置写入完成"
    white "开始重启sing-box"
    systemctl restart sing-box
    white "开始生成sing-box回家-手机配置"
    wget -q -O /usr/local/etc/singbox/go_home.json https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/singbox/oupavoc/go_home.json
    home_config_file="/usr/local/etc/singbox/go_home.json"
    if [ ! -f "$home_config_file" ]; then
        echo -e "\e[31m错误：配置文件 $home_config_file 不存在.\e[0m"
        echo -e "\e[31m请检查网络可正常访问github后运行脚本.\e[0m"
        rm -rf /mnt/psb.sh    #delete    
        exit 1
    fi
    sed -i "s|ip_cidr_ip|${private_lan}.0/24|g" ${home_config_file}
    sed -i "s/dns_domain/${hy2home_domain}/g" ${home_config_file}
    sed -i "s/singbox_domain/${hy2home_domain}/g" ${home_config_file}
    sed -i "s/singbox_hyport/${hyport}/g" ${home_config_file}
    sed -i "s/singbox_password/${hy2_password}/g" ${home_config_file}

    rm -rf /mnt/psb.sh    #delete   
    systemctl restart sing-box
    echo "=================================================================="
    echo -e "\t\t\tSing-Box HY2回家配置生成完毕"
    echo -e "\n"
    echo -e "sing-box 回家配置生成路径为: ${yellow}/usr/local/etc/singbox/go_home.json${reset}请自行复制至 sing-box 客户端"
    echo -e "温馨提示:\n本脚本仅在ubuntu25.04环境下测试，其他环境未经验证 "
    echo "================================================================="   
}
################################ 删除 HY2回家 -- O ################################
del_hy2_o() {
    if [[ -z "${hy2home_tag}" ]]; then
        while [[ -z "${hy2home_tag}" ]]; do
            read -p "请输入您的 HY2 节点名称 (默认名称：hy2-in): " hy2home_tag
            hy2home_tag=${hy2home_tag:-hy2-in}
        done
    fi
    
    white "删除HY2回家..."
    systemctl stop sing-box
    
    # 创建备份
    cp /usr/local/etc/singbox/config.json /usr/local/etc/singbox/config.json.bak
    
    # 检查并安装jq
    if ! command -v jq >/dev/null 2>&1; then
        white "jq未安装，正在自动安装..."
        
        # Ubuntu/Debian系统安装jq
        apt update && apt install -y jq
        
        # 检查jq是否安装成功
        if ! command -v jq >/dev/null 2>&1; then
            red "错误：jq安装失败，请手动执行: apt install jq"
            return 1
        fi
        
        green "jq安装成功"
    fi
    
    white "使用jq处理JSON配置..."
    
    # 使用jq精确删除指定tag的inbound配置
    if jq --arg tag "$hy2home_tag" '.inbounds |= map(select(.tag != $tag))' /usr/local/etc/singbox/config.json.bak > /usr/local/etc/singbox/config.json; then
        green "配置删除成功"
        
        # 验证生成的JSON格式是否正确
        if ! jq empty /usr/local/etc/singbox/config.json >/dev/null 2>&1; then
            echo "警告：生成的JSON格式有误，恢复备份文件"
            cp /usr/local/etc/singbox/config.json.bak /usr/local/etc/singbox/config.json
            return 1
        fi
    else
        red "错误：使用jq处理配置文件失败"
        return 1
    fi
    
    white "删除相关配置文件"
    rm -rf /usr/local/etc/singbox/hysteria
    rm -rf /usr/local/etc/singbox/go_home.json
    rm -rf /mnt/psb.sh    #delete  
    
    green "HY2回家卸载完成"
    systemctl restart sing-box
    echo "=================================================================="
    echo -e "\t\t\tSing-Box HY2回家配置卸载完成"
    echo -e "\n"
    echo -e "sing-box 配置已生成备份\n路径为: ${yellow}/usr/local/etc/singbox/config.json.bak${reset}\n如配置出错需恢复，请自行修改。"
    echo -e "温馨提示:\n本脚本仅在ubuntu25.04环境下测试，其他环境未经验证 "
    echo "=================================================================="
}

##############################################################################
####                                                                      ####
####                               Ron版                                  ####
####                                                                      ####
##############################################################################

################################ 用户自定义设置 -- Ron  ################################
custom_settings_ron() {
    interfaces=$(ip -o link show | awk -F': ' '{print $2}')
    # 输出物理网卡名称
    for interface in $interfaces; do
        # 检查是否为物理网卡（不包含虚拟、回环等），并排除@符号及其后面的内容
        if [[ $interface =~ ^(en|eth).* ]]; then
            interface_name=$(echo "$interface" | awk -F'@' '{print $1}')  # 去掉@符号及其后面的内容
            echo "您当前的网卡是：$interface_name"
            valid_interfaces+=("$interface_name")  # 存储有效的网卡名称
        fi
    done
    while true; do
        # 提示用户选择
        read -p "脚本自行检测的是否是您要的网卡？( y [默认选项] /n): " confirm_interface
        confirm_interface=${confirm_interface:-y}
        if [[ "$confirm_interface" =~ ^[yn]$ ]]; then
            break
        else
            red "无效的选项，请输入y或n"
        fi
    done
    if [ "$confirm_interface" = "y" ]; then
        selected_interface="$interface_name"
        white "您选择的网卡是: ${yellow}$selected_interface${reset}"
    elif [ "$confirm_interface" = "n" ]; then
        read -p "请自行输入您的网卡名称: " selected_interface
        white "您输入的网卡名称是: ${yellow}$selected_interface${reset}"
    fi
    
    while true; do
        clear
        white "是否已开始vps固定缓存解析"
        white "1. 未开启 [默认选项]"
        white "2. 开启"     
        read -p "请选择: " singbox_install_mode_choose
        singbox_install_mode_choose=${singbox_install_mode_choose:-1}
        if [[ "$singbox_install_mode_choose" =~ ^[1-2]$ ]]; then
            break
        else
            red "无效的选项，请输入1或2"
        fi
    done
    if [ "$singbox_install_mode_choose" == "2" ]; then
        read -p "请输入vps固定缓存解析服务器IP (默认：$private_lan.1): " vps_dns_server
        vps_dns_server=${vps_dns_server:-$private_lan.1}

        read -p "请输入要添加的域名（多个域名用空格分隔）: " vps_passwall_domain
        if [ -z "$vps_passwall_domain" ]; then
            red "错误：VPS节点域名输入不能为空"
            exit 1
        fi
    fi   
    custom_VPS_settings
}

################################ 下载安装singbox -- Ron ################################
install_singbox_ron() {
    mkdir -p /mnt/singbox /usr/local/etc/singbox
    cd /mnt/singbox
    wget --quiet --show-progress https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/singbox/Ron/ron-singbox-1.12.0-beta.11.rar
    7z x /mnt/singbox/ron-singbox-1.12.0-beta.11.rar -o/mnt/singbox
    cd /mnt/singbox/singbox
    chmod +x /mnt/singbox/singbox/singbox_rule_updata.sh /mnt/singbox/singbox/ui_updata.sh /mnt/singbox/singbox/singbox
    mv /mnt/singbox/singbox/singbox /usr/local/bin/
    mv /mnt/singbox/singbox/{sing-box.service,sing-box-router.service} /etc/systemd/system/
    mv /mnt/singbox/singbox/nftables.conf /etc/
    mv /mnt/singbox/singbox /usr/local/etc/

    green "sing-box 下载安装完成"
}

################################写入配置文件 -- Ron ################################
install_config_ron() {
    bash /usr/local/etc/singbox/singbox_rule_updata.sh
    singbox_config_file="/usr/local/etc/singbox/conf/04_outbounds.json"
    if [[ "$node_basic_choose" == "1" ]]; then
        if [[ "$node_operation" == "1" ]]; then
            cp /usr/local/etc/singbox/conf/04_outbounds_brutal.json $singbox_config_file
            sed -i "s|vless_tag|${vless_tag}|g" $singbox_config_file
            sed -i "s|vless_uuid|${vless_uuid}|g" $singbox_config_file
            sed -i "s|vless_server_ip|${vless_server_ip}|g" $singbox_config_file
            sed -i "s|vless_port|${vless_port}|g" $singbox_config_file
            sed -i "s|vless_domain|${vless_domain}|g" $singbox_config_file
            sed -i "s|vless_public_key|${vless_public_key}|g" $singbox_config_file
            sed -i "s|vless_short_id|${vless_short_id}|g" $singbox_config_file
            sed -i "s|vless_up_mbps|${vless_up_mbps}|g" $singbox_config_file
            sed -i "s|vless_down_mbps|${vless_down_mbps}|g" $singbox_config_file
        elif [[ "$node_operation" == "2" ]]; then
            cp /usr/local/etc/singbox/conf/04_outbounds_hy2.json $singbox_config_file         
            sed -i "s|hy2_pass_tag|${hy2_pass_tag}|g" $singbox_config_file
            sed -i "s|hy2_pass_server_ip|${hy2_pass_server_ip}|g" $singbox_config_file
            sed -i "s|hy2_pass_port|${hy2_pass_port}|g" $singbox_config_file
            sed -i "s|hy2_pass_up_mbps|${hy2_pass_up_mbps}|g" $singbox_config_file
            sed -i "s|hy2_pass_down_mbps|${hy2_pass_down_mbps}|g" $singbox_config_file
            sed -i "s|hy2_pass_password|${hy2_pass_password}|g" $singbox_config_file
            sed -i "s|hy2_pass_domain|${hy2_pass_domain}|g" $singbox_config_file
        fi
    else
        cp /usr/local/etc/singbox/conf/04_outbounds_brutal.json $singbox_config_file 
    fi
    if [[ "$singbox_install_mode_choose" == "2" ]]; then
        conf_path="/usr/local/etc/singbox/conf/02_dns.json"
        cp /usr/local/etc/singbox/conf/02_dns_opn.json $conf_path

        read -ra domains <<< "$vps_passwall_domain"

        temp_domains=""
        for i in "${!domains[@]}"; do
            domain=$(echo "${domains[i]}" | xargs)
            if [ -n "$domain" ]; then
                if [ $i -eq 0 ]; then
                    temp_domains="          \"$domain\""
                else
                    temp_domains="$temp_domains,\n          \"$domain\""
                fi
            fi
        done

        awk -v new_domains="$temp_domains" '
        BEGIN { 
            in_target_rule = 0
            in_domain_suffix = 0
            rule_content = ""
        }
        {
            # 如果在规则块中
            if (in_target_rule) {
                rule_content = rule_content $0 "\n"
                
                # 检查是否是规则块结束
                if ($0 ~ /^      }/) {
                    # 检查这个规则是否包含111.top
                    if (rule_content ~ /"111\.top"/) {
                        # 执行替换
                        gsub(/"domain_suffix": \[[^]]*\]/, "\"domain_suffix\": [\n" new_domains "\n        ]", rule_content)
                    }
                    printf "%s", rule_content
                    in_target_rule = 0
                    rule_content = ""
                    next
                }
            }
            # 检查是否开始一个新的规则块
            else if ($0 ~ /^      {$/) {
                in_target_rule = 1
                rule_content = $0 "\n"
                next
            }
            # 不在规则块中，直接输出
            else {
                print
            }
        }
        END {
            if (rule_content != "") {
                printf "%s", rule_content
            }
        }
        ' "$conf_path" > /tmp/temp_conf.json

        if [ -f "/tmp/temp_conf.json" ]; then
            if python3 -m json.tool /tmp/temp_conf.json > /dev/null 2>&1; then
                mv /tmp/temp_conf.json "$conf_path"
            else
                echo "错误：生成的JSON格式不正确，恢复原始文件"
                mv "$backup_path" "$conf_path"
                rm -f /tmp/temp_conf.json
                exit 1
            fi
        else
            echo "错误：无法生成临时配置文件，恢复原始文件"
            mv "$backup_path" "$conf_path"
            exit 1
        fi
    fi

    sed -i "s|"listen": "10.10.10.2"|"listen": "${private_ip}"|g" /usr/local/etc/singbox/conf/03_inbounds.json 

    if ls /usr/local/etc/singbox/conf/*_opn.json /usr/local/etc/singbox/conf/*_brutal.json /usr/local/etc/singbox/conf/*_hy2.json 1> /dev/null 2>&1; then
        rm /usr/local/etc/singbox/conf/*_opn.json /usr/local/etc/singbox/conf/*_brutal.json /usr/local/etc/singbox/conf/*_hy2.json 2> /dev/null
    fi
}

################################安装tproxy -- Ron ################################
install_tproxy_ron() {
    white "开始创建nftables tproxy转发..."
    apt install nftables -y
    green "sing-box-router 服务创建完成"

    white "开始写入nftables tproxy规则..."
    dos2unix /etc/nftables.conf
    green "nftables规则写入完成"

    nft flush ruleset
    nft -f /etc/nftables.conf
    systemctl enable --now nftables
    green "Nftables tproxy转发创建完成"

    white "开始启动sing-box..."
    systemctl enable --now sing-box-router
    if [[ "$node_basic_choose" == "1" && "$node_operation" != "3" ]]; then
        systemctl enable --now sing-box
    else
        systemctl enable sing-box
    fi    
    green "Sing-box启动已完成"
}

################################  HY2回家  -- Ron ################################
install_home_ron() {
    sleep 1 
    white "hysteria2 回家 自签证书"
    if [[ -z "${hy2home_tag}" ]] || [[ -z "${hyport}" ]] || [[ -z "${hy2_password}" ]]; then
        while [[ -z "${hy2home_domain}" ]]; do
            read -p "请输入回家的DDNS域名: " hy2home_domain
            if [[ $hy2home_domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                break
            else
                red "域名格式不正确，请重新输入"
            fi
        done
        # 获取节点名称
        while [[ -z "${hy2home_tag}" ]]; do
            read -p "请输入您的 HY2 节点名称 (默认名称：hy2-in): " hy2home_tag
            hy2home_tag=${hy2home_tag:-hy2-in}
        done
        
        # 获取端口号
        while [[ -z "${hyport}" ]]; do
            read -p "请输入您的 HY2 回家节点的入站端口： " hyport
            if [[ ! "$hyport" =~ ^[0-9]{1,5}$ ]] || [[ "$hyport" -lt 1 ]] || [[ "$hyport" -gt 65535 ]]; then
                red "无效的端口号，请输入 1-65535 之间的数字"
                hyport=""
            fi
        done
        while [[ -z "${hy2_password}" ]]; do
        read -p "请输入您的 HY2 节点的密码: " hy2_password
        if [[ -z "${hy2_password}" ]]; then
            red "密码不能为空，请重新输入"
        fi
        done
    fi
    white "开始创建证书存放目录"
    mkdir -p /usr/local/etc/singbox/hysteria 
    white "自签bing.com证书100年"
    openssl ecparam -genkey -name prime256v1 -out /usr/local/etc/singbox/hysteria/private.key && openssl req -new -x509 -days 36500 -key /usr/local/etc/singbox/hysteria/private.key -out /usr/local/etc/singbox/hysteria/cert.pem -subj "/CN=bing.com"
    white "开始生成配置文件"
    # 检查sb配置文件是否存在
    config_file="/usr/local/etc/singbox/conf/03_inbounds.json"
    if [ ! -f "$config_file" ]; then
        echo -e "\e[31m错误：配置文件 $config_file 不存在.\e[0m"
        echo -e "\e[31m请选择检查singbox或者创建config.json脚本.\e[0m"
        rm -rf /mnt/psb.sh    #delete    
        exit 1
    fi   
    hy_config='    {
      "type": "hysteria2",
      "tag": "'"${hy2home_tag}"'",
      "listen": "::",
      "listen_port": '"${hyport}"',
      "sniff": true,
      "sniff_override_destination": false,
      "sniff_timeout": "100ms",
      "users": [
        {
          "password": "'"${hy2_password}"'"
        }
      ],
      "ignore_client_bandwidth": true,
      "tls": {
        "enabled": true,
        "alpn": [
          "h3"
        ],
        "certificate_path": "/usr/local/etc/singbox/hysteria/cert.pem",
        "key_path": "/usr/local/etc/singbox/hysteria/private.key"
      }
    },'

    # 查找 "inbounds": [ 的行号
    line_num=$(grep -n '"inbounds": \[' /usr/local/etc/singbox/conf/03_inbounds.json | cut -d ":" -f 1)

    # 如果找到了行号，则在其后面插入 JSON 字符串
    if [ ! -z "$line_num" ]; then
        # 将文件分成两部分，然后在 "inbounds": [ 后面插入新的 JSON 字符串
        head -n "$line_num" /usr/local/etc/singbox/conf/03_inbounds.json > tmpfile
        echo "$hy_config" >> tmpfile
        tail -n +$(($line_num + 1)) /usr/local/etc/singbox/conf/03_inbounds.json >> tmpfile
        mv tmpfile /usr/local/etc/singbox/conf/03_inbounds.json
    fi
    green "HY2回家配置写入完成"
    white "开始重启sing-box"
    systemctl restart sing-box
    white "开始生成sing-box回家-手机配置"
    wget -q -O /usr/local/etc/singbox/go_home.json https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/singbox/oupavoc/go_home.json
    home_config_file="/usr/local/etc/singbox/go_home.json"
    if [ ! -f "$home_config_file" ]; then
        echo -e "\e[31m错误：配置文件 $home_config_file 不存在.\e[0m"
        echo -e "\e[31m请检查网络可正常访问github后运行脚本.\e[0m"
        rm -rf /mnt/psb.sh    #delete    
        exit 1
    fi
    sed -i "s|ip_cidr_ip|${private_lan}.0/24|g" ${home_config_file}
    sed -i "s/dns_domain/${hy2home_domain}/g" ${home_config_file}
    sed -i "s/singbox_domain/${hy2home_domain}/g" ${home_config_file}
    sed -i "s/singbox_hyport/${hyport}/g" ${home_config_file}
    sed -i "s/singbox_password/${hy2_password}/g" ${home_config_file}

    rm -rf /mnt/psb.sh    #delete  
    systemctl restart sing-box 
    echo "=================================================================="
    echo -e "\t\t\tSing-Box HY2回家配置生成完毕"
    echo -e "\n"
    echo -e "sing-box 回家配置生成路径为: ${yellow}/usr/local/etc/singbox/go_home.json${reset}请自行复制至 sing-box 客户端"
    echo -e "温馨提示:\n本脚本仅在ubuntu25.04环境下测试，其他环境未经验证 "
    echo "================================================================="   
}

################################ 删除 HY2回家  -- Ron ################################
del_hy2_ron() {
    if [[ -z "${hy2home_tag}" ]]; then
        while [[ -z "${hy2home_tag}" ]]; do
            read -p "请输入您的 HY2 节点名称 (默认名称：hy2-in): " hy2home_tag
            hy2home_tag=${hy2home_tag:-hy2-in}
        done
    fi
   
    white "删除HY2回家..."
    systemctl stop sing-box
   
    # 创建备份
    cp /usr/local/etc/singbox/conf/03_inbounds.json /usr/local/etc/singbox/conf/03_inbounds.json.bak
   
    # 检查并安装jq
    if ! command -v jq >/dev/null 2>&1; then
        white "jq未安装，正在自动安装..."
       
        # Ubuntu/Debian系统安装jq
        apt update && apt install -y jq
       
        # 检查jq是否安装成功
        if ! command -v jq >/dev/null 2>&1; then
            red "错误：jq安装失败，请手动执行: apt install jq"
            return 1
        fi
       
        green "jq安装成功"
    fi
   
    white "使用jq处理JSON配置..."
   
    # 使用jq精确删除指定tag的inbound配置
    if jq --arg tag "$hy2home_tag" '. |= map(select(.tag != $tag))' /usr/local/etc/singbox/conf/03_inbounds.json.bak > /usr/local/etc/singbox/conf/03_inbounds.json; then
        green "配置删除成功"
       
        # 验证生成的JSON格式是否正确
        if ! jq empty /usr/local/etc/singbox/conf/03_inbounds.json >/dev/null 2>&1; then
            red "警告：生成的JSON格式有误，恢复备份文件"
            cp /usr/local/etc/singbox/conf/03_inbounds.json.bak /usr/local/etc/singbox/conf/03_inbounds.json
            return 1
        fi
    else
        red "错误：使用jq处理配置文件失败"
        return 1
    fi
   
    white "删除相关配置文件"
    rm -rf /usr/local/etc/singbox/hysteria
    rm -rf /usr/local/etc/singbox/go_home.json
    rm -rf /mnt/psb.sh    #delete  
   
    green "HY2回家卸载完成"
    systemctl restart sing-box
    echo "=================================================================="
    echo -e "\t\t\tSing-Box HY2回家配置卸载完成"
    echo -e "\n"
    echo -e "sing-box 配置已生成备份\n路径为: ${yellow}/usr/local/etc/singbox/conf/03_inbounds.json.bak${reset}\n如配置出错需恢复，请自行修改。"
    echo -e "温馨提示:\n本脚本仅在ubuntu22.04环境下测试，其他环境未经验证 "
    echo "=================================================================="
}
################################## 删除 Sing-Box ################################
del_singbox() {
    white "停止 sing-box 服务并删除相关文件..."
    systemctl stop sing-box sing-box-router nftables
    systemctl disable sing-box sing-box-router nftables
    rm -rf /etc/systemd/system/sing-box* /usr/local/etc/singbox /usr/local/bin/sing*
    if [[ -d "/mnt/singbox" ]]; then
        rm -rf /mnt/singbox || exit 1
    fi   
    green "卸载sing-box已完成"
}

################################## HY2回家系列 ################################
singbox_hy2home() {
    clear
    white "请选择要执行的操作 [回车返回上级菜单]："
    white "\n--------------安装HY2回家----------------"    
    white "1. 已安装Singbox-${yellow}Οὐρανός版${reset}安装"
    white "2. 已安装Singbox-${yellow}Ron版${reset}安装"  
    white "\n--------------删除HY2回家----------------"
    white "3. 删除Singbox-${yellow}Οὐρανός版${reset} HY2"
    white "4. 删除Singbox-${yellow}Ron版${reset} HY2"
    white "\n--------------返回----------------"
    white "5. ${yellow}返回上级菜单${reset}"
            
    # 输入验证循环
    while true; do
        read -p "请选择（1-5）: " hy2home_chose
        hy2home_chose="${hy2home_chose:-5}"  
        if [[ $hy2home_chose =~ ^[1-5]$ ]]; then
            break
        else
            red "输入的选项数字不正确，请重新输入"
        fi
    done

    # 根据选择执行对应操作
    case $hy2home_chose in
        1)
            white "你选择了: Οὐρανός版-singbox 安装HY2回家"
            install_home_o
            ;;         
        2)
            white "你选择了: Ron版-singbox 安装HY2回家"
            install_home_ron
            ;;         
        3)
            white "你选择了: Οὐρανός版-singbox 删除HY2回家"
            del_hy2_o
            ;;           
        4)
            white "你选择了: Ron版-singbox 删除HY2回家"
            del_hy2_ron
            ;;         
        5)
            singbox_choose
            ;;
    esac
}

################################## Sing-Box选择 ################################
singbox_choose() {
    clear
    echo "=================================================================="
    echo -e "\t\tSing-Box相关脚本 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo "欢迎使用Sing-Box相关脚本"
    echo "请选择要执行的服务："
    echo "=================================================================="
    white "1. 安装sing-box -- ${yellow}Οὐρανός版${reset} （配置描述:${yellow}官核v1.10.7${reset}）"
    white "2. 安装sing-box -- ${yellow}Ron版${reset} （配置描述:${yellow}官核v1.12.0-beta.11${reset}）"
    echo "3. 卸载sing-box"
    echo "4. HY2 回家安装 & 删除"
    echo -e "\t"
    echo "-. 返回上级菜单"      
    echo "0) 退出脚本"
    read -p "请选择服务: " choice
    # read choice
    case $choice in
        1)
            white "安装sing-box -- ${yellow}Οὐρανός版${reset} （配置描述:${yellow}官核v1.10.7${reset}）"
            intall_mode_Classification=Οὐρανός版
            custom_settings_o
            basic_settings
            install_singbox_o
            install_config_o
            install_tproxy_o
            install_sing_box_over
            ;;
        2)
            white "安装sing-box -- ${yellow}Ron版${reset} （配置描述:${yellow}官核v1.12.0-beta.11${reset}）"
            intall_mode_Classification=Ron版
            custom_settings_ron
            basic_settings
            install_singbox_ron
            install_config_ron
            install_tproxy_ron
            install_sing_box_over
            ;;          
        3)
            white "卸载sing-box核心程序及其相关配置文件"    
            del_singbox
            rm -rf /mnt/psb.sh    #delete   
            ;; 
        4)            
            white "HY2 回家安装 & 删除"  
            singbox_hy2home  
            rm -rf /mnt/psb.sh    #delete   
            ;;           
        0)
            red "退出脚本，感谢使用."
            rm -rf /mnt/psb.sh    #delete             
            ;;
        -)
            white "脚本切换中，请等待..."
            rm -rf /mnt/psb.sh    #delete       
            wget -q -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
            ;;
        *)
            white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            singbox_choose
            ;;
    esac
}

################################ 主程序 ################################
singbox_choose