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

################################## Sing-Box选择 ################################
singbox_choose() {
    clear
    echo "=================================================================="
    echo -e "\t\tSing-Box相关脚本 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo "欢迎使用Sing-Box相关脚本"
    echo "请选择要执行的服务："
    echo "=================================================================="
    echo "1. 安装官方sing-box"
    echo "2. 升级官方sing-box"    
    echo "3. sing-box添加部分协议节点"    
    echo "4. hysteria2 回家"
    echo "5. 卸载sing-box" 
    echo "6. 卸载hysteria2 回家"
    echo "7. sing-box 面板（metacubexd）升级"
    echo "8. sing-box 面板切换（将原metacubexd切换为zashboard）"    
    echo "9. sing-box 面板（zashboard）升级"
    echo -e "\t"
    echo "99. 一键卸载singbox及HY2回家"
    echo "-. 返回上级菜单"      
    echo "0) 退出脚本"
    read -p "请选择服务: " choice
    # read choice
    case $choice in
        1)
            white "开始安装官方Singbox核心"
            install_mode_choose
            interface_choose
            custom_basic
            basic_settings
            if [[ "$singbox_install_mode_choose" == "1" ]]; then 
                install_singbox
            elif [[ "$singbox_install_mode_choose" == "2" ]]; then
                install_binary_file_singbox
            fi
            install_service
            install_config
            install_tproxy
            install_sing_box_over
            ;;
        2)
            white "升级官方sing-box"    
            singbox_update
            ;;              
        3)
            white "sing-box添加部分协议节点"    
            add_node_flow_path
            ;;    
        4)
            white "开始生成回家配置"
            hy2_custom_settings
            install_home
            install_hy2_home_over
            ;;
        5)
            white "卸载sing-box核心程序及其相关配置文件"    
            del_singbox
            rm -rf /mnt/singbox.sh    #delete   
            ;;
        6)
            white "卸载HY2回家配置及其相关配置文件"       
            del_hy2
            rm -rf /mnt/singbox.sh    #delete   
            ;;
        7)
            white "升级sing-box 面板（metacubexd）..."       
            updata_singbox_ui_metacubexd
            rm -rf /mnt/singbox.sh    #delete   
            ;;
        8)
            white "sing-box 面板切换（将原metacubexd切换为zashboard）..."       
            change_singbox_ui
            rm -rf /mnt/singbox.sh    #delete   
            ;;              
        9)
            white "升级sing-box 面板（zashboard）..."       
            updata_singbox_ui_zashboard
            rm -rf /mnt/singbox.sh    #delete   
            ;;                        
        99)
            white "一键卸载singbox及HY2回家"    
            del_singbox
            echo "删除相关配置文件"
            rm -rf /root/hysteria
            rm -rf /root/go_home.json
            rm -rf /mnt/singbox.sh    #delete   
            green "HY2回家卸载完成"
            ;;            
        0)
            red "退出脚本，感谢使用."
            rm -rf /mnt/singbox.sh    #delete             
            ;;
        -)
            white "脚本切换中，请等待..."
            rm -rf /mnt/singbox.sh    #delete       
            wget -q -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
            ;;
        *)
            white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            singbox_choose
            ;;
    esac
}

################################ 用户自定义安装模式 ################################
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
        read -p "请输入要编译的版本号（默认：v1.10.7）: " input_version
        if [[ -z "$input_version" ]]; then
            white "您选择了默认版本：v1.10.7"
            selected_version="v1.10.7"
        else
            white "您选择了指定版本：$input_version"
            selected_version="$input_version"
        fi
    fi      
    while true; do
        echo "请选择要安装的 tproxy 配置版本："
        echo "1) 新版 tproxy 配置（read方案）"
        echo "2) 旧版 tproxy 配置（fake方案）"
        read -p "请输入选项 (1 或 2): " tproxy_version
        tproxy_version=${tproxy_version:-1}  # 默认选择新版（1）
        if [[ "$tproxy_version" == "1" ]]; then
            tproxy_name=new
            white "已选择：新版 tproxy 配置"
            break
        elif [[ "$tproxy_version" == "2" ]]; then
            tproxy_name=old
            white "已选择：旧版 tproxy 配置"
            break
        else
            red "无效的选项，请输入 1 或 2"
        fi
    done
}      
################################ 用户自定义设置 ################################
interface_choose() {
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
}    
custom_basic() {
    # 选择节点类型
    while true; do
        read -p "请输入您的内网网段(默认为10.10.10.0/24): " lanip_segment
        lanip_segment=${lanip_segment:-10.10.10.0/24}
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
        custom_node
    else
        white "${yellow}用户选择自行调整配置文件...${reset}"
    fi
}

custom_node() {
    clear
        white "\n${yellow}特别声明:\n本脚本功能适用于本脚本安装singbox配置，其他配置请自行测试！！！${reset}\n"    
    # 选择节点类型
    while true; do
        white "请选择需要写入的节点类型 :"
        white "1. vless（brutal协议） [默认选项]"
        white "2. hy2"
        white "3. 返回上级菜单"
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
        custom_basic
    fi
}
################################ 基础环境设置 ################################
basic_settings() {
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
    go_version=$(curl -s https://go.dev/VERSION?m=text | head -1)
    curl -L "https://go.dev/dl/${go_version}.linux-amd64.tar.gz" -o "${go_version}.linux-amd64.tar.gz"
    sudo tar -C /usr/local -xzf "${go_version}.linux-amd64.tar.gz"
    # curl -L https://go.dev/dl/go1.23.4.linux-amd64.tar.gz -o go1.23.4.linux-amd64.tar.gz
    # tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/golang.sh
    source /etc/profile.d/golang.sh
    go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@$selected_version
    white "等待检测安装状态"    
    if ! go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@$selected_version; then
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
    if [[ "$build_mode" == "1" ]]; then
        local singbox_VERSION=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep tag_name | cut -d ":" -f2 | sed 's/[\",v ]//g')
    elif [[ "$build_mode" == "2" ]]; then
        local singbox_VERSION=${selected_version//v/}
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
install_service() {
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
}
################################写入配置文件################################
install_config() {
    if [[ "$node_basic_choose" == "1" ]]; then
        if [[ "$node_operation" == "1" ]]; then
            wget -q -O /usr/local/etc/sing-box/config.json https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/singbox/config_vless.json
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
            wget -q -O /usr/local/etc/sing-box/config.json https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/singbox/config_hy2.json
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
    # white "创建系统转发..."   
    # if ! grep -q '^net.ipv4.ip_forward=1$' /etc/sysctl.conf; then
    #     echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    # fi
    # if ! grep -q '^net.ipv6.conf.all.forwarding = 1$' /etc/sysctl.conf; then
    #     echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
    # fi
    # green "系统转发创建完成"
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
                iifname { lo, $selected_interface } meta l4proto { tcp } redirect to :7877 
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
                iifname { lo, $selected_interface } meta l4proto { tcp } redirect to :7877 

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
		iifname { lo, $selected_interface } meta l4proto {  udp } ct direction original goto singbox-tproxy
	}
}
EOF
    fi

    sed -i "s|10.10.10.0/24|${lanip_segment}|g" /etc/nftables.conf
    # sed -i "s/dns_domain/${domain}/g" /root/go_home.json
    # sed -i "s#10.10.10.0/24#${lanip_segment}#g" /etc/nftables.conf

    green "nftables规则写入完成"
    nft flush ruleset
    nft -f /etc/nftables.conf
    systemctl enable --now nftables
    green "Nftables tproxy转发创建完成"
    install_over
}
################################sing-box安装结束################################
install_over() {
    white "开始启动sing-box..."
    systemctl enable --now sing-box-router
    systemctl enable --now sing-box
    green "Sing-box启动已完成"
}
################################sing-box升级################################
singbox_update() {

    while true; do
        clear
        white "请选择升级模式:"
        white "1. go文件编译模式升级 [默认选项]"
        white "2. 下载二进制文件模式升级"     
        read -p "请选择: " singbox_mode_update
        singbox_mode_update=${singbox_mode_update:-1}
        if [[ "$singbox_mode_update" =~ ^[1-2]$ ]]; then
            break
        else
            red "无效的选项，请输入1或2"
        fi
    done
    if [ ! -f "/usr/local/bin/sing-box" ]; then
        red "请检查是否已安装sing-box程序，如已安装仍报错，可能为路径错误，请用本脚本安装程序后使用"
        rm -rf /mnt/singbox.sh    #delete
        exit 1
    fi
    if [[ "$singbox_mode_update" == "1" ]]; then
        white "开始编译升级安装..."
        if [ ! -x "/usr/local/go/bin/go" ]; then
            white "未安装go环境，开始安装..."
            apt -y install curl git build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64
            curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz -o go1.22.4.linux-amd64.tar.gz
            tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
            echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/golang.sh
            source /etc/profile.d/golang.sh
            if [ ! -x "/usr/local/go/bin/go" ]; then
                red "go环境安装失败，退出脚本"
                rm -rf /mnt/singbox.sh    #delete    
                exit 1
            fi    
        fi
        # go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme -ldflags "-X github.com/sagernet/sing-box/cmd/sing-box.version=1.9.7" github.com/sagernet/sing-box/cmd/sing-box@latest
        go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@latest
        white "等待检测安装状态"    
        if ! go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@latest; then
            red "Sing-Box 编译失败！退出脚本"
            rm -rf /mnt/singbox.sh    #delete    
            exit 1
        fi
        systemctl stop sing-box
        if pgrep -x "sing-box" > /dev/null; then
            red "关闭sing-box 服务失败，程序仍在运行，请停止程序后重新运行脚本"
            rm -rf /mnt/singbox.sh    #delete
            exit 1
        fi
        rm -rf /usr/local/bin/sing-box
        cp $(go env GOPATH)/bin/sing-box /usr/local/bin/
    elif [[ "$singbox_mode_update" == "2" ]]; then
        white "开始二进制文件升级安装..."
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
        local singbox_VERSION=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep tag_name | cut -d ":" -f2 | sed 's/[\",v ]//g')
        wget --quiet --show-progress -O /mnt/singbox/singbox.tar.gz https://github.com/SagerNet/sing-box/releases/download/v${singbox_VERSION}/sing-box-${singbox_VERSION}-linux-${ARCH}.tar.gz
        if [ ! -f "/mnt/singbox/singbox.tar.gz" ]; then
            red "下载最新版sing-box文件失败，请检查网络，保持网络畅通后重新运行脚本"
            rm -rf /mnt/singbox.sh    #delete
            rm -rf /mnt/singbox
            exit 1
        fi
        tar -C /mnt/singbox -xzf /mnt/singbox/singbox.tar.gz
        chown root:root /mnt/singbox/sing-box-${singbox_VERSION}-linux-${ARCH}/sing-box
        systemctl stop sing-box
        if pgrep -x "sing-box" > /dev/null; then
            red "关闭sing-box 服务失败，程序仍在运行，请停止程序后重新运行脚本"
            rm -rf /mnt/singbox.sh    #delete
            rm -rf /mnt/singbox
            exit 1
        fi
        rm -rf /usr/local/bin/sing-box
        mv /mnt/singbox/sing-box-${singbox_VERSION}-linux-${ARCH}/sing-box /usr/local/bin 
        if [ ! -f "/usr/local/bin/sing-box" ]; then
            red "文件移动失败，请检查用户权限"
            rm -rf /mnt/singbox.sh    #delete
            rm -rf /mnt/singbox
            exit 1
        fi
        rm -rf /mnt/singbox
    fi
    systemctl restart sing-box
    systemctl status sing-box
    green "sing-box 程序升级完成"
}        
################################ HY2回家自定义设置 ################################
hy2_custom_settings() {
    while true; do
        read -p "请输入回家的DDNS域名: " domain
        if [[ $domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            red "域名格式不正确，请重新输入"
        fi
    done
    echo -e "您输入的域名是: \e[1m\e[33m$domain\e[0m"
    while true; do
        read -p "请输入端口号: " hyport
        if [[ $hyport =~ ^[0-9]+$ ]]; then
            break
        else
            red "端口号格式不正确，请重新输入"
        fi
    done
    echo -e "您输入的端口号是: \e[1m\e[33m$hyport\e[0m"
    read -p "请输入局域网IP网段（示例：10.10.10.0，回车默认为示例网段）: " net
    net="${net:-10.10.10.0}"
    echo -e "您输入的局域网网段是: \e[1m\e[33m$net\e[0m"
    while true; do
        read -p "请输入子网掩码（255.255.255.0为24，回车默认为24）: " mask
        mask="${mask:-24}"
        if [[ $mask =~ ^[0-9]+$ ]]; then
            break
        else
            echo -e "\e[31m子网掩码格式不正确，请重新输入\e[0m"
        fi
    done
    echo -e "您输入的子网掩码是: \e[1m\e[33m$mask\e[0m"
    ip="${net}/${mask}"
    read -p "请输入密码: " password
    echo -e "您输入的密码是: \e[1m\e[33m$password\e[0m"
    sleep 1
}    
################################回家配置脚本################################
install_home() {
    sleep 1 
    white "hysteria2 回家 自签证书"
    white "开始创建证书存放目录"
    mkdir -p /root/hysteria 
    white "自签bing.com证书100年"
    openssl ecparam -genkey -name prime256v1 -out /root/hysteria/private.key && openssl req -new -x509 -days 36500 -key /root/hysteria/private.key -out /root/hysteria/cert.pem -subj "/CN=bing.com"
    white "开始生成配置文件"
    # 检查sb配置文件是否存在
    config_file="/usr/local/etc/sing-box/config.json"
    if [ ! -f "$config_file" ]; then
        echo -e "\e[31m错误：配置文件 $config_file 不存在.\e[0m"
        echo -e "\e[31m请选择检查singbox或者创建config.json脚本.\e[0m"
        rm -rf /mnt/singbox.sh    #delete    
        exit 1
    fi   
    hy_config='{
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": '"${hyport}"',
      "sniff": true,
      "sniff_override_destination": false,
      "sniff_timeout": "100ms",
      "users": [
        {
          "password": "'"${password}"'"
        }
      ],
      "ignore_client_bandwidth": true,
      "tls": {
        "enabled": true,
        "alpn": [
          "h3"
        ],
        "certificate_path": "/root/hysteria/cert.pem",
        "key_path": "/root/hysteria/private.key"
      }
    },'
line_num=$(grep -n 'inbounds' /usr/local/etc/sing-box/config.json | cut -d ":" -f 1)
# 如果找到了行号，则在其后面插入 JSON 字符串，否则不进行任何操作
if [ ! -z "$line_num" ]; then
    # 将文件分成两部分，然后在中间插入新的 JSON 字符串
    head -n "$line_num" /usr/local/etc/sing-box/config.json > tmpfile
    echo "$hy_config" >> tmpfile
    tail -n +$(($line_num + 1)) /usr/local/etc/sing-box/config.json >> tmpfile
    mv tmpfile /usr/local/etc/sing-box/config.json
fi
    green "HY2回家配置写入完成"
    white "开始重启sing-box"
    systemctl restart sing-box
    white "开始生成sing-box回家-手机配置"
    wget -q -O /root/go_home.json https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/singbox/go_home.json
    home_config_file="/root/go_home.json"
    if [ ! -f "$home_config_file" ]; then
        echo -e "\e[31m错误：配置文件 $home_config_file 不存在.\e[0m"
        echo -e "\e[31m请检查网络可正常访问github后运行脚本.\e[0m"
        rm -rf /mnt/singbox.sh    #delete    
        exit 1
    fi
    sed -i "s|ip_cidr_ip|${ip}|g" /root/go_home.json
    sed -i "s/dns_domain/${domain}/g" /root/go_home.json
    sed -i "s/singbox_domain/${domain}/g" /root/go_home.json
    sed -i "s/singbox_hyport/${hyport}/g" /root/go_home.json
    sed -i "s/singbox_password/${password}/g" /root/go_home.json
}
################################ 删除 singbox ################################
del_singbox() {
    white "关闭sing-box"
    systemctl stop sing-box
    white "卸载sing-box自启动"
    systemctl disable sing-box
    white "关闭nftables防火墙规则"
    systemctl stop nftables
    white "nftables防火墙规则"
    systemctl disable nftables
    white "关闭sing-box路由规则"
    systemctl stop sing-box-router
    white "卸载sing-box路由规则"
    systemctl disable sing-box-router
    white "删除相关配置文件"
    rm -rf /etc/systemd/system/sing-box*
    rm -rf /etc/sing-box
    rm -rf /usr/local/bin/sing-box
    rm -rf /usr/local/etc/sing-box
    rm -rf /mnt/singbox.sh    #delete  
    green "卸载完成"
    echo "=================================================================="
    echo -e "\t\t\tSing-Box 卸载完成"
    echo -e "\n"
    echo -e "温馨提示:\n本脚本仅在ubuntu22.04环境下测试，其他环境未经验证 "
    echo "=================================================================="
}
################################ 删除 HY2回家 ################################
del_hy2() {
    white "删除HY2回家..."
    systemctl stop sing-box
    systemctl daemon-reload
    systemctl restart sing-box
    line_num_tag=$(grep -n '"tag": "hy2-in"' /usr/local/etc/sing-box/config.json | head -n 1 | cut -d ":" -f 1)
    if [ ! -z "$line_num_tag" ]; then
        line_num_start=$(head -n "$line_num_tag" /usr/local/etc/sing-box/config.json | grep -n '{' | tail -n 1 | cut -d ":" -f 1)
        line_num_end=$(tail -n +$(($line_num_tag + 1)) /usr/local/etc/sing-box/config.json | grep -n '},' | head -n 1 | cut -d ":" -f 1)
        line_num_end=$(($line_num_tag + $line_num_end))  # 补偿偏移量
        cp /usr/local/etc/sing-box/config.json /usr/local/etc/sing-box/config.json.bak       
        sed "${line_num_start},${line_num_end}d" /usr/local/etc/sing-box/config.json.bak > /usr/local/etc/sing-box/config.json
    fi
    white "删除相关配置文件"
    rm -rf /root/hysteria
    rm -rf /root/go_home.json
    rm -rf /mnt/singbox.sh    #delete  
    green "HY2回家卸载完成"
    echo "=================================================================="
    echo -e "\t\t\tSing-Box HY2回家配置卸载完成"
    echo -e "\n"
    echo -e "sing-box 配置已生成备份\n路径为: ${yellow}/usr/local/etc/sing-box/config.json.bak${reset}\n如配置出错需恢复，请自行修改。"
    echo -e "温馨提示:\n本脚本仅在ubuntu22.04环境下测试，其他环境未经验证 "
    echo "=================================================================="
}
################################sing-box 面板（metacubexd）升级################################
updata_singbox_ui_metacubexd() {
    FILE="/usr/local/etc/sing-box/ui"
    if [ ! -d "$FILE" ]; then
        red "未检测到 UI 文件，请检查是否安装，退出脚本"
        rm -rf /mnt/singbox.sh    #delete  
        exit 1
    else
        white "已检测到 UI 文件，开始升级..."
        rm -rf /usr/local/etc/sing-box/ui
        git clone https://github.com/metacubex/metacubexd.git -b gh-pages /usr/local/etc/sing-box/ui
        if [ ! -d "$FILE" ]; then
            red "文件下载失败，请保持网络畅通后重新运行脚本"
            rm -rf /mnt/singbox.sh    #delete             
            exit 1
        fi
        git -C /usr/local/etc/sing-box/ui pull -r
    fi    
    systemctl restart sing-box
    rm -rf /mnt/singbox.sh    #delete  
    local_ip=$(hostname -I | awk '{print $1}')
    echo "=================================================================="
    echo -e "\t\tsing-box 面板（metacubexd）升级完毕"
    echo -e "\n"
    echo -e "singbox WebUI地址:${yellow}http://$local_ip:9090${reset}"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，请\n打开${yellow}WebUI${reset}后${yellow}CTRL+F5刷新${reset}后查看"
    echo "=================================================================="    
}  
################################sing-box 面板切换（将原metacubexd切换为zashboard）################################
change_singbox_ui() {
    change_UI_DIR="/usr/local/etc/sing-box/Zephyruso/ui"
    change_CONFIG_FILE="/usr/local/etc/sing-box/config.json"
    change_REPO_URL="https://github.com/Zephyruso/zashboard.git"
    change_BRANCH="gh-pages"

    if [ -d "$change_UI_DIR" ]; then
        white "UI文件已存在，进行更新覆盖..."
        git -C "$change_UI_DIR" fetch --all && git -C "$change_UI_DIR" reset --hard "origin/$change_BRANCH"
    else
        white "开始下载UI文件..."
        git clone -b "$change_BRANCH" "$change_REPO_URL" "$change_UI_DIR"
    fi

    if [ $? -ne 0 ]; then
        red "下载UI文件失败，请检查网络或仓库地址！"
        exit 1
    fi

    white "正在修改sing-box ui 配置文件路径..."
    if [ -f "$change_CONFIG_FILE" ]; then
        sed -i 's|"external_ui": "/usr/local/etc/sing-box/ui",|"external_ui": "/usr/local/etc/sing-box/Zephyruso/ui",|' "$change_CONFIG_FILE"
    else
        red "配置文件不存在或修改失败，请检查路径！"
        exit 1
    fi
    systemctl restart sing-box
    rm -rf /mnt/singbox.sh    #delete  
    local_ip=$(hostname -I | awk '{print $1}')
    echo "=================================================================="
    echo -e "\t\tsing-box 面板切换完毕"
    echo -e "\n"
    echo -e "singbox WebUI地址:${yellow}http://$local_ip:9090${reset}"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，请\n打开${yellow}WebUI${reset}后将主机地址修改为本机IP，\n${yellow}点击提交${reset}查看"
    echo "=================================================================="    
} 
################################sing-box 面板（zashboard）升级################################
updata_singbox_ui_zashboard() {
    UI_DIR="/usr/local/etc/sing-box/Zephyruso/ui"
    UI_BACKUP_DIR="/usr/local/etc/sing-box/Zephyruso/ui_backup"

    if [ -d "$UI_DIR" ] && [ "$(find "$UI_DIR" -mindepth 1 | read)" ]; then
        white "开始备份UI文件夹..."
        if [ -d "$UI_BACKUP_DIR" ]; then
            if ! rm -rf "$UI_BACKUP_DIR"; then
                red "删除备份目录失败，请检查权限！"
                exit 1
            fi
        fi

        if ! mv "$UI_DIR" "$UI_BACKUP_DIR"; then
            red "移动目录失败，请检查权限或空间！"
            exit 1
        fi
    fi

    white "开始更新 UI ..."
    if ! git clone https://github.com/Zephyruso/zashboard.git -b gh-pages "$UI_DIR"; then
        red "UI 更新失败，请检查网络连接或仓库地址！"
        exit 1
    fi

    systemctl restart sing-box
    rm -rf /mnt/singbox.sh    #delete  
    local_ip=$(hostname -I | awk '{print $1}')
    echo "=================================================================="
    echo -e "\t\tsing-box 面板（zashboard）升级完毕"
    echo -e "\n"
    echo -e "singbox WebUI地址:${yellow}http://$local_ip:9090/ui/#/settings${reset}"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，请\n打开${yellow}WebUI${reset}后${yellow}CTRL+F5刷新${reset}后查看"
    echo "=================================================================="    
}       
################################sing-box安装结束################################
install_sing_box_over() {
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
        echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，目前程序未\n运行，请自行修改运行目录下配置文件后运行\e[1m\e[33msystemctl restart sing-box\e[0m\n命令运行程序。"
        echo "=================================================================="
    fi
}
################################ HY2回家结束 ################################
install_hy2_home_over() {
    rm -rf /mnt/singbox.sh    #delete   
    echo "=================================================================="
    echo -e "\t\t\tSing-Box 回家配置生成完毕"
    echo -e "\n"
    echo -e "sing-box 回家配置生成路径为: ${yellow}/root/go_home.json${reset}请自行复制至 sing-box 客户端"
    echo -e "温馨提示:\n本脚本仅在ubuntu22.04环境下测试，其他环境未经验证 "
    echo "================================================================="
}
################################ 添加节点执行 ################################
add_node_operation() {
    if [[ "$node_operation" == "1" ]]; then
        add_node_code='
            {
                "type": "vless",
                "tag": "'"${vless_tag}"'",
                "uuid": "'"${vless_uuid}"'",
                "packet_encoding": "xudp",
                "server": "'"${vless_server_ip}"'",
                "server_port": '"${vless_port}"',
                "flow": "",
                "tls": {
                    "enabled": true,
                    "server_name": "'"${vless_domain}"'",
                    "utls": {
                        "enabled": true,
                        "fingerprint": "chrome"
                    },
                    "reality": {
                        "enabled": true,
                        "public_key": "'"${vless_public_key}"'",
                        "short_id": "'"${vless_short_id}"'"
                    }
                },
                "multiplex": {
                    "enabled": true,
                    "protocol": "h2mux",
                    "max_connections": 1,
                    "min_streams": 2,
                    "padding": true,
                    "brutal": {
                        "enabled": true,
                        "up_mbps": '"${vless_up_mbps}"',
                        "down_mbps": '"${vless_down_mbps}"'
                    }
                }
            },'
    elif [[ "$node_operation" == "2" ]]; then
        add_node_code='
            {
                "type": "hysteria2",
                "tag": "'"${hy2_pass_tag}"'",
                "server": "'"${hy2_pass_server_ip}"'",
                "server_port": '"${hy2_pass_port}"',
                "up_mbps": '"${hy2_pass_up_mbps}"',
                "down_mbps": '"${hy2_pass_down_mbps}"',
                "password": "'"${hy2_pass_password}"'",
                "tls": {
                    "enabled": true,
                    "server_name": "'"${hy2_pass_domain}"'"
                },
                "brutal_debug": false
            },'
    fi
    add_node_line_num=$(grep -n '"outbounds": \[' /usr/local/etc/sing-box/config.json | head -n 1 | cut -d ":" -f 1)
    # 如果找到了行号，则在其下一行插入 JSON 字符串
    if [ ! -z "$add_node_line_num" ]; then
        # 将文件分成两部分，然后在 "outbounds": [ 行的下一行插入新的 JSON 字符串
        head -n "$add_node_line_num" /usr/local/etc/sing-box/config.json > tmpfile
        echo "$add_node_code" >> tmpfile
        tail -n +$(($add_node_line_num + 1)) /usr/local/etc/sing-box/config.json >> tmpfile
        mv tmpfile /usr/local/etc/sing-box/config.json
    fi
    green "已添加出站节点到 Outbounds"
    add_node_file="/usr/local/etc/sing-box/config.json"
    cp "$add_node_file" "${add_node_file%.json}_backup_$(date +%Y%m%d).json"
    white "已备份配置文件到 $backup_file"
    # 使用 jq 插入新的 add_tag 到 ♾️ Global 的 outbounds 下
    jq '(.outbounds[] | select(.tag == "♾️ Global").outbounds) += ["'"$add_tag"'"]' "$add_node_file" > tmp.json && mv tmp.json "$add_node_file"
    green "已添加节点 $add_tag 到 ♾️ Global 的 outbounds "
}
################################ 添加节点循环&结束 ################################
add_node_over() {
    systemctl stop sing-box && systemctl daemon-reload && systemctl restart sing-box 
    echo "=================================================================="
    echo -e "\t\tSing-Box节点添加 配置完成"
    echo -e "\n"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证"
    echo -e "${yellow}请根据下面提示完成脚本后续操作${reset}"
    echo "=================================================================="
    while true; do
        white "请选择后续操作:"        
        white "1. ${yellow}退出脚本${reset} [默认选项]"
        white "2. 继续新增代理操作"
        read -p "请选择: " add_node_continue_choose
        add_node_continue_choose=${add_node_continue_choose:-1}
        if [[ "$add_node_continue_choose" =~ ^[12]$ ]]; then
            break
        else
            white "无效的选项，请输入1或2"
        fi
    done
    if [[ "$add_node_continue_choose" == "2" ]]; then
        add_node_flow_path
    else
        red "退出脚本，感谢使用."
        [ -f /mnt/singbox.sh ] && rm -rf /mnt/singbox.sh    #delete
        exit 1    
    fi
}
################################ 添加节点流程 ################################
add_node_flow_path() {
    custom_node
    add_node_operation
    add_node_over
}
################################ 主程序 ################################
singbox_choose