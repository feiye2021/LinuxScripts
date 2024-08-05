#!/bin/bash

# 检查是否为root用户执行
[[ $EUID -ne 0 ]] && echo -e "错误：必须使用root用户运行此脚本！\n" && exit 1

################################入口################################
main() {
    home
}
################################主菜单################################
home() {
    clear
    echo "=================================================================="
    echo -e "\t\t自用安装脚本 by 忧郁滴飞叶"
    echo -e "\t\n"
    echo -e "温馨提示：\n本脚本推荐使用ububtu22.04环境，其他环境未经验证，仅供个人使用"
    echo "=================================================================="
    echo "1. IP"
    echo "2. HostName"
    echo "3. 基础环境设置"    
    echo "4. MosDNS"
    echo "5. Sing-box"
    echo -e "\t"    
    echo "0. 退出脚本"        
    read choice
    case $choice in
        1)
            # ip_choose
            echo "脚本切换中，请等待..."
            wget -q -O /mnt/ip.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/ip.sh && chmod +x /mnt/ip.sh && /mnt/ip.sh
            ;;
        2)
            hostname_choose
            ;;
        3)
            basic_choose
            ;;            
        4)
            mosdns_choose
            ;;
        5)
            singbox_choose
            ;;
        0)
            echo -e "\e[31m退出脚本，感谢使用.\e[0m"
            ;;    
        *)
            echo "无效的选项，2秒后返回当前菜单，请重新选择有效的选项."
            sleep 2
            home
            ;;
esac 
}

################################ IP 选择 ################################
ip_choose() {
    clear
    echo "=================================================================="
    echo -e "\t\tIP 选择脚本 by 忧郁滴飞叶"
    echo -e "\t\n"
    echo "请选择要设置的网络模式，设置完成后脚本将自动重启系统："
    echo "=================================================================="
    echo "1. 静态IP"
    echo "2. DHCP"
    echo -e "\t"
    echo "-. 返回上级菜单"    
    echo "0. 退出脚本"
    read -p "输入选项（1或2）： " choice
    case $choice in
        1)
            ip_checking
            static_ip_setting
            ;;
        2)
            ip_checking
            dhcp_setting
            ;;
        0)
            echo -e "\e[31m退出脚本，感谢使用.\e[0m"
            ;;
        -)
            home
            ;;            
        *)
            echo "无效的选项，2秒后返回当前菜单，请重新选择有效的选项."
            sleep 2
            ip_choose
            ;;
    esac 
}
################################ 主机名选择 ################################
hostname_choose() {
    hostname_setting
}
################################ 基础环境设置 选择 ################################
basic_choose() {
    clear
    echo "=================================================================="
    echo -e "\t\t基础环境设置脚本 by 忧郁滴飞叶"
    echo -e "\t\n"   
    echo "请选择要操作的基本设置："
    echo "=================================================================="   
    echo "1. Update & Upgrade"
    echo "2. 安装程序依赖"
    echo "3. 设置时区为Asia/Shanghai"
    echo "4. 设置NTP为ntp.aliyun.com"    
    echo "5. 关闭53端口监听"
    echo -e "\t"
    echo "9. 一键安装以上所有基础设置"
    echo "-. 返回上级菜单"      
    echo "0. 退出脚本"            
    read -p "输入选项： " choice
    case $choice in
        1)
            apt_update_upgrade
            ;;
        2)
            apt_install
            ;;    
        3)
            set_timezone
            ;;
        4)
            set_ntp
            ;;                        
        5)
            modify_dns_stub_listener
            ;;
        9)
            echo "一键安装所有基础设置..."
            apt_update_upgrade
            apt_install
            set_timezone
            set_ntp
            modify_dns_stub_listener
            ;;
        0)
            echo -e "\e[31m退出脚本，感谢使用.\e[0m"
            ;;
        -)
            home
            ;;                                
        *)
            echo "无效的选项，2秒后返回当前菜单，请重新选择有效的选项."
            sleep 2
            basic_choose
            ;;
    esac 
}
################################ MosDNS选择 ################################
mosdns_choose() {
    clear
    echo "=================================================================="
    echo -e "\t\tMosDNS相关脚本 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo "请选择要执行的服务："
    echo "=================================================================="
    echo "1. 安装Mosdns"
    echo "2. 重置Mosdns缓存"
    echo "3. 安装Mosdns UI"
    echo "4. 卸载Mosdns"
    echo "5. 卸载Mosdns UI"
    echo -e "\t"
    echo "8. 一键安装Mosdns及UI面板"
    echo "9. 一键卸载Mosdns及UI面板"
    echo "-. 返回上级菜单"          
    echo "0) 退出脚本"        
    read choice
    case $choice in
        1)
            echo "安装Mosdns"
            install_mosdns
            ;;
        2)
            echo "重置Mosdns缓存"
            del_mosdns_cache || exit 1
            ;;        
        3)
            echo "安装Mosdns UI"
            install_mosdns_ui
            ;;
        4)
            echo "卸载Mosdns"
            del_mosdns || exit 1
            ;;
        5)
            echo "卸载Mosdns UI"
            del_mosdns_ui || exit 1
            ;;
        8)
            echo "一键安装Mosdns及UI面板"
            install_mosdns_ui_all
            ;;
        9)
            echo "一键卸载Mosdns及UI面板"
            del_mosdns || exit 1
            del_mosdns_ui || exit 1
            ;;
        0)
            echo -e "\e[31m退出脚本，感谢使用.\e[0m"
            ;;
        -)
            home
            ;;                              
        *)
            echo "无效的选项，2秒后返回当前菜单，请重新选择有效的选项."
            sleep 2
            mosdns_choose
            ;;
    esac
}
# ################################ Sing-Box选择 ################################
singbox_choose() {
    clear
    echo "=================================================================="
    echo -e "\t\tSing-Box相关脚本 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo "欢迎使用Sing-Box相关脚本"
    echo "请选择要执行的服务："
    echo "=================================================================="
    echo "1. 安装官方sing-box/升级"
    echo "2. hysteria2 回家"
    echo "3. 卸载sing-box" 
    echo "4. 卸载hysteria2 回家"
    echo -e "\t"
    echo "9. 一键卸载singbox及HY2回家"
    echo "-. 返回上级菜单"      
    echo "0) 退出脚本"
    read choice
    case $choice in
        1)
            echo "开始安装官方Singbox核心"
            apt_update_upgrade
            apt_install
            set_timezone
            set_ntp
            install_singbox
            install_service
            install_config
            install_tproxy
            install_sing_box_over
            ;;
        2)
            echo "开始生成回家配置"
            hy2_custom_settings
            install_home
            install_hy2_home_over
            ;;
        3)
            echo "卸载sing-box核心程序及其相关配置文件"    
            del_singbox
            ;;
        4)
            echo "卸载HY2回家配置及其相关配置文件"       
            del_hy2
            ;;
        9)
            echo "一键卸载singbox及HY2回家"    
            del_singbox
            echo "删除相关配置文件"
            rm -rf /root/hysteria
            rm -rf /root/go_home.json
            echo -e "\n\e[1m\e[37m\e[42mHY2回家卸载完成\e[0m\n"
            ;;            
        0)
            echo -e "\e[31m退出脚本，感谢使用.\e[0m"
            ;;
        -)
            home
            ;;              
        *)
            echo "无效的选项，2秒后返回当前菜单，请重新选择有效的选项."
            sleep 2
            singbox_choose
            ;;
    esac
}
################################ 网卡及网络设置文件检测 ################################
ip_checking() {
    NETPLAN_DIR="/etc/netplan"
    NETPLAN_FILES=($NETPLAN_DIR/*.yaml)
    INTERFACES=($(ls /sys/class/net | grep -v lo))
    if [[ ${#INTERFACES[@]} -gt 1 ]]; then
        echo "检测到多个网卡，请选择要修改的网卡："
        select INTERFACE in "${INTERFACES[@]}"; do
            if [[ -n "$INTERFACE" ]]; then
                NET_INTERFACE="$INTERFACE"
                break
            fi
        done
    elif [[ ${#INTERFACES[@]} -eq 1 ]]; then
        NET_INTERFACE="${INTERFACES[0]}"
    else
        echo "未找到网络接口，脚本退出。"
        exit 1
    fi
    if [[ ${#NETPLAN_FILES[@]} -gt 1 ]]; then
        echo "检测到多个Netplan文件，请选择要修改的文件："
        select FILE in "${NETPLAN_FILES[@]}"; do
            if [[ -n "$FILE" ]]; then
                NETPLAN_FILE="$FILE"
                break
            fi
        done
    elif [[ ${#NETPLAN_FILES[@]} -eq 1 ]]; then
        NETPLAN_FILE="${NETPLAN_FILES[0]}"
    else
        echo "未找到Netplan网络配置文件，脚本退出。"
        exit 1
    fi
}
################################ 设置静态IP ################################
static_ip_setting() {
    read -p "请输入静态IP地址（例如10.10.10.2）： " static_ip
    echo -e "您输入的静态IP地址为：\e[1m\e[33m$static_ip\e[0m。"
    read -p "请输入子网掩码（例如24，回车默认为24）： " netmask
    netmask="${netmask:-24}"
    echo -e "您输入的子网掩码为：\e[1m\e[33m$netmask\e[0m。"
    read -p "请输入网关地址（例如10.10.10.1）： " gateway
    echo -e "您输入的网关地址为：\e[1m\e[33m$gateway\e[0m。"
    read -p "请输入DNS服务器地址（例如10.10.10.3）： " dns
    echo -e "您输入的DNS服务器地址为：\e[1m\e[33m$dns\e[0m。"
    sudo cp "$NETPLAN_FILE" "$NETPLAN_FILE.bak"
    sudo bash -c "cat > $NETPLAN_FILE" <<EOL
network:
    version: 2
    ethernets:
        $NET_INTERFACE:
            addresses:
                - $static_ip/$netmask
            nameservers:
                addresses:
                    - $dns
            routes:
                - to: default
                  via: $gateway
EOL
    sudo netplan apply
    if [[ $? -eq 0 ]]; then
        echo -e "静态IP已设置为：\e[1m\e[33m$static_ip\e[0m，系统即将重启。"
        sleep 1
        sudo reboot
    else
        echo "设置静态IP失败，请检查配置。"
        exit 1
    fi
}

################################ 设置DHCP ################################
dhcp_setting() {
    if grep -q "dhcp4: true" "$NETPLAN_FILE"; then
        echo "当前已经是DHCP配置，无需修改。"
    else
        sudo cp "$NETPLAN_FILE" "$NETPLAN_FILE.bak"
        sudo bash -c "cat > $NETPLAN_FILE" <<EOL
network:
    version: 2
    ethernets:
        $NET_INTERFACE:
            dhcp4: true
EOL
        sudo netplan apply
        if [[ $? -eq 0 ]]; then
            echo -e "已设置为\e[1m\e[33mDHCP模式\e[0m，系统即将重启。"
            sleep 1
            sudo reboot
        else
            echo "设置DHCP模式失败，请检查配置。"
            exit 1
        fi
    fi
}

################################ 主机名设置 ################################
hostname_setting() {
    current_hostname=$(hostname)
    clear
    echo "=================================================================="
    echo -e "\t\tHostName修改脚本 by 忧郁滴飞叶"
    echo -e "\t\n"
    echo -e "当前的主机名是:\e[1m\e[33m$current_hostname\e[0m，脚本完成后将自动重启以应用设置。"
    echo "=================================================================="
    read -p "请输入新的主机名: " new_hostname
    if [[ -z "$new_hostname" ]]; then
        echo "主机名不能为空，脚本退出。"
        exit 1
    fi
    echo "$new_hostname" | sudo tee /etc/hostname
    sudo sed -i "s/$current_hostname/$new_hostname/g" /etc/hosts
    sudo hostnamectl set-hostname "$new_hostname"
    echo -e "新的主机名已设置为:\e[1m\e[33m$new_hostname\e[0m，系统即将重启。"
    sleep 1
    sudo reboot
}
################################更新环境################################
apt_update_upgrade() {
    echo -e "配置基础设置并安装依赖..."
    sleep 1
    apt update -y
    apt -y upgrade || { echo "\n\e[1m\e[37m\e[41m环境更新失败！退出脚本\e[0m\n"; exit 1; }
    echo -e "\n\e[1m\e[37m\e[42m环境更新成功\e[0m\n"
}
################################安装相关依赖################################
apt_install() {
    echo -e "环境依赖安装开始..."
    apt install curl wget tar gawk sed cron unzip nano sudo vim sshfs net-tools nfs-common bind9-host adduser libfontconfig1 musl git build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64 -y || { echo -e "\n\e[1m\e[37m\e[41m环境依赖安装失败！退出脚本\e[0m\n"; exit 1; }
    echo -e "\n\e[1m\e[37m\e[42m环境依赖安装成功\e[0m\n"
}
################################设置时区################################
set_timezone() {
    timedatectl set-timezone Asia/Shanghai || { echo -e "\n\e[1m\e[37m\e[41m时区设置失败！退出脚本\e[0m\n"; exit 1; }
    echo -e "\n\e[1m\e[37m\e[42m时区设置成功\e[0m\n"
}
################################设置NTP################################    
set_ntp() {    
    ntp_config="NTP=ntp.aliyun.com"
    echo "$ntp_config" | sudo tee -a /etc/systemd/timesyncd.conf > /dev/null
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-timesyncd
    echo -e "\n\e[1m\e[37m\e[42m已将 NTP 服务器配置为 ntp.aliyun.com\e[0m\n"
}
################################ 关闭 53监听 ################################
modify_dns_stub_listener() {
    sed -i '/^#*DNSStubListener/s/#*DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf || { echo -e "\n\e[1m\e[37m\e[41m关闭53端口监听失败！退出脚本\e[0m\n"; exit 1; }
    systemctl restart systemd-resolved.service || { echo -e "\n\e[1m\e[37m\e[41m重启 systemd-resolved.service 失败！退出脚本\e[0m\n"; exit 1; }
    echo -e "\n\e[1m\e[37m\e[42m关闭53端口监听成功\e[0m\n"
}
################################编译 Sing-Box 的最新版本################################
install_singbox() {
    echo -e "编译Sing-Box 最新版本"
    # mkdir /mnt/singbox && cd /mnt/singbox
    sleep 1
    apt -y install curl git build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64
    echo -e "开始编译Sing-Box 最新版本"
    rm -rf /root/go/bin/*
    curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz -o go1.22.4.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
    echo "下载go文件完成"
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/golang.sh
    source /etc/profile.d/golang.sh
    echo "开始go文件安装"
    go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@latest
    echo "等待检测安装状态"    
    if ! go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@latest; then
        echo -e "Sing-Box 编译失败！退出脚本"
        exit 1
    fi
    echo -e "编译完成，开始安装"
    sleep 1
    if [ -f "/usr/local/bin/sing-box" ]; then
        echo "检测到已安装的 sing-box"
        read -p "是否替换升级？(y/n): " replace_confirm
        if [ "$replace_confirm" = "y" ]; then
            echo "正在替换升级 sing-box"
            cp "$(go env GOPATH)/bin/sing-box" /usr/local/bin/
echo "=================================================================="
echo -e "\t\t\tSing-Box 升级完毕"
echo -e "\n"
echo -e "温馨提示:\n本脚本仅在ubuntu22.04环境下测试，其他环境未经验证，仅供个人使用"
echo "=================================================================="
            exit 0
        else
            echo "用户取消了替换升级操作"
        fi
    else
        echo -e "未安装Sing-Box ，开始安装"

        cp $(go env GOPATH)/bin/sing-box /usr/local/bin/
        echo -e "Sing-Box 安装完成"
    fi

    mkdir -p /usr/local/etc/sing-box
    sleep 1
}
################################启动脚本################################
install_service() {
    echo -e "配置系统服务文件"
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
    echo "sing-box服务创建完成"  
else
    # 如果服务文件已经存在，则给出警告
    echo "警告：sing-box服务文件已存在，无需创建"
fi 
    sleep 1
    systemctl daemon-reload 
}
################################写入配置文件################################
install_config() {
echo '


' > /usr/local/etc/sing-box/config.json
}
################################安装tproxy################################
install_tproxy() {
    sleep 1
    echo "创建系统转发..."   
    if ! grep -q '^net.ipv4.ip_forward=1$' /etc/sysctl.conf; then
        echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    fi
    if ! grep -q '^net.ipv6.conf.all.forwarding = 1$' /etc/sysctl.conf; then
        echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
    fi
    echo "系统转发创建完成"
    echo "开始创建nftables tproxy转发..."
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
    echo "sing-box-router 服务创建完成"
else
    echo "警告：sing-box-router 服务文件已存在，无需创建"
fi
    echo "开始写入nftables tproxy规则..."
echo "" > "/etc/nftables.conf"
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
		iifname { lo, ens18 } meta l4proto { tcp, udp } ct direction original goto singbox-tproxy
	}
}
EOF
    echo "nftables规则写入完成"
    nft flush ruleset
    nft -f /etc/nftables.conf
    systemctl enable --now nftables
    echo -e "\n\e[1m\e[37m\e[42mNftables tproxy转发创建完成\e[0m\n"
    install_over
}
################################sing-box安装结束################################
install_over() {
    echo "开始启动sing-box..."
    systemctl enable --now sing-box-router
    systemctl enable --now sing-box
    echo -e "\n\e[1m\e[37m\e[42mSing-box启动已完成\e[0m\n"
}
################################ HY2回家自定义设置 ################################
hy2_custom_settings() {
    while true; do
        # 提示用户输入域名
        read -p "请输入家庭DDNS域名: " domain
        # 检查域名格式是否正确
        if [[ $domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            echo -e "\e[31m域名格式不正确，请重新输入\e[0m"
        fi
    done
    echo -e "您输入的域名是: \e[1m\e[33m$domain\e[0m"
    # 输入端口号
    while true; do
        read -p "请输入端口号: " hyport

        # 检查端口号是否为数字
        if [[ $hyport =~ ^[0-9]+$ ]]; then
            break
        else
            echo -e "\e[31m端口号格式不正确，请重新输入\e[0m"
        fi
    done
    echo -e "您输入的端口号是: \e[1m\e[33m$hyport\e[0m"
    read -p "请输入局域网IP网段（示例：10.0.0.0/24）: " ip
    echo -e "您输入的局域网IP网段是: \e[1m\e[33m$ip\e[0m"    
    read -p "请输入密码: " password
    echo -e "您输入的密码是: \e[1m\e[33m$password\e[0m"
    sleep 1
}    
################################回家配置脚本################################
install_home() {
    sleep 1 
    echo -e "hysteria2 回家 自签证书"
    echo -e "开始创建证书存放目录"
    mkdir -p /root/hysteria 
    echo -e "自签bing.com证书100年"
    openssl ecparam -genkey -name prime256v1 -out /root/hysteria/private.key && openssl req -new -x509 -days 36500 -key /root/hysteria/private.key -out /root/hysteria/cert.pem -subj "/CN=bing.com"
    echo "开始生成配置文件"
    # 检查sb配置文件是否存在
    config_file="/usr/local/etc/sing-box/config.json"
    if [ ! -f "$config_file" ]; then
        echo "错误：配置文件 $config_file 不存在"
        echo "请选择检查singbox或者P核singbox config.json脚本"        
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
    echo "HY2回家配置写入完成"
    echo "开始重启sing-box"
    systemctl restart sing-box
    echo "开始生成sing-box回家-手机配置"
    cat << EOF >  "/root/go_home.json"
{
    "log": {
        "level": "info",
        "timestamp": false
    },
    "dns": {
        "servers": [     
            {
                "tag": "dns_proxy",
                "address": "tls://8.8.8.8:853",
                "strategy": "prefer_ipv4",
                "detour": "proxy",
                "client_subnet": "183.195.1.1"
            },
            {
                "tag": "dns_direct",
                "address": "https://223.5.5.5/dns-query",
                "strategy": "prefer_ipv4",
                "detour": "direct"
            },
            {
                "tag": "dns_resolver",
                "address": "223.5.5.5",
                "detour": "direct"
            },
            {
                "tag": "dns_success",
                "address": "rcode://success"
            },
            {
                "tag": "dns_refused",
                "address": "rcode://refused"
            },
            {
                "tag": "dns_fakeip",
                "address": "fakeip",
                "detour": "proxy"
            }
        ],
        "rules": [
            {
                "domain_suffix": [
                    "${domain}"         
                ],
                "server": "dns_direct",
                "disable_cache": true
            },           
            {
                "domain_suffix": [
                    "office365.com",
                    "office.com",
                    "push-apple.com.akadns.net",
                    "push.apple.com",
                    "time.apple.com",
                    "gs-loc-cn.apple.com",
                    "iphone-ld.apple.com",
                    "lcdn-locator.apple.com",
                    "lcdn-registration.apple.com"
                ],
                "server": "dns_direct",
                "disable_cache": true
            },
            {
                "rule_set": "geosite-cn",
                "query_type": [
                    "A",
                    "AAAA"
                ],
                "server": "dns_direct"
            },
            {
                "rule_set": "geosite-cn",
                "query_type": [
                    "CNAME"
                ],
                "server": "dns_direct"
            },      
            {
                "rule_set": "geosite-geolocation-!cn",
                "query_type": [
                    "A",
                    "AAAA"
                ],
                "server": "dns_fakeip"
            },
            {
                "rule_set": "geosite-geolocation-!cn",
                "query_type": [
                    "CNAME"
                ],
                "server": "dns_proxy"
            },
            {
                "query_type": [
                    "A",
                    "AAAA",
                    "CNAME"
                ],
                "invert": true,
                "server": "dns_refused",
                "disable_cache": true
            }
        ],
        "final": "dns_proxy",
        "independent_cache": true,
        "fakeip": {
            "enabled": true,
            "inet4_range": "198.18.0.0/15",
            "inet6_range": "fc00::/18"
        }
    },
    "route": {
        "rule_set": [
            {
                "tag": "geosite-category-ads-all",
                "type": "remote",
                "format": "binary",
                "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs",
                "download_detour": "proxy"
            },
      {
        "tag": "geosite-netflix",
        "type": "remote",
        "format": "binary",
        "url": "https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@sing/geo/geosite/netflix.srs",
        "download_detour": "proxy"
      },
        {
                "tag": "geosite-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-cn.srs",
                "download_detour": "proxy"
            },  
            {
                "tag": "geosite-geolocation-!cn",
                "type": "remote",
"format": "binary",
                "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-geolocation-!cn.srs",
                "download_detour": "proxy"
            },
            {
                "tag": "geoip-cn",
                "type": "remote",
                "format": "binary",
                "url": "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs",
                "download_detour": "proxy"
            }
        ],
        "rules": [
            {
                "protocol": "dns",
                "outbound": "dns-out"
            },
            {
               "ip_cidr": [
                 "${ip}"
               ],
               "outbound": "proxy"
            },
       {
        "network": "udp",
        "port": 443,
        "outbound": "block"
        },
         {   
        "protocol": "stun",   
        "outbound": "block"   
         }, 
         {
      "domain_suffix": [ 
          ".cn"
        ],
        "outbound": "direct"
        },
        {
      "domain_suffix": [ 
          "office365.com",
          "office.com"
        ],
        "outbound": "direct"
        },
        {
        "domain_suffix": [
          "push.apple.com",
          "time.apple.com",
          "push-apple.com.akadns.net",
          "gs-loc-cn.apple.com",
          "iphone-ld.apple.com",
          "lcdn-locator.apple.com",
          "lcdn-registration.apple.com"
        ],
        "outbound": "direct"
        },
        {
                "rule_set": "geosite-cn",
                "outbound": "direct"
            },
            {
                "rule_set": "geosite-geolocation-!cn",
                "outbound": "proxy"
            },
            {
                "rule_set": "geoip-cn",
                "outbound": "direct"
            },
            {
                "ip_is_private": true,
                "outbound": "direct"
            }
        ],
        "final": "proxy",
        "auto_detect_interface": true
    },
    "inbounds": [
        {
            "type": "tun",
            "tag": "tun-in",
            "inet4_address": "172.16.0.1/30",
            "inet6_address": "fd00::1/126",
            "mtu": 1400,
            "auto_route": true,
            "strict_route": true,
            "stack": "gvisor",
            "sniff": true,
            "sniff_override_destination": false
        }
    ],
    "outbounds": [
        {
            "tag":"proxy",
            "type":"selector",
            "outbounds":[
            "telecom_home"
          ]
        },
        {
         "type": "hysteria2",
         "server": "${domain}",       
         "server_port": ${hyport}, 
         "tag": "telecom_home", 
         "up_mbps": 50,
         "down_mbps": 500,
         "password": "${password}",
         "tls": {
         "enabled": true,
         "server_name": "bing.com",   
         "insecure": true,
         "alpn": [
          "h3"
            ]
          }
        },
        {
            "type": "direct",
            "tag": "direct"
        },
        {
            "type": "block",
            "tag": "block"
        },
        {
            "type": "dns",
            "tag": "dns-out"
        }
    ],
    "experimental": {
        "cache_file": {
            "enabled": true,
            "path": "cache.db",
            "store_fakeip": true
        }
    }
}
EOF
}
################################ 删除 singbox ################################
del_singbox() {
    echo "关闭sing-box"
    systemctl stop sing-box
    echo "卸载sing-box自启动"
    systemctl disable sing-box
    echo "关闭nftables防火墙规则"
    systemctl stop nftables
    echo "nftables防火墙规则"
    systemctl disable nftables
    echo "关闭sing-box路由规则"
    systemctl stop sing-box-router
    echo "卸载sing-box路由规则"
    systemctl disable sing-box-router
    echo "删除相关配置文件"
    rm -rf /etc/systemd/system/sing-box*
    rm -rf /etc/sing-box
    rm -rf /usr/local/bin/sing-box
    rm -rf /usr/local/etc/sing-box
    echo -e "\n\e[1m\e[37m\e[42m卸载完成\e[0m\n"
}
################################ 删除 HY2回家 ################################
del_hy2() {
    echo "删除HY2回家..."
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
    echo "删除相关配置文件"
    rm -rf /root/hysteria
    rm -rf /root/go_home.json
    echo -e "\n\e[1m\e[37m\e[42mHY2回家卸载完成\e[0m\n"
}
################################安装 mosdns################################
install_mosdns() {
    mkdir /mnt/mosdns && cd /mnt/mosdns
    local mosdns_host="https://github.com/IrineSistiana/mosdns/releases/download/v5.3.1/mosdns-linux-amd64.zip"
    mosdns_customize_settings || exit 1
    apt_update_upgrade || exit 1
    apt_install || exit 1
    set_timezone || exit 1
    set_ntp || exit 1
    modify_dns_stub_listener || exit 1
    download_mosdns || exit 1
    extract_and_install_mosdns || exit 1
    configure_mosdns || exit 1
    enable_autostart || exit 1
    install_complete
}
################################ MosDNS及UI一键 ################################
install_mosdns_ui_all() {
    echo "开始安装MosDNS ..."   
    mkdir /mnt/mosdns && cd /mnt/mosdns
    local mosdns_host="https://github.com/IrineSistiana/mosdns/releases/download/v5.3.1/mosdns-linux-amd64.zip"
    mosdns_customize_settings || exit 1
    apt_update_upgrade || exit 1
    apt_install || exit 1
    set_timezone || exit 1
    set_ntp || exit 1
    modify_dns_stub_listener || exit 1
    download_mosdns || exit 1
    extract_and_install_mosdns || exit 1
    configure_mosdns || exit 1
    enable_autostart || exit 1
    systemctl restart mosdns
    echo "开始安装MosDNS UI..."    
    install_loki || exit 1
    install_vector || exit 1
    install_prometheus || exit 1
    install_grafana || exit 1
    install_complete_all
}
################################用户自定义设置################################
mosdns_customize_settings() {
    echo -e "\n自定义设置（以下设置可直接回车使用默认值）"
    read -p "输入sing-box入站地址：端口（默认10.10.10.2:6666）：" uiport
    uiport="${uiport:-10.10.10.2:6666}"
    echo -e "已设置Singbox入站地址：\e[1m\e[33m$uiport\e[0m"
    read -p "输入国内DNS解析地址：端口（默认223.5.5.5:53）：" localport
    localport="${localport:-223.5.5.5:53}"
    echo -e "已设置国内DNS地址：\e[1m\e[33m$localport\e[0m"
}
################################下载 mosdns################################
download_mosdns() {
    echo "开始下载 mosdns v5.3.1"
    wget "${mosdns_host}" || { echo -e "\n\e[1m\e[37m\e[41m下载失败！退出脚本\e[0m\n"; exit 1; }
}
################################解压并安装 mosdns################################
extract_and_install_mosdns() {
    echo "开始安装MosDNS..."
    unzip mosdns-linux-amd64.zip -d /etc/mosdns
    cd /etc/mosdns
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
ExecStart=/usr/local/bin/mosdns start -c /etc/mosdns/config.yaml -d /etc/mosdns

[Install]
WantedBy=multi-user.target
EOF

    echo -e "\n\e[1m\e[37m\e[42mMosDNS服务已安装完成\e[0m\n"
}
################################# 配置 mosdns ################################
configure_mosdns() {
    echo "开始配置MosDNS规则..."
    mkdir /etc/mosdns/rule
    touch /etc/mosdns/rule/{whitelist,blocklist,greylist,ddnslist,hosts,redirect,adlist,localptr}.txt
    cd /etc/mosdns/rule
    echo "keyword:.localdomain" >> blocklist.txt
    echo "domain:in-addr.arpa" >> blocklist.txt
    echo "domain:ip6.arpa" >> blocklist.txt
    echo "# block all PTR requests" >> localptr.txt
    echo "domain:in-addr.arpa" >> localptr.txt
    echo "domain:ip6.arpa" >> localptr.txt
    echo "domain:googleapis.cn" >> greylist.txt
    echo "domain:gstatic.com" >> greylist.txt
    echo "domain:googleapis.com" >> greylist.txt
    echo "domain:google.com" >> greylist.txt
    echo "domain:services.googleapis.cn" >> greylist.txt
    echo "domain:docker.io" >> greylist.txt
    echo "domain:push-apple.com.akadns.net" >> whitelist.txt
    echo "domain:push.apple.com" >> whitelist.txt
    echo "domain:iphone-ld.apple.com" >> whitelist.txt
    echo "domain:lcdn-locator.apple.com" >> whitelist.txt
    echo "domain:lcdn-registration.apple.com" >> whitelist.txt
    echo "domain:cn-ssl.ls.apple.com" >> whitelist.txt
    echo "domain:time.apple.com" >> whitelist.txt
    echo "domain:store.ui.com.cn" >> whitelist.txt
    echo "domain:amd.com" >> whitelist.txt
    echo "domain:msftncsi.com" >> whitelist.txt
    echo "domain:msftconnecttest.com" >> whitelist.txt
    echo "domain:office.com" >> whitelist.txt
    echo "domain:office365.com" >> whitelist.txt
    echo "domain:apple.cn" >> whitelist.txt
    echo "full:gs-loc-cn.apple.com" >> whitelist.txt
    echo "full:gsp10-ssl-cn.ls.apple.com" >> whitelist.txt
    echo "full:gsp12-cn.ls.apple.com" >> whitelist.txt
    echo "full:gsp13-cn.ls.apple.com" >> whitelist.txt
    echo "full:gsp4-cn.ls.apple.com.edgekey.net.globalredir.akadns.net" >> whitelist.txt
    echo "full:gsp4-cn.ls.apple.com.edgekey.net" >> whitelist.txt
    echo "full:gsp4-cn.ls.apple.com" >> whitelist.txt
    echo "full:gsp5-cn.ls.apple.com" >> whitelist.txt
    echo "full:gsp85-cn-ssl.ls.apple.com" >> whitelist.txt
    echo "full:gspe19-2-cn-ssl.ls.apple.com" >> whitelist.txt
    echo "full:gspe19-cn-ssl.ls.apple.com" >> whitelist.txt
    echo "full:gspe19-cn.ls-apple.com.akadns.net" >> whitelist.txt
    echo "full:gspe19-cn.ls.apple.com" >> whitelist.txt
    echo "full:gspe79-cn-ssl.ls.apple.com" >> whitelist.txt
    echo "full:cl2-cn.apple.com" >> whitelist.txt
    echo "full:cl4-cn.apple.com" >> whitelist.txt
    echo "domain:dht.libtorrent.org" >> whitelist.txt
    echo "domain:dht.transmissionbt.com" >> whitelist.txt
    echo "domain:dns.msftncsi.com" >> whitelist.txt
    echo "domain:msftncsi.com" >> whitelist.txt
    echo "domain:ipv6.msftconnecttest.com" >> whitelist.txt
    echo "domain:www.msftconnecttest.com" >> whitelist.txt
    echo "domain:xiuxitong.com" >> whitelist.txt
    echo "domain:pc528.net" >> whitelist.txt
    echo "domain:pc521.net" >> whitelist.txt
    echo "    " >> whitelist.txt
    echo "domain:bing.com" >> whitelist.txt
    echo "domain:live.com" >> whitelist.txt
    echo "domain:msn.com" >> whitelist.txt
    echo "domain:ntp.org" >> whitelist.txt
    echo "domain:office.com" >> whitelist.txt
    echo "domain:qlogo.cn" >> whitelist.txt
    echo "domain:qq.com" >> whitelist.txt
    echo "domain:redhat.com" >> whitelist.txt
    echo "keyword:douyin" >> whitelist.txt
    echo "keyword:microsoft" >> whitelist.txt
    echo "keyword:windows" >> whitelist.txt
    echo "    " >> whitelist.txt
    echo "domain:btschool.club" >> whitelist.txt
    echo "domain:m-team.io" >> whitelist.txt
    echo "domain:m-team.cc" >> whitelist.txt
    echo "domain:soulvoice.club" >> whitelist.txt
    echo "domain:hddolby.com" >> whitelist.txt
    echo "domain:pthome.net" >> whitelist.txt
    echo "domain:hdatmos.club" >> whitelist.txt
    echo "domain:ourbits.club" >> whitelist.txt
    echo "domain:hdhome.org" >> whitelist.txt
    echo "domain:pttime.org" >> whitelist.txt
    echo "domain:audiences.me" >> whitelist.txt
    echo "domain:cinefiles.info" >> whitelist.txt
    echo "domain:ptsbao.club" >> whitelist.txt
    echo "domain:discfan.net" >> whitelist.txt
    echo "domain:chdbits.co" >> whitelist.txt
    echo "domain:open.cd" >> whitelist.txt
    echo "domain:hdsky.me" >> whitelist.txt
    echo "domain:hdchina.org" >> whitelist.txt
    echo "domain:beitai.pt" >> whitelist.txt
    echo "domain:springsunday.net" >> whitelist.txt
    echo "domain:totheglory.im" >> whitelist.txt
    echo "domain:keepfrds.com" >> whitelist.txt
    echo "domain:et8.org" >> whitelist.txt
    echo "domain:pterclub.com" >> whitelist.txt
    echo "domain:nicept.net" >> whitelist.txt
    echo "domain:skyey2.com" >> whitelist.txt
    echo "domain:wintersakura.net" >> whitelist.txt
    echo "domain:hhanclub.top" >> whitelist.txt
    echo "domain:piggo.me" >> whitelist.txt
    echo "domain:icc2022.com" >> whitelist.txt
    echo "domain:hd4fans.org" >> whitelist.txt
    echo "domain:iptorrents.com" >> whitelist.txt
    echo "domain:agsvpt.com" >> whitelist.txt
    echo "domain:empirehost.me" >> whitelist.txt
    echo "domain:tvzb.com" >> whitelist.txt
    echo "domain:hdmayi.com" >> whitelist.txt
    echo "domain:hdtime.org" >> whitelist.txt
    echo "domain:hdfun.me" >> whitelist.txt
    echo "domain:feiye2016.cn" >> whitelist.txt
    echo "domain:feiye2022.top" >> whitelist.txt
    echo "domain:feiye2023.top" >> whitelist.txt
    echo "domain:timor.tech" >> whitelist.txt
    echo -e "\n\e[1m\e[37m\e[42m所有规则文件修改操作已完成\e[0m\n"
    echo "开始配置MosDNS config文件..."
> /etc/mosdns/config.yaml
cat << 'EOF' >> /etc/mosdns/config.yaml
log:
  level: info
  file: "/etc/mosdns/mosdns.log"  # 日志级别和日志文件路径

api:
  http: "0.0.0.0:8338"  # HTTP API监听地址和端口

include: []  # 包含的配置文件（当前为空）

plugins:
  - tag: geosite_cn
    type: domain_set
    args:
      files:
        - "/etc/mosdns/geosite_cn.txt"  # 中国大陆的域名集合

  - tag: geoip_cn
    type: ip_set
    args:
      files:
        - "/etc/mosdns/geoip_cn.txt"  # 中国大陆的IP集合

  - tag: geosite_no_cn
    type: domain_set
    args:
      files:
        - "/etc/mosdns/geosite_geolocation_noncn.txt"  # 非中国大陆的域名集合

  - tag: whitelist
    type: domain_set
    args:
      files:
        - "/etc/mosdns/rule/whitelist.txt"  # 白名单域名集合

  - tag: blocklist
    type: domain_set
    args:
      files:
        - "/etc/mosdns/rule/blocklist.txt"  # 黑名单域名集合

  - tag: greylist
    type: domain_set
    args:
      files:
        - "/etc/mosdns/rule/greylist.txt"  # 灰名单域名集合

  - tag: ddnslist
    type: domain_set
    args:
      files:
        - "/etc/mosdns/rule/ddnslist.txt"  # DDNS域名列表

  - tag: hosts
    type: hosts
    args:
      files:
        - "/etc/mosdns/rule/hosts.txt"  # 主机文件，用于静态域名解析

  - tag: redirect
    type: redirect
    args:
      files:
        - "/etc/mosdns/rule/redirect.txt"  # 重定向规则

  - tag: adlist
    type: domain_set
    args:
      files:
        - "/etc/mosdns/rule/adlist.txt"  # 广告域名列表

  - tag: local_ptr
    type: domain_set
    args:
      files:
        - "/etc/mosdns/rule/localptr.txt"  # 本地PTR记录

  - tag: ecs_local
    type: ecs_handler
    args:
      forward: false  # 是否转发到ECS
      preset:  123.118.5.30  # ECS地址
      mask4: 24  # 子网掩码

  - tag: lazy_cache
    type: cache
    args:
      size: 32768  # 缓存大小
      lazy_cache_ttl: 86400  # 懒惰缓存的TTL
      dump_file: /etc/mosdns/cache.dump  # 缓存转储文件路径
      dump_interval: 3600  # 缓存转储间隔

  - tag: reject_3
    type: sequence
    args:
      - exec: reject 3  # 拒绝3个查询

  - tag: reject_blocklist
    type: sequence
    args:
      - exec: query_summary reject_blocklist  # 对黑名单进行查询汇总
      - exec: $reject_3  # 拒绝3个查询

  - tag: reject_adlist
    type: sequence
    args:
      - exec: query_summary reject_adlist  # 对广告名单进行查询汇总
      - exec: $reject_3  # 拒绝3个查询

  - tag: reject_ptrlist
    type: sequence
    args:
      - exec: query_summary reject_ptrlist  # 对PTR记录名单进行查询汇总
      - exec: $reject_3  # 拒绝3个查询

  - tag: reject_qtype65
    type: sequence
    args:
      - exec: query_summary reject_qtype65  # 对QTYPE 65进行查询汇总
      - exec: $reject_3  # 拒绝3个查询

  - tag: forward_local
    type: forward
    args:
      concurrent: 1  # 并发请求数
      upstreams:
        - addr: 223.5.5.5:53  # 本地DNS服务器地址
          enable_pipeline: false  # 是否启用管道
          insecure_skip_verify: false  # 是否跳过安全验证
          idle_timeout: 30  # 空闲超时
          enable_http3: false  # 是否启用HTTP3

  - tag: forward_remote
    type: forward
    args:
      concurrent: 1  # 并发请求数
      upstreams:
        - addr: 10.10.10.2:6666  # 远程DNS服务器地址
          enable_pipeline: false  # 是否启用管道
          insecure_skip_verify: false  # 是否跳过安全验证
          idle_timeout: 30  # 空闲超时
          enable_http3: false  # 是否启用HTTP3

  - tag: forward_cf
    type: forward
    args:
      concurrent: 1  # 并发请求数
      upstreams:
        - addr: tls://8.8.8.8:853  # Cloudflare DNS地址（使用TLS）
          enable_pipeline: true  # 是否启用管道
          insecure_skip_verify: false  # 是否跳过安全验证
          idle_timeout: 30  # 空闲超时
          enable_http3: false  # 是否启用HTTP3

  - tag: modify_ttl
    type: sequence
    args:
      - exec: ttl 0-0  # 修改TTL为0

  - tag: modify_ddns_ttl
    type: sequence
    args:
      - exec: ttl 5-5  # 修改DDNS TTL为5

  - tag: local_sequence
    type: sequence
    args:
      - exec: query_summary forward_local  # 对本地转发的查询进行汇总
      - exec: $forward_local  # 执行本地转发

  - tag: remote_sequence
    type: sequence
    args:
      - exec: query_summary forward_remote  # 对远程转发的查询进行汇总
      - exec: $forward_remote  # 执行远程转发

  - tag: forward_cf_upstream
    type: sequence
    args:
      - exec: query_summary forward_cf  # 对Cloudflare转发的查询进行汇总
      - exec: $forward_cf  # 执行Cloudflare转发

  - tag: has_resp_sequence
    type: sequence
    args:
      - matches: qname $ddnslist  # 匹配DDNS域名
        exec: $modify_ddns_ttl  # 修改DDNS TTL
      - matches: "!qname $ddnslist"  # 不匹配DDNS域名
        exec: $modify_ttl  # 修改TTL
      - matches: has_resp  # 有响应
        exec: accept  # 接受响应

  - tag: query_is_ddns_domain
    type: sequence
    args:
      - matches: qname $ddnslist  # 匹配DDNS域名
        exec: $local_sequence  # 执行本地处理序列

  - tag: query_is_srv_domain
    type: sequence
    args:
      - matches:
        - qtype 33  # 匹配SRV记录
        exec: $forward_cf_upstream  # 执行Cloudflare转发

  - tag: query_is_local_domain
    type: sequence
    args:
      - matches: qname $geosite_cn  # 匹配中国大陆域名
        exec: $local_sequence  # 执行本地处理序列

  - tag: query_is_no_local_domain
    type: sequence
    args:
      - matches: qname $geosite_no_cn  # 匹配非中国大陆域名
        exec: $remote_sequence  # 执行远程处理序列

  - tag: query_is_whitelist_domain
    type: sequence
    args:
      - matches: qname $whitelist  # 匹配白名单域名
        exec: $local_sequence  # 执行本地处理序列

  - tag: query_is_greylist_domain
    type: sequence
    args:
      - matches: qname $greylist  # 匹配灰名单域名
        exec: $remote_sequence  # 执行远程处理序列

  - tag: query_is_reject_domain
    type: sequence
    args:
      - matches: qname $blocklist  # 匹配黑名单域名
        exec: $reject_blocklist  # 执行黑名单处理
      - matches: qname $adlist  # 匹配广告名单域名
        exec: $reject_adlist  # 执行广告名单处理
      - matches:
        - qtype 12  # 匹配PTR记录
        - qname $local_ptr  # 匹配本地PTR记录
        exec: $reject_ptrlist  # 执行PTR记录处理
      - matches: qtype 65  # 匹配QTYPE 65记录
        exec: $reject_qtype65  # 执行QTYPE 65处理

  - tag: fallback_sequence
    type: sequence
    args:
      - exec: $ecs_local  # 执行ECS处理
      - exec: $forward_cf_upstream  # 执行Cloudflare转发
      - matches: "resp_ip $geoip_cn"  # 匹配中国大陆IP
        exec: $local_sequence  # 执行本地处理序列
      - matches: "!resp_ip 0.0.0.0/0 ::/0"  # 不匹配所有IP
        exec: accept  # 接受响应
      - matches: "!resp_ip $geoip_cn"  # 不匹配中国大陆IP
        exec: $remote_sequence  # 执行远程处理序列

  - tag: main_sequence
    type: sequence
    args:
      - exec: metrics_collector metrics  # 收集指标
      - exec: $hosts  # 执行主机文件处理
      - exec: jump has_resp_sequence  # 跳转到有响应处理序列
      - matches:
        - "!qname $ddnslist"  # 不匹配DDNS域名
        - "!qname $blocklist"  # 不匹配黑名单域名
        - "!qname $adlist"  # 不匹配广告名单域名
        - "!qname $local_ptr"  # 不匹配本地PTR记录
        exec: $lazy_cache  # 执行懒惰缓存
      - exec: $redirect  # 执行重定向
      - exec: jump has_resp_sequence  # 跳转到有响应处理序列
      - exec: $query_is_ddns_domain  # 执行DDNS域名处理
      - exec: jump has_resp_sequence  # 跳转到有响应处理序列
      - exec: $query_is_srv_domain  # 执行SRV域名处理
      - exec: jump has_resp_sequence  # 跳转到有响应处理序列	  
      - exec: $query_is_whitelist_domain  # 执行白名单域名处理
      - exec: jump has_resp_sequence  # 跳转到有响应处理序列
      - exec: $query_is_reject_domain  # 执行拒绝域名处理
      - exec: jump has_resp_sequence  # 跳转到有响应处理序列
      - exec: $query_is_greylist_domain  # 执行灰名单域名处理
      - exec: jump has_resp_sequence  # 跳转到有响应处理序列
      - exec: $query_is_local_domain  # 执行本地域名处理
      - exec: jump has_resp_sequence  # 跳转到有响应处理序列
      - exec: $query_is_no_local_domain  # 执行非本地域名处理
      - exec: jump has_resp_sequence  # 跳转到有响应处理序列
      - exec: $fallback_sequence  # 执行备用处理序列

  - tag: udp_server
    type: udp_server
    args:
      entry: main_sequence  # UDP服务器入口
      listen: ":53"  # 监听地址和端口 

EOF
    sed -i "s/- addr: 10.10.10.2:6666/- addr: ${uiport}/g" /etc/mosdns/config.yaml
    sed -i "s/- addr: 223.5.5.5:53/- addr: ${localport}/g" /etc/mosdns/config.yaml
    echo -e "\n\e[1m\e[37m\e[42mMosDNS config文件已配置完成\e[0m\n"    
    echo "开始配置定时更新规则与清理日志..."
    cd /etc/mosdns
    touch {geosite_cn,geoip_cn,geosite_geolocation_noncn,gfw}.txt
    touch mos_rule_update.sh
    # 添加新的内容
cat << 'EOF' >> /etc/mosdns/mos_rule_update.sh
#!/bin/bash

# 设置需要下载的文件 URL
proxy_list_url="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/proxy-list.txt"
gfw_list_url="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt"
direct_list_url="https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/direct-list.txt"
cn_ip_cidr_url="https://raw.githubusercontent.com/Hackl0us/GeoIP2-CN/release/CN-ip-cidr.txt"

# 设置本地文件路径
geosite_cn_file="/etc/mosdns/geosite_cn.txt"
geoip_cn_file="/etc/mosdns/geoip_cn.txt"
geosite_geolocation_noncn_file="/etc/mosdns/geosite_geolocation_noncn.txt"
gfw_file="/etc/mosdns/gfw.txt"

# 下载并替换文件的函数
download_and_replace() {
    local url=$1
    local file=$2

    # 下载文件
    curl -s "$url" -o "$file.tmp"

    # 检查下载是否成功
    if [ $? -eq 0 ]; then
        # 用下载的文件替换原文件
        mv "$file.tmp" "$file"
        echo "文件 $file 更新成功。"
    else
        echo "下载 $file 失败。"
    fi
}

# 下载并替换文件
download_and_replace "$proxy_list_url" "$geosite_geolocation_noncn_file"
download_and_replace "$gfw_list_url" "$gfw_file"
download_and_replace "$direct_list_url" "$geosite_cn_file"
download_and_replace "$cn_ip_cidr_url" "$geoip_cn_file"

echo "proxy_list、gfw_list、direct_list、cn_ip_cidr更新完成。"
EOF
    # 设置脚本为可执行
    chmod +x mos_rule_update.sh
    ./mos_rule_update.sh
    (crontab -l 2>/dev/null; echo "0 0 * * 0 sudo truncate -s 0 /etc/mosdns/mosdns.log && /etc/mosdns/mos_rule_update.sh") | crontab -
    echo -e "\n\e[1m\e[37m\e[42m定时更新规则与清理日志添加完成\e[0m\n"
}
################################ 开机自启动 服务 ################################
enable_autostart() {
    echo "设置mosdns开机自启动"
    # 启用并立即启动 mosdns 服务
    systemctl enable mosdns --now
    echo -e "\n\e[1m\e[37m\e[42mmosdns开机启动完成\e[0m\n"
}
################################ 重置Mosdns缓存 ################################
del_mosdns_cache() {
    echo "停止MosDNS并开始删除MosDNS缓存"
    systemctl stop mosdns && rm -f /etc/mosdns/cache.dump
    sleep 1
    echo "重载配置并启动MosDNS"    
    systemctl daemon-reload && systemctl start mosdns
    echo -e "\n\e[1m\e[37m\e[42mMosdns缓存已重置\e[0m\n"
    sleep 1
}
################################ Mosdns UI安装 ################################
install_mosdns_ui() {
    echo "开始安装MosDNS UI..."    
    apt_update_upgrade || exit 1
    apt_install || exit 1
    set_timezone || exit 1
    set_ntp || exit 1
    install_loki || exit 1
    install_vector || exit 1
    install_prometheus || exit 1
    install_grafana || exit 1
    install_complete_ui
}
################################ Loki 安装 ################################
install_loki() {
    echo "开始安装Loki..."
    mkdir /mnt/ui && cd /mnt/ui
    wget https://github.com/grafana/loki/releases/download/v3.1.0/loki_3.1.0_amd64.deb
    dpkg -i loki_3.1.0_amd64.deb
    systemctl enable loki --now
    echo -e "\n\e[1m\e[37m\e[42mLoki已安装完成\e[0m\n"
}
################################ Vector 安装 ################################
install_vector() {
    echo "开始安装Vector..."
    cd /mnt/ui
    curl --proto '=https' --tlsv1.2 -sSfL https://sh.vector.dev | bash -s -- -y
    echo -n "" > /root/.vector/config/vector.yaml
# 写入新的内容
cat << 'EOF' > /root/.vector/config/vector.yaml
data_dir: /tmp/vector

sources:
  mosdns-log-file:
    type: file
    include:
      - /etc/mosdns/mosdns.log
    read_from: beginning

transforms:
  mosdns-input:
    type: filter
    inputs:
      - mosdns-log-file
    condition: |
      .file == "/etc/mosdns/mosdns.log"      

  mosdns-data:
    type: remap
    inputs:
      - mosdns-input
    drop_on_error: true
    source: |
      .type = "mosdns"
      .app = "mosdns"
      del(.host)
      del(.file)
      del(.source_type)

      message_parts = split!(.message, r'\t')

      .timestamp = parse_timestamp!(message_parts[0], format: "%FT%T%.9f%z")
      .level = message_parts[1]

      if (length(message_parts) == 6) {
        .plugin = message_parts[2]
        .processor = message_parts[3]
        .message = message_parts[4]

        if (exists(message_parts[5])) {
          .metadata = parse_json!(message_parts[5])
          . = merge!(., .metadata)
          del(.metadata)
        }
      } else {
        .processor = message_parts[2]
        .message = message_parts[3]

        if (exists(message_parts[4])) {
          .metadata = parse_json!(message_parts[4])
          . = merge!(., .metadata)
          del(.metadata)
        }
      }

      if (exists(.query)) {
        . = merge!(., .query)
        del(.query)
      }      

sinks:
  # 同步到 loki，根据实际情况修改 endpoint 的值
  loki:
    type: loki
    inputs:
      - mosdns-data
    endpoint: 'http://127.0.0.1:3100'
    encoding:
      codec: json
    labels:
      app: '{{ app }}'
      type: '{{ type }}'
    healthcheck:
      enabled: true

  # 临时输出转换数据到 vector 控制台（生产环境请禁用）
  debug_mosdns:
    type: console
    inputs:
      - mosdns-data
    encoding:
      codec: json
EOF
    cd /etc/systemd/system/
    touch vector.service
cat << 'EOF' > vector.service
[Unit]
Description=Vector Service
After=network.target

[Service]
Type=simple
User=root
ExecStartPre=/bin/sleep 10
ExecStartPre=/bin/mkdir -p /tmp/vector
ExecStart=/root/.vector/bin/vector --config /root/.vector/config/vector.yaml
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable vector --now
    echo -e "\n\e[1m\e[37m\e[42mVector已安装完成\e[0m\n"
}
################################ Prometheus 安装 ################################
install_prometheus() {
    echo "开始安装Prometheus..."
    sudo apt-get install -y prometheus
# 添加 mosdns 任务配置
cat << EOF | sudo tee -a /etc/prometheus/prometheus.yml
  - job_name: mosdns
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:8338']
EOF
    # 重启 Prometheus
    sudo systemctl enable prometheus --now
    sudo systemctl restart prometheus
    echo -e "\n\e[1m\e[37m\e[42mPrometheus已安装完成\e[0m\n"
}
################################ Grafana 安装 ################################
install_grafana() {
    echo "开始安装Grafana..."
    cd /mnt/ui
    wget https://dl.grafana.com/enterprise/release/grafana-enterprise_11.0.0_amd64.deb
    sudo dpkg -i grafana-enterprise_11.0.0_amd64.deb
    # 重新加载 systemd 并启用/启动 Grafana 服务器
    sudo systemctl daemon-reload
    sudo systemctl enable grafana-server
    sudo systemctl start grafana-server
    # 确认 Grafana 服务器状态
    if systemctl is-active --quiet grafana-server; then
        echo -e "\n\e[1m\e[37m\e[42mGrafana已安装并成功启动\e[0m\n"
    else
        echo -e "\n\e[1m\e[37m\e[41mGrafana安装失败或未能启动\e[0m\n" || exit 1
    fi
}
################################ 卸载Mosdns ################################
del_mosdns() {
    echo "停止MosDNS服务并删除"
    sudo systemctl stop mosdns || exit 1
    sudo systemctl disable mosdns || exit 1
    sudo rm /etc/systemd/system/mosdns.service || exit 1
    sudo rm -r /etc/mosdns || exit 1
    (crontab -l 2>/dev/null | grep -v 'truncate -s 0 /etc/mosdns/mosdns.log && /etc/mosdns/mos_rule_update.sh') | crontab - || exit 1
    echo -e "\n\e[1m\e[37m\e[42m卸载Mosdns已完成\e[0m\n"
}
################################ 卸载Mosdns UI ################################
del_mosdns_ui() {
    echo "停止MosDNS UI服务并删除"
    sudo systemctl stop loki
    sudo systemctl disable loki
    sudo dpkg -r loki
    sudo rm -rf /etc/loki /var/lib/loki /var/log/loki
    sudo find /etc/systemd /lib/systemd /run/systemd -name 'loki.service' -exec sudo rm {} \;
    sudo systemctl stop vector
    sudo systemctl disable vector
    sudo rm -rf /root/.vector
    sudo rm /etc/systemd/system/vector.service
    sudo rm -rf /root/.vector/config/vector.yaml
    sudo systemctl stop prometheus
    sudo systemctl disable prometheus
    sudo apt-get remove --purge -y prometheus
    sudo rm -rf /etc/prometheus /var/lib/prometheus
    sudo rm -rf /usr/bin/prometheus
    sudo rm -rf /usr/bin/prometheus-node-exporter
    sudo rm /lib/systemd/system/prometheus-node-*
    sudo rm /etc/systemd/system/multi-user.target.wants/prometheus-node-*
    sudo systemctl stop grafana-server
    sudo systemctl disable grafana-server
    sudo dpkg -r grafana-enterprise
    sudo rm -rf /etc/grafana /var/lib/grafana /var/log/grafana
    sudo rm /lib/systemd/system/grafana-server.service
    sudo rm /etc/systemd/system/grafana-server.service
    sudo rm /etc/systemd/system/multi-user.target.wants/grafana-server.service
    sudo rm /etc/init.d/grafana-server
    sudo systemctl daemon-reload
    sudo systemctl reset-failed
    echo -e "\n\e[1m\e[37m\e[42m卸载Mosdns UI已完成\e[0m\n"
}
################################ Mosdns安装结束 ################################
install_complete() {
    systemctl restart mosdns
    sudo rm -r /mnt/mosdns || exit 1
    sleep 1
echo "=================================================================="
echo -e "\t\tMosdns 安装完成"
echo -e "\n"
echo -e "Mosdns运行目录为\e[1m\e[33m/etc/mosdns\e[0m"
echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，已查\n询程序运行状态，如出现\e[1m\e[32m active (running)\e[0m，程序已启动成功。\n网关自行配置为sing-box，dns为Mosdns地址"
echo "=================================================================="
systemctl status mosdns
}
################################ Mosdns UI 安装结束 ################################
install_complete_ui() {
    systemctl restart loki
    systemctl restart vector
    systemctl restart prometheus
    systemctl restart grafana-server
    sudo rm -r /mnt/ui || exit 1
    local_ip=$(hostname -I | awk '{print $1}')
    sleep 1
echo "=================================================================="
echo -e "\t\tMosdns UI 安装完成"
echo -e "\n"
echo -e "请打开：\e[1m\e[33mhttp://$local_ip:3000\e[0m,进入ui管理界面，默认账号及密码均为\e[1m\e[33madmin\e[0m"
echo "=================================================================="
}
################################ Mosdns 一键安装结束 ################################
install_complete_all() {
    systemctl restart mosdns
    sudo rm -r /mnt/mosdns || exit 1
    systemctl restart loki
    systemctl restart vector
    systemctl restart prometheus
    systemctl restart grafana-server
    sudo rm -r /mnt/ui || exit 1
    local_ip=$(hostname -I | awk '{print $1}')
    sleep 1
echo "=================================================================="
echo -e "\t\tMosdns及UI一键安装完成"
echo -e "\n"
echo -e "Mosdns运行目录为\e[1m\e[33m/etc/mosdns\e[0m"
echo -e "请打开：\e[1m\e[33mhttp://$local_ip:3000\e[0m,进入ui管理界面，默认账号及密码均为：\n\e[1m\e[33madmin\e[0m"
echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，已查\n询程序运行状态，如出现\e[1m\e[32m active (running)\e[0m，程序已启动成功。\n网关自行配置为sing-box，dns为Mosdns地址"
echo "=================================================================="
systemctl status mosdns
}
################################sing-box安装结束################################
install_sing_box_over() {
    sleep 1
    rm -rf go1.22.4.linux-amd64.tar.gz
    systemctl stop sing-box && systemctl daemon-reload && systemctl restart sing-box
    local_ip=$(hostname -I | awk '{print $1}')
echo "=================================================================="
echo -e "\t\t\tSing-Box 安装完毕"
echo -e "\n"
echo -e "singbox运行目录为\e[1m\e[33m/usr/loacl/etc/sing-box\e[0m"
echo -e "singbox WebUI地址:\e[1m\e[33mhttp://$local_ip:9090\e[0m"
echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，目前程序未\n运行，请自行修改运行目录下配置文件后运行\e[1m\e[33msystemctl restart sing-box\e[0m\n命令运行程序。"
echo "=================================================================="
}
################################ HY2回家结束 ################################
install_hy2_home_over() {
sleep 1
echo "=================================================================="
echo -e "\t\t\tSing-Box 回家配置生成完毕"
echo -e "\n"
echo -e "sing-box 回家配置生成路径为: \e[1m\e[33m/root/go_home.json\e[0m\n请自行复制至 sing-box 客户端"
echo -e "温馨提示:\n本脚本仅在ubuntu22.04环境下测试，其他环境未经验证，仅供个人使用"
echo "================================================================="
}
main