#!/bin/bash

clear
rm -rf /mnt/main_install.sh

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
echo -e "温馨提示:\n本脚本仅在ubuntu22.04环境下测试，其他环境未经验证 "
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
    wget -q -O /etc/nftables.conf https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/nftables.conf
# echo "" > "/etc/nftables.conf"
# cat <<EOF > "/etc/nftables.conf"
# #!/usr/sbin/nft -f

# table inet singbox {
# # 原本的 local_ipv4 设置
# 	 set local_ipv4 {
# 	 	type ipv4_addr
# 	 	flags interval
# 	 	elements = {
# 			10.10.10.0/24,	 	
# 			127.0.0.0/8,
# 	 		169.254.0.0/16,
# 	 		172.16.0.0/12,
# 	 		192.168.0.0/16,
# 	 		240.0.0.0/4
# 	 	}
# 	 }

# 	set local_ipv6 {
# 		type ipv6_addr
# 		flags interval
# 		elements = {
# 			::ffff:0.0.0.0/96,
# 			64:ff9b::/96,
# 			100::/64,
# 			2001::/32,
# 			2001:10::/28,
# 			2001:20::/28,
# 			2001:db8::/32,
# 			2002::/16,
# 			fc00::/7,
# 			fe80::/10
# 		}
# 	}

# 	chain singbox-tproxy {
# 		fib daddr type { unspec, local, anycast, multicast } return
# 		ip daddr @local_ipv4 return
# 		ip6 daddr @local_ipv6 return
# 		udp dport { 123 } return
# 		meta l4proto { tcp, udp } meta mark set 1 tproxy to :7896 accept
# 	}

# 	chain singbox-mark {
# 		fib daddr type { unspec, local, anycast, multicast } return
# 		ip daddr @local_ipv4 return
# 		ip6 daddr @local_ipv6 return
# 		udp dport { 123 } return
# 		meta mark set 1
# 	}

# 	chain mangle-output {
# 		type route hook output priority mangle; policy accept;
# 		meta l4proto { tcp, udp } skgid != 1 ct direction original goto singbox-mark
# 	}

# 	chain mangle-prerouting {
# 		type filter hook prerouting priority mangle; policy accept;
# 		iifname { lo, ens18 } meta l4proto { tcp, udp } ct direction original goto singbox-tproxy
# 	}
# }
# EOF
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
echo -e "温馨提示:\n本脚本仅在ubuntu22.04环境下测试，其他环境未经验证 "
echo "================================================================="
}
################################ 主程序 ################################
singbox_choose