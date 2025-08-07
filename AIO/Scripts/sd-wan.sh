#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
export APT_LISTCHANGES_FRONTEND=none

rm -rf /mnt/main_install.sh
# 检查是否为root用户执行
[[ $EUID -ne 0 ]] && echo -e "错误：必须使用root用户运行此脚本！\n" && exit 1
# 颜色定义
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
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

spin() {
  local message="$1"
  echo -en "${BLUE}[INFO]${NC} $message "

  local chars='| / - \\'
  _spinner_running=true

  {
    while $_spinner_running; do
      for c in $chars; do
        echo -ne "\b$c"
        sleep 0.1
      done
    done
  } &
  _spinner_pid=$!
}

stopspin() {
  if [ -n "$_spinner_pid" ]; then
    _spinner_running=false
    kill "$_spinner_pid" >/dev/null 2>&1
    wait "$_spinner_pid" 2>/dev/null
    echo -ne "\b"
    unset _spinner_pid
  fi
}

private_ip=$(ip route get 1.2.3.4 | awk '{print $7}' | head -1)
private_lan=$(echo "$private_ip" | cut -d'.' -f1-3)

################################ 基础环境设置 ################################
basic_settings() {
    spin "配置基础设置并安装依赖..."
    sleep 1
    apt-get update -y && apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || { red "环境更新失败！退出脚本"; exit 1; }
    # green "环境更新成功"
    # white "环境依赖安装开始..."
    apt install curl git build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64 jq dos2unix socat -y || { red "环境依赖安装失败！退出脚本"; exit 1; }
    # green "依赖安装成功"
    timedatectl set-timezone Asia/Shanghai || { red "时区设置失败！退出脚本"; exit 1; }
    # green "时区设置成功"
    ntp_config="NTP=ntp.aliyun.com"
    echo "$ntp_config" | sudo tee -a /etc/systemd/timesyncd.conf > /dev/null
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-timesyncd
    # green "已将 NTP 服务器配置为 ntp.aliyun.com"
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
                # green "53端口占用已解除"
            # else
                # green "未找到53端口占用配置，无需操作"
            fi
        elif [ "$dns_stub_listener" = "DNSStubListener=yes" ]; then
            # 如果找到 DNSStubListener=yes，则修改为 no
            sed -i 's/^DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
            systemctl restart systemd-resolved.service
            # green "53端口占用已解除"
        elif [ "$dns_stub_listener" = "DNSStubListener=no" ]; then
            # 如果 DNSStubListener 已为 no，提示用户无需修改
            # green "53端口未被占用，无需操作"
        fi
    else
        # green "/etc/systemd/resolved.conf 不存在，无需操作"
    fi
    stopspin
    log_success "配置基础设置并安装依赖完成"
}

################################ 变量参数设定 ################################
custom_settings() {
    white "${yellow}说明：${reset}"
    white "${yellow}1. 本脚本支持申请泛域名证书并自动续期。${reset}"
    white "${yellow}2. 本脚本仅支持域名委托CF解析操作。${reset}"
    white "${yellow}3. 使用前需将域名在CF设置好解析，并已解析成功。${reset}"
    white "${yellow}4. 如未设置解析，现在请自行设置解析并解析成功后继续脚本。${reset}"

    # 读取域名
    while [[ -z "$DOMAIN" ]]; do
        read -p "请输入您的域名（例如：*.example.com）[支持泛域名]: " DOMAIN
        if [[ -z "$DOMAIN" ]]; then
            red "域名不能为空，请重新输入"
        fi
    done
    
    # 读取Cloudflare API Token
    while [[ -z "$CF_TOKEN" ]]; do
        read -s -p "请输入Cloudflare API Token （API 令牌）: " CF_TOKEN
        echo
        if [[ -z "$CF_TOKEN" ]]; then
            red "API Token （API 令牌）不能为空，请重新输入"
        fi
    done
    
    # 读取Cloudflare Account ID
    while [[ -z "$CF_ACCOUNT_ID" ]]; do
        read -p "请输入Cloudflare Account ID: " CF_ACCOUNT_ID
        if [[ -z "$CF_ACCOUNT_ID" ]]; then
            red "Account ID不能为空，请重新输入"
        fi
    done
    
    # 读取Cloudflare Zone ID
    while [[ -z "$CF_ZONE_ID" ]]; do
        read -p "请输入Cloudflare Zone ID: " CF_ZONE_ID
        if [[ -z "$CF_ZONE_ID" ]]; then
            red "Zone ID不能为空，请重新输入"
        fi
    done
    
    # 读取SSL证书安装路径
    read -p "请输入SSL证书安装目录（默认：/usr/local/etc/nginx/ssl）: " SSL_DIR
    SSL_DIR=${SSL_DIR:-"/usr/local/etc/nginx/ssl"}

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

    while [[ -z "${in_port}" ]]; do
        read -p "请输入您的本机组网节点的入站端口： " in_port
        if [[ ! "$in_port" =~ ^[0-9]{1,5}$ ]] || [[ "$in_port" -lt 1 ]] || [[ "$in_port" -gt 65535 ]]; then
            red "无效的端口号，请输入 1-65535 之间的数字"
            in_port=""
        fi
    done

    while [[ -z "${in_password}" ]]; do
        read -p "请输入本机组网节点的密码: " in_password
        if [[ -z "${in_password}" ]]; then
            red "密码不能为空，请重新输入"
        fi
    done

    while [[ -z "${in_domain}" ]]; do
        read -p "请输入本机组网节点的域名: " in_domain
        if [[ $in_domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            red "域名格式不正确，请重新输入"
        fi
    done

    while [[ -z "${out_port}" ]]; do
        white "如无对端节点信息，可随意输入，后续注意手动修改。"
        read -p "请输入您的对端组网节点的入站端口： " out_port
        if [[ ! "$out_port" =~ ^[0-9]{1,5}$ ]] || [[ "$out_port" -lt 1 ]] || [[ "$out_port" -gt 65535 ]]; then
            red "无效的端口号，请输入 1-65535 之间的数字"
            out_port=""
        fi
    done

    while [[ -z "${out_password}" ]]; do
        white "如无对端节点信息，可随意输入，后续注意手动修改。"
        read -p "请输入对端组网节点的密码: " out_password
        if [[ -z "${out_password}" ]]; then
            red "密码不能为空，请重新输入"
        fi
    done

    while [[ -z "${out_domain}" ]]; do
        white "如无对端节点信息，可随意输入，后续注意手动修改。"
        read -p "请输入对端组网节点的域名: " out_domain
        if [[ $out_domain =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            red "域名格式不正确，请重新输入"
        fi
    done

    while [[ -z "${out_lan}" ]]; do
        read -p "请输入对端组网节点的内网网段（如：$private_lan.0/24）: " out_lan
        if [[ -z "${out_lan}" ]]; then
            red "密码不能为空，请重新输入"
        fi
    done

}

################################ 检查安装acme ################################
install_acmek_and_issue_certificate() {
    white "检查acme.sh安装状态..."
    if command -v acme.sh &> /dev/null || [[ -f ~/.acme.sh/acme.sh ]]; then
        green "acme.sh已安装"
    else
        white "acme.sh未安装，开始安装..."
        curl https://get.acme.sh | sh
   
        # 加载环境变量
        source ~/.bashrc
        # 验证安装
        if [[ -f ~/.acme.sh/acme.sh ]]; then
            green "acme.sh安装成功"
        else
            red "acme.sh安装失败"
            exit 1
        fi
    fi
   
    # 配置Cloudflare API信息
    export CF_Token="$CF_TOKEN"
    export CF_Account_ID="$CF_ACCOUNT_ID"
    export CF_Zone_ID="$CF_ZONE_ID"
    
    # 检测并处理泛域名（提前处理，用于目录创建）
    if [[ $DOMAIN == \*.* ]]; then
        CERT_DOMAIN=${DOMAIN#\*.}
    else
        CERT_DOMAIN=$DOMAIN
    fi
    
    # 创建SSL目录（使用处理后的域名，去掉*）
    white "创建SSL证书目录..."
    cert_dir="$SSL_DIR/$CERT_DOMAIN"
   
    if [[ ! -d "$cert_dir" ]]; then
        mkdir -p "$cert_dir"
        white "创建目录: $cert_dir"
    else
        white "目录已存在: $cert_dir"
    fi
    
    # 申请泛域名证书
    white "正在为 $DOMAIN 申请Let's Encrypt泛域名证书..."
    ~/.acme.sh/acme.sh --issue --dns dns_cf -d "$DOMAIN" --server letsencrypt --force
   
    if [[ $? -eq 0 ]]; then
        white "证书申请成功！"
    else
        red "证书申请失败"
        exit 1
    fi
    
    white "正在安装证书到指定目录..."  
    
    # 定义证书文件路径（使用已处理的CERT_DOMAIN）
    key_file="$SSL_DIR/$CERT_DOMAIN/$CERT_DOMAIN.key"
    cert_file="$SSL_DIR/$CERT_DOMAIN/$CERT_DOMAIN.crt"
    
    ~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" --key-file "$key_file" --fullchain-file "$cert_file"
   
    if [[ $? -eq 0 ]]; then
        white "证书安装成功！"
        white "私钥文件: $key_file"
        white "证书文件: $cert_file"
    else
        red "证书安装失败"
        exit 1
    fi
    
    # 设置自动更新
    white "设置证书自动更新..."    
    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
   
    if [[ $? -eq 0 ]]; then
        white "自动更新设置成功"
    else
        red "自动更新设置可能失败，请手动检查"
    fi
    
    # 验证证书
    white "验证证书..."  
    cert_path="/root/.acme.sh/$DOMAIN"_ecc/fullchain.cer  
    if [[ -f $cert_path ]]; then
        white "验证证书DNS信息..."
        openssl x509 -in "$cert_path" -noout -text | grep DNS        
        if [[ $? -eq 0 ]]; then
            green "证书验证成功"
        else
            red "证书验证可能存在问题"
        fi
    else
        red "证书文件未找到，请检查证书申请是否成功"
    fi

    white "开始配置SSL证书续期脚本..."
    wget --quiet --show-progress -O /mnt/update_ssl.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/brutal/nginx/update_ssl_new.sh && chmod +x /mnt/update_ssl.sh
    if ! crontab -l 2>/dev/null | grep -F "bash /mnt/update_ssl.sh" >/dev/null; then
        (crontab -l 2>/dev/null; echo "0 3 * * * bash /mnt/update_ssl.sh") | crontab -
    fi
    green "SSL证书续期脚本配置完成"
}
################################安装 Sing-Box################################
install_singbox() {
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
        spin "开始编译 Sing-Box $selected_version ..."
        rm -rf /root/go/bin/*
        rm -rf /mnt/singbox/go/bin/*
        go_version=$(curl -s https://go.dev/VERSION?m=text | head -1)
        curl -L "https://go.dev/dl/${go_version}.linux-${ARCH}.tar.gz" -o "${go_version}.linux-${ARCH}.tar.gz"
        sudo tar -C /usr/local -xzf "${go_version}.linux-${ARCH}.tar.gz"
        echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/golang.sh
        source /etc/profile.d/golang.sh
        go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@$selected_version
        # white "检测编译结果...."
        if ! go install -v -tags with_quic,with_grpc,with_dhcp,with_wireguard,with_ech,with_utls,with_reality_server,with_clash_api,with_gvisor,with_v2ray_api,with_lwip,with_acme github.com/sagernet/sing-box/cmd/sing-box@$selected_version; then
            red "Sing-Box 编译失败！退出脚本"
            rm -rf /mnt/sd-wan.sh    #delete    
            exit 1
        fi
        stopspin
        log_success "编译完成，准备提取版本信息..."

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
        spin "下载Sing-Box $selected_version ..."
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
        stopspin
        log_success "Sing-Box 安装完成"
    fi

    wget --quiet --show-progress -O /etc/systemd/system/sing-box.service https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO//Configs/sd-wan/sing-box.service
    if [ ! -f "/etc/systemd/system/sing-box.service" ]; then
        red "错误：启动文件 /etc/systemd/system/sing-box.service 不存在"
        red "请检查网络可正常访问github后运行脚本"
        rm -rf /mnt/psb.sh    #delete
        exit 1
    fi  
}
################################写入配置文件################################
install_config() {
    singbox_config_file="/usr/local/etc/singbox/config.json"
    wget --quiet --show-progress -O ${singbox_config_file} https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/sd-wan/config.json

    if [ ! -f ${singbox_config_file} ]; then
        red "错误：启动文件 ${singbox_config_file} 不存在"
        red "请检查网络可正常访问github后运行脚本"
        rm -rf /mnt/psb.sh    #delete
        exit 1
    fi 

    sed -i "s|本机监听端口|${in_port}|g" ${singbox_config_file}
    sed -i "s|本机密码|${in_password}|g" ${singbox_config_file}
    sed -i "s|本机域名|${in_domain}|g" ${singbox_config_file}
    sed -i "s|crt地址|${cert_file}|g" ${singbox_config_file}
    sed -i "s|key地址|${key_file}|g" ${singbox_config_file}
    sed -i "s|对端域名|${out_domain}|g" ${singbox_config_file}
    sed -i "s|对端端口|${out_port}|g" ${singbox_config_file}
    sed -i "s|对端密码|${out_password}|g" ${singbox_config_file}
    sed -i "s|对端内网IP|${out_lan}|g" ${singbox_config_file}      

    # 生成配置
    sd_wan_config=$(cat <<EOF
{
    "type": "trojan",
    "tag": "SD-Wan-Trojan",
    "server": "$in_domain",
    "server_port": $in_port,
    "password": "$in_password",
    "tls": {
        "enabled": true,
        "server_name": "$in_domain",
        "utls": {
            "enabled": true,
            "fingerprint": "chrome"
        }
    },
    "multiplex": {
        "enabled": true,
        "protocol": "h2mux",
        "max_connections": 4,
        "min_streams": 4
    }
},
EOF
)

    # 直接输出到文件
    echo "$sd_wan_config" | sudo tee /usr/local/etc/singbox/outbound.txt > /dev/null

}
################################安装tproxy################################
install_tproxy() {
    white "开始创建nftables tproxy转发..."
    apt install nftables -y
    if [ ! -f "/etc/systemd/system/sing-box-router.service" ]; then
        white "未找到 sing-box-router 服务文件，开始创建...." 
        wget --quiet --show-progress -O /etc/systemd/system/sing-box-router.service https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/sd-wan/sing-box-router.service
        green "sing-box-router 服务创建完成"
    else

        white "警告：sing-box-router 服务文件已存在，重新创建...."
        rm -rf /etc/systemd/system/sing-box-router.service
        wget --quiet --show-progress -O /etc/systemd/system/sing-box-router.service https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/sd-wan/sing-box-router.service
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
    wget --quiet --show-progress -O /etc/nftables.conf https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/sd-wan/nftables.conf
    if [ ! -f "/etc/nftables.conf" ]; then
        red "错误：启动文件 /etc/nftables.conf 不存在"
        red "请检查网络可正常访问github后运行脚本"
        rm -rf /mnt/psb.sh    #delete
        exit 1
    fi 

    sed -i "s|10.10.10.0/24|${private_lan}.0/24|g" /etc/nftables.conf
    sed -i "s|ens18|${selected_interface}|g" /etc/nftables.conf
    dos2unix /etc/nftables.conf
    green "nftables规则写入完成"

    nft flush ruleset
    nft -f /etc/nftables.conf
    systemctl enable --now nftables
    green "Nftables tproxy转发创建完成"

    white "开始启动sing-box..."
    systemctl enable --now sing-box-router
    systemctl enable --now sing-box
    green "Sing-box启动已完成"
}

################################结束语################################
install_over() {
    systemctl stop sing-box && systemctl daemon-reload && systemctl restart sing-box
    rm -rf /mnt/sd-wan.sh    #delete       
    echo "=================================================================="
    echo -e "\t\t\t ${yellow}异地组网${reset} 安装完毕"
    echo -e "\n"
    echo -e "运行目录为${yellow}/usr/loacl/etc/singbox${reset}"
    echo -e "WebUI地址:${yellow}http://$private_ip:9090${reset}"
    echo -e "对端出站节点已生成，地址:${yellow}/usr/local/etc/singbox/outbound.txt${reset}"
    echo -e "温馨提示:\n本脚本仅在 ubuntu25.04 环境下测试，其他环境未经验证，已查\n询程序运行状态，如出现\e[1m\e[32m active (running)\e[0m，程序已启动成功"
    echo "=================================================================="
    systemctl status sing-box
}

acme-part() {
    install_acmek_and_issue_certificate
}

singbox-part() {
    install_singbox
    install_config
    install_tproxy
} 

################################## SD Wan 选择 ################################
sd_wan_choose() {
    clear
    echo "=================================================================="
    echo -e "\t\t 异地组网脚本 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo "欢迎使用异地组网脚本"
    echo "请选择要执行的服务："
    echo "=================================================================="
    echo "1. 安装异地组网"
    echo -e "\t"
    echo "-. 返回上级菜单"      
    echo "0) 退出脚本"
    read -p "请选择服务: " choice
    # read choice
    case $choice in
        1)
            white "安装异地组网"
            custom_settings
            basic_settings
            acme-part
            singbox-part
            install_over
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
            sd_wan_choose
            ;;
    esac
}

################################ 主程序 ################################
sd_wan_choose