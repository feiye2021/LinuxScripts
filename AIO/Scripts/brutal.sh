#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
export APT_LISTCHANGES_FRONTEND=none

# 检查是否为root用户登录
check_root() {
  if [ "$EUID" -ne 0 ]; then 
    echo "请使用root用户运行此脚本。"
    rm -rf /mnt/brutal.sh     #delete
    exit 1
  fi
}

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
################################# Sing-Box选择 ################################
brutal_choose() {
    clear
    echo "=================================================================="
    echo -e "\t\tbrutal 节点安装脚本 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo "欢迎使用brutal 节点安装脚本"
    echo "请选择要执行的服务："
    echo "=================================================================="
    echo "1. 安装brutal节点并生成出站配置"
    echo "2. 升级/更新brutal"    
    echo "3. 一键生成出站配置"
    echo -e "\t"
    echo "9. 一键卸载singbox及HY2回家"
    echo "-. 返回上级菜单"      
    echo "0) 退出脚本"
    read -p "请选择服务: " choice
    # read choice
    case $choice in
        1)
            white "开始安装brutal节点并生成出站配置..."
            check_root
            check_and_upgrade_kernel
            custom_settings
            basic_settings
            install_brutal
            install_nginx
            install_singbox 
            install_service
            install_config
            outbounds_setting
            over_brutal_install
            ;;
        2)
            install_brutal
            ;;               
        3)
            outbounds_setting
            ;;         
        0)
            red "退出脚本，感谢使用."
            rm -rf /mnt/brutal.sh     #delete       
            ;;
        -)
            white "脚本切换中，请等待..."
            rm -rf /mnt/brutal.sh     #delete     
            wget -q -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
            ;;
        *)
            white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            brutal_choose
            ;;
    esac
}
################################ 检查内核版本并升级 ################################  
check_and_upgrade_kernel() {
  local KERNEL_VERSION=$(uname -r)
  local REQUIRED_VERSION="5.8"

  if [[ $(echo -e "$KERNEL_VERSION\n$REQUIRED_VERSION" | sort -V | head -n1) == "$KERNEL_VERSION" ]]; then
    white "当前内核版本为 ${yellow}$KERNEL_VERSION${reset}，需要升级内核到5.8或更高版本"

    # 查找最新的可用内核版本
    local LATEST_KERNEL=$(apt list linux-headers-*.*.*-*-generic linux-image-*.*.*-*-generic 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+-[0-9]+-generic' | sort -V | tail -n 1)
    
    if [ -z "$LATEST_KERNEL" ]; then
      red "无法找到适合的内核版本"
      rm -rf /mnt/brutal.sh     #delete      
      exit 1
    fi
    
    white "将升级到最新的内核版本：${yellow}$LATEST_KERNEL${reset}"

    basic_settings

    # 安装最新的内核
    apt install -y linux-headers-$LATEST_KERNEL linux-image-$LATEST_KERNEL
    
    white "${yellow}内核已升级，请重启系统并重新运行此脚本${reset}"
    rm -rf /mnt/brutal.sh     #delete    
    exit 1
  fi
}

################################ 用户自定义参数 ################################ 
custom_settings() {
  clear
  echo "=================================================================="
  echo -e "\t\tbrutal 节点安装脚本 by 忧郁滴飞叶"
  echo -e "\t\n"  
  echo "欢迎使用brutal 节点安装脚本"
  echo "请选择提示设定相关参数："
  echo "=================================================================="
  # 获取SSL邮箱
  while true; do
    read -p "请输入您的SSL邮箱: " ssl_email
    if [[ "$ssl_email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
      break
    else
      red "无效的邮箱格式，请重新输入"
    fi
  done

  # 获取SSL域名
  while true; do
    read -p "请输入您的SSL域名: " ssl_domain
    if [[ "$ssl_domain" =~ ^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
      break
    else
      red "无效的域名格式，请重新输入"
    fi
  done

  # 获取singbox输入端口
  while true; do
    read -p "请输入您的singbox监听端口： " singbox_input_port
    if [[ "$singbox_input_port" =~ ^[0-9]+$ ]]; then
      break
    else
      red "无效的端口号，请重新输入"
    fi
  done

  # 获取VPS上行数据（Mbps）
  while true; do
    read -p "请输入您的VPS上行带宽 (仅限数字, 单位：Mbps): " singbox_input_up_mbps
    if [[ "$singbox_input_up_mbps" =~ ^[0-9]+$ ]]; then
      break
    else
      red "无效的上行数据，请重新输入"
    fi
  done

  # 获取VPS下行数据（Mbps）
  while true; do
    read -p "请输入您的VPS下行数据 (仅限数字, 单位：Mbps): " singbox_input_down_mbps
    if [[ "$singbox_input_down_mbps" =~ ^[0-9]+$ ]]; then
      break
    else
      red "无效的下行数据，请重新输入"
    fi
  done

  # 获取节点名称
  read -p "请输入您的singbox服务端节点名称: " singbox_input_tag

  # 获取VPS IP或者节点名称
  read -p "请输入您的VPS的IP或者域名: " vps_ip_domain

  # 将信息导出为环境变量，方便后续使用
  export SSL_EMAIL=$ssl_email
  export SSL_DOMAIN=$ssl_domain
  export SINGBOX_INPUT_PORT=$singbox_input_port
  export SINGBOX_INPUT_UP_MBPS=$singbox_input_up_mbps
  export SINGBOX_INPUT_DOWN_MBPS=$singbox_input_down_mbps
  export SINGBOX_INPUT_TAG=$singbox_input_tag
  export VPS_IP_DOMAIN=$vps_ip_domain

  white "您设定的参数："
  white "SSL邮箱：${yellow}$ssl_email${reset}"
  white "SSL域名：${yellow}$ssl_domain${reset}"
  white "singbox监听端口：${yellow}$singbox_input_port${reset}"
  white "VPS上行带宽：${yellow}$singbox_input_up_mbps M${reset}"
  white "VPS下行带宽：${yellow}$singbox_input_down_mbps M${reset}"
  white "singbox服务端节点名称：${yellow}$singbox_input_tag${reset}"
  white "VPS的IP或者域名：${yellow}$vps_ip_domain${reset}"
}

################################ 更新基础配置 ################################ 
basic_settings() {
    white "配置基础设置并安装依赖..."
    sleep 1
    apt-get update -y && apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || { red "环境更新失败！退出脚本"; exit 1; }
    green "环境更新成功"
    white "环境依赖安装开始..."
    apt-get install -y curl wget tar socat gawk sed jq cron unzip nano sudo vim sshfs net-tools nfs-common bind9-host adduser libfontconfig1 musl git build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64 || { red "环境依赖安装失败！退出脚本"; exit 1; }
    green "依赖安装成功"
    timedatectl set-timezone Asia/Shanghai || { red "时区设置失败！退出脚本"; exit 1; }
    green "时区设置成功"
    ntp_config="NTP=ntp.aliyun.com"
    echo "$ntp_config" | sudo tee -a /etc/systemd/timesyncd.conf > /dev/null
    systemctl daemon-reload
    systemctl restart systemd-timesyncd
    green "已将 NTP 服务器配置为 ntp.aliyun.com"
} 

################################ 安装并配置brutal ################################ 
install_brutal() {
  white "检查是否已安装brutal支持..."
  if grep -q 'brutal' /proc/sys/net/ipv4/tcp_allowed_congestion_control; then
    read -p "系统已支持brutal，是否需要升级？(默认Y): " upgrade_brutal
    upgrade_brutal=${upgrade_brutal:-Y}

    if [[ "$upgrade_brutal" =~ ^[Yy]$ ]]; then
      bash <(curl -fsSL https://tcp.hy2.sh/)
      if grep -q 'brutal' /proc/sys/net/ipv4/tcp_allowed_congestion_control; then
        red "brutal升级完成，请重启系统并重新运行此脚本"
        rm -rf /mnt/brutal.sh     #delete        
        exit 1
      else
        red "brutal升级失败，请检查安装过程中的错误"
        rm -rf /mnt/brutal.sh     #delete        
        exit 1
      fi
    else
      white "用户选择取消升级，正常安装brutal..."
      bash <(curl -fsSL https://tcp.hy2.sh/)
    fi
  else
    white "检测到未安装brutal，安装brutal..."
    bash <(curl -fsSL https://tcp.hy2.sh/)
  fi

  # 再次检查brutal是否安装成功
  if ! grep -q 'brutal' /proc/sys/net/ipv4/tcp_allowed_congestion_control; then
    red "brutal安装失败，请检查安装过程中的错误"
    rm -rf /mnt/brutal.sh     #delete    
    exit 1
  fi
  rm -rf /mnt/brutal.sh     #delete    
  green "brutal 已安装"
}

################################ 安装并配置NGINX ################################
install_nginx() {
  white "开始安装nginx..."
  apt install -y nginx
  green "NGINX 已安装"

  # 配置SSL证书
  install_and_configure_ssl

  # 配置nginx
  [ ! -d "/etc/nginx/conf.d" ] && mkdir -p "/etc/nginx/conf.d"
  wget -q -O /etc/nginx/conf.d/default.conf https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/brutal/nginx/brutal_nginx_config.conf
  sed -i "s|nginx_SSL_DOMAIN|${SSL_DOMAIN}|g" /etc/nginx/conf.d/default.conf

  # 下载并解压hdsn_2_caraft.zip文件
  white "开始下载伪装文件..."
  ZIP_URL="https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/brutal/nginx/hdsn_2_caraft.zip"
  DOWNLOAD_DIR="/mnt/bratul"
  DEST_DIR="/usr/share/nginx/html"

  mkdir -p "$DOWNLOAD_DIR"
  wget -q -O "$DOWNLOAD_DIR/hdsn_2_caraft.zip" "$ZIP_URL"
  unzip -o "$DOWNLOAD_DIR/hdsn_2_caraft.zip" -d "$DOWNLOAD_DIR"
  white "开始移动伪装文件..."
  mv "$DOWNLOAD_DIR/hdsn_2_caraft"/* "$DEST_DIR"
  rm -rf "$DOWNLOAD_DIR"

  systemctl restart nginx
  green "NGINX 配置已完成"
}

################################ 安装并配置SSL证书 ################################# 
install_and_configure_ssl() {
  white "开始安装acme..."
  curl https://get.acme.sh | sh

  green "acme安装完成"

  white "开始申请SSL证书..."
  systemctl stop nginx
  mkdir -p /root/bratul
  ~/.acme.sh/acme.sh --register-account -m "$SSL_EMAIL"
  ~/.acme.sh/acme.sh --issue -d "$SSL_DOMAIN" --standalone
  ~/.acme.sh/acme.sh --installcert -d "$SSL_DOMAIN" --key-file /root/bratul/private.key --fullchain-file /root/bratul/cert.crt
  ~/.acme.sh/acme.sh --upgrade --auto-upgrade

  # 验证证书是否成功申请
  if [ ! -f "/root/bratul/private.key" ] || [ ! -f "/root/bratul/cert.crt" ]; then
    red "证书申请失败，请重新运行脚本"
    rm -rf /mnt/brutal.sh     #delete    
    exit 1
  fi

  green "SSL证书配置完成"
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
        rm -rf /mnt/brutal.sh     #delete        
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
            rm -rf /mnt/brutal.sh    #delete    
            echo "=================================================================="
            echo -e "\t\t\tSing-Box 升级完毕"
            echo -e "\n"
            echo -e "温馨提示:\n本脚本仅在ubuntu22.04环境下测试，其他环境未经验证 "
            echo "=================================================================="
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
    rm -rf go1.22.4.linux-amd64.tar.gz
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
    wget -q -O /usr/local/etc/sing-box/config.json https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/brutal/singbox/brutal_singbox_config.json
    singbox_config_file="/usr/local/etc/sing-box/config.json"
    if [ ! -f "$singbox_config_file" ]; then
        red "错误：配置文件 $singbox_config_file 不存在"
        red "请检查网络可正常访问github后运行脚本"
        rm -rf /mnt/brutal.sh     #delete        
        exit 1
    fi
    generate_singbox_config

    white "正在修正配置..."

    sed -i "s/singbox_port/${singbox_input_port}/g" /usr/local/etc/sing-box/config.json
    sed -i "s/singbox_uuid/${uuid}/g" /usr/local/etc/sing-box/config.json
    sed -i "s/vps_ip_domain/${vps_ip_domain}/g" /usr/local/etc/sing-box/config.json
    sed -i "s/ssl_domain/${ssl_domain}/g" /usr/local/etc/sing-box/config.json
    sed -i "s/singbox_privatekey/${PrivateKey}/g" /usr/local/etc/sing-box/config.json
    sed -i "s/singbox_short_id/${short_id}/g" /usr/local/etc/sing-box/config.json
    sed -i "s/singbox_up_mbps/${singbox_input_up_mbps}/g" /usr/local/etc/sing-box/config.json
    sed -i "s/singbox_down_mbps/${singbox_input_down_mbps}/g" /usr/local/etc/sing-box/config.json
}

################################获取singbox相关配置################################
generate_singbox_config() {
  # 生成UUID
  uuid=$(sing-box generate uuid)
  
  # 生成公钥和私钥
  keypair=$(sing-box generate reality-keypair)
  PrivateKey=$(echo "$keypair" | grep 'PrivateKey:' | awk -F ': ' '{print $2}')
  PublicKey=$(echo "$keypair" | grep 'PublicKey:' | awk -F ': ' '{print $2}')
  
  # 生成short id
  short_id=$(sing-box generate rand --hex 8)
  
  # 验证是否成功生成了所有必需的值
  if [[ -z "$uuid" || -z "$PrivateKey" || -z "$PublicKey" || -z "$short_id" ]]; then
    echo "singbox参数获取失败，请检查安装情况"
    rm -rf /mnt/brutal.sh     #delete    
    exit 1
  fi
}

# 生成出站节点配置
outbounds_setting() {
    white "开始根据sing-box配置文件及程序生成出站节点配置..."
    config_file="/usr/local/etc/sing-box/config.json"

    # 检查配置文件是否存在
    if [[ ! -f "$config_file" ]]; then
        red "未找到配置文件 $config_file，退出脚本"
        rm -rf /mnt/brutal.sh     #delete        
        exit 1
    fi

    # 检查是否有空值变量
    if [[ -z "$singbox_input_port" || -z "$vps_ip_domain" || -z "$ssl_domain" || -z "$singbox_input_up_mbps" || -z "$singbox_input_down_mbps" ]]; then

        # 读取配置文件中的 vless 类型节点数量
        vless_count=$(jq '[.inbounds[] | select(.type=="vless")] | length' "$config_file")

        # 如果 vless 节点超过一个，输出提示并退出脚本
        if [[ $vless_count -gt 1 ]]; then
            red "配置文件中存在多个 vless 节点，请手动配置"
            rm -rf /mnt/brutal.sh     #delete            
            exit 1
        elif [[ $vless_count -eq 1 ]]; then
            # 如果仅有一个 vless 节点，提取相关变量值
            singbox_input_port=$(jq -r '.inbounds[] | select(.type=="vless") | .listen_port' "$config_file")
            vps_ip_domain=$(jq -r '.inbounds[] | select(.type=="vless") | .tls.server_name' "$config_file")
            ssl_domain=$(jq -r '.inbounds[] | select(.type=="vless") | .tls.reality.handshake.server' "$config_file")
            singbox_input_up_mbps=$(jq -r '.inbounds[] | select(.type=="vless") | .multiplex.brutal.up_mbps' "$config_file")
            singbox_input_down_mbps=$(jq -r '.inbounds[] | select(.type=="vless") | .multiplex.brutal.down_mbps' "$config_file")
            white "配置变量获取成功"
        else
            red "未找到 vless 节点，请检查配置文件"
            rm -rf /mnt/brutal.sh     #delete            
            exit 1
        fi

    else
        white "所有变量已配置，无需更改"
    fi

    if [[ -z "$uuid" || -z "$PrivateKey" || -z "$PublicKey" || -z "$short_id" ]]; then
        generate_singbox_config
        white "参数变量获取成功"
    fi

    white "开始生成出站节点配置..."
    wget -q -O /usr/local/etc/sing-box/outbounds.json https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/brutal/singbox/outbounds.json

    white "\n参数变量："
    white "VPS IP或域名: ${yellow}$vps_ip_domain${reset}"
    white "监听端口: ${yellow}$singbox_input_port${reset}"
    white "证书域名: ${yellow}$ssl_domain${reset}"
    white "VPS 上行带宽: ${yellow}$singbox_input_up_mbps${reset}"
    white "VPS 下行带宽: ${yellow}$singbox_input_down_mbps${reset}"
    white "UUID: ${yellow}$uuid${reset}"
    white "PrivateKey: ${yellow}$PrivateKey${reset}"
    white "PublicKey: ${yellow}$PublicKey${reset}"
    white "Short ID: ${yellow}$short_id${reset}"

    outbounds_config_file="/usr/local/etc/sing-box/outbounds.json"
    if [ ! -f "$outbounds_config_file" ]; then
        red "错误：配置文件 $outbounds_config_file 不存在"
        red "请检查网络可正常访问github后运行脚本"
        rm -rf /mnt/brutal.sh     #delete        
        exit 1
    fi

    white "开始修正出站节点..."
    sed -i "s/singbox_input_port/${singbox_input_port}/g" /usr/local/etc/sing-box/outbounds.json
    sed -i "s/singbox_uuid/${uuid}/g" /usr/local/etc/sing-box/outbounds.json
    sed -i "s/vps_ip_domain/${vps_ip_domain}/g" /usr/local/etc/sing-box/outbounds.json
    sed -i "s/ssl_domain/${ssl_domain}/g" /usr/local/etc/sing-box/outbounds.json
    sed -i "s/singbox_PublicKey/${PublicKey}/g" /usr/local/etc/sing-box/outbounds.json
    sed -i "s/singbox_short_id/${short_id}/g" /usr/local/etc/sing-box/outbounds.json
    sed -i "s/singbox_input_up_mbps/${singbox_input_up_mbps}/g" /usr/local/etc/sing-box/outbounds.json
    [ -f /mnt/brutal.sh ] && rm -rf /mnt/brutal.sh     #delete
    green "出站节点配置文件已生成，路径$outbounds_config_file"
}

################################ 结束通知 ################################
over_brutal_install() {
    systemctl enable --now nginx
    systemctl enable --now sing-box
    systemctl daemon-reload
    systemctl restart sing-box
    [ -f /mnt/brutal.sh ] && rm -rf /mnt/brutal.sh     #delete
    echo "=================================================================="
    echo -e "\t\t\tbrutal 节点安装完毕"
    echo -e "\n"
    echo -e "sing-box运行目录为${yellow}/usr/loacl/etc/sing-box${reset}"
    echo -e "sing-box出站节点配置已生成，路径为: \n${yellow}/usr/local/etc/sing-box/outbounds.json${reset}"
    echo -e "温馨提示:\n本脚本仅在ubuntu22.04环境下测试，其他环境未经验证 "
    echo "=================================================================="
}

################################ 主程序 ################################
brutal_choose
