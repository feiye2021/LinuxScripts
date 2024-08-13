#!/bin/bash

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
    read -p "请选择服务: " choice
    # read choice
    case $choice in
        1)
            white "开始安装官方Singbox核心"
            basic_settings
            install_singbox
            install_service
            install_config
            install_tproxy
            install_sing_box_over
            ;;
        2)
            white "开始生成回家配置"
            hy2_custom_settings
            install_home
            install_hy2_home_over
            ;;
        3)
            white "卸载sing-box核心程序及其相关配置文件"    
            del_singbox
            rm -rf /mnt/singbox.sh    #delete   
            ;;
        4)
            white "卸载HY2回家配置及其相关配置文件"       
            del_hy2
            rm -rf /mnt/singbox.sh    #delete   
            ;;
        9)
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
            /mnt/singbox.sh
            ;;
    esac
}
################################ 基础环境设置 ################################
basic_settings() {
    white "配置基础设置并安装依赖..."
    sleep 1
    DEBIAN_FRONTEND=noninteractive apt update -y && apt -y upgrade || { red "环境更新失败！退出脚本"; exit 1; }
    green "环境更新成功"
    white "环境依赖安装开始..."
    apt install curl wget tar gawk sed cron unzip nano sudo vim sshfs net-tools nfs-common bind9-host adduser libfontconfig1 musl git build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64 -y || { red "环境依赖安装失败！退出脚本"; exit 1; }
    green "依赖安装成功"
    timedatectl set-timezone Asia/Shanghai || { red "时区设置失败！退出脚本"; exit 1; }
    green "时区设置成功"
    ntp_config="NTP=ntp.aliyun.com"
    echo "$ntp_config" | sudo tee -a /etc/systemd/timesyncd.conf > /dev/null
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-timesyncd
    green "已将 NTP 服务器配置为 ntp.aliyun.com"
    sed -i '/^#*DNSStubListener/s/#*DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf || { echo -e "\n\e[1m\e[37m\e[41m关闭53端口监听失败！退出脚本\e[0m\n"; exit 1; }
    systemctl restart systemd-resolved.service || { red "重启 systemd-resolved.service 失败！退出脚本"; exit 1; }
    green "关闭53端口监听成功"
}    
################################编译 Sing-Box 的最新版本################################
install_singbox() {
    white "编译Sing-Box 最新版本..."
    sleep 1
    apt -y install curl git build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64
    white "开始编译Sing-Box 最新版本..."
    rm -rf /root/go/bin/*
    curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz -o go1.22.4.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
    white "下载go文件完成"
    echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/golang.sh
    source /etc/profile.d/golang.sh
    white "开始go文件安装"
    go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@latest
    white "等待检测安装状态"    
    if ! go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@latest; then
        red "Sing-Box 编译失败！退出脚本"
        rm -rf /mnt/singbox.sh    #delete    
        exit 1
    fi
    white "编译完成，开始安装Sing-Box..."
    sleep 1
    if [ -f "/usr/local/bin/sing-box" ]; then
        white "检测到已安装的 sing-box"
        read -p "是否替换升级？(y/n): " replace_confirm
        if [ "$replace_confirm" = "y" ]; then
            white "正在替换升级 sing-box"
            cp "$(go env GOPATH)/bin/sing-box" /usr/local/bin/
            rm -rf /mnt/singbox.sh    #delete    
echo "=================================================================="
echo -e "\t\t\tSing-Box 升级完毕"
echo -e "\n"
echo -e "温馨提示:\n本脚本仅在ubuntu22.04环境下测试，其他环境未经验证 "
echo "=================================================================="
            exit 0
        else
            echo "用户取消了替换升级操作"
        fi
    else
        white "未安装Sing-Box ，开始安装"
        cp $(go env GOPATH)/bin/sing-box /usr/local/bin/
        white "Sing-Box 安装完成"
    fi
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
    wget -q -O /usr/local/etc/sing-box/config.json https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/singbox.json
    singbox_config_file="/usr/local/etc/sing-box/config.json"
    if [ ! -f "$singbox_config_file" ]; then
        echo -e "\e[31m错误：配置文件 $singbox_config_file 不存在.\e[0m"
        echo -e "\e[31m请检查网络可正常访问github后运行脚本.\e[0m"
        rm -rf /mnt/singbox.sh    #delete
        exit 1
    fi
}
################################安装tproxy################################
install_tproxy() {
    sleep 1
    white "创建系统转发..."   
    if ! grep -q '^net.ipv4.ip_forward=1$' /etc/sysctl.conf; then
        echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    fi
    if ! grep -q '^net.ipv6.conf.all.forwarding = 1$' /etc/sysctl.conf; then
        echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.conf
    fi
    green "系统转发创建完成"
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
    wget -q -O /root/go_home.json https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/go_home.json
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
################################sing-box安装结束################################
install_sing_box_over() {
    rm -rf go1.22.4.linux-amd64.tar.gz
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
################################ 主程序 ################################
singbox_choose