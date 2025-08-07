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

################################ 基础环境设置 ################################
basic_settings() {
    spin "正在更新系统基础环境..."
    apt-get update -y >/dev/null 2>&1 && apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" >/dev/null 2>&1 || { red "环境更新失败！退出脚本"; exit 1; }
    stopspin
    log_success "环境更新成功"
    spin "环境依赖安装开始..."
    apt install curl git build-essential socat libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64 jq p7zip-full p7zip-rar dos2unix -y >/dev/null 2>&1 || { red "环境依赖安装失败！退出脚本"; exit 1; }
    stopspin
    log_success "依赖安装成功"
    timedatectl set-timezone Asia/Shanghai || { red "时区设置失败！退出脚本"; exit 1; }
    log_success "时区设置成功"
    ntp_config="NTP=ntp.aliyun.com"
    echo "$ntp_config" | sudo tee -a /etc/systemd/timesyncd.conf > /dev/null
    systemctl daemon-reload
    systemctl restart systemd-timesyncd
    log_success "已将 NTP 服务器配置为 ntp.aliyun.com"
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
                log_success "53端口占用已解除"
            else
                green "未找到53端口占用配置，无需操作"
            fi
        elif [ "$dns_stub_listener" = "DNSStubListener=yes" ]; then
            # 如果找到 DNSStubListener=yes，则修改为 no
            sed -i 's/^DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
            systemctl restart systemd-resolved.service
            log_success "53端口占用已解除"
        elif [ "$dns_stub_listener" = "DNSStubListener=no" ]; then
            green "53端口未被占用，无需操作"
        fi
    else
        green "/etc/systemd/resolved.conf 不存在，无需操作"
    fi
    lanip_segment=$private_lan.0/24
}

################################  检查现有证书 ################################ 
check_existing_cert() {
    white "检查本机acme已申请的证书..."

    acme_script=$(find /root /home -name "acme.sh" -type f -executable 2>/dev/null | head -1)
    
    if [[ -z "$acme_script" ]]; then
        if command -v acme.sh &> /dev/null; then
            acme_script=$(which acme.sh)
        else
            log_error "未找到acme.sh，稍后将进行安装"
            CERT_EXISTS=false
            current_cert_path=""
        fi
    fi
    
    ACME_CMD="$acme_script"
    ACME_DIR="$(dirname "$acme_script")"

    cert_list=$(eval "$ACME_CMD --list" 2>/dev/null)

    search_domain="$DOMAIN"
    found_in_list=false
    
    if echo "$cert_list" | grep -q "$DOMAIN"; then
        found_in_list=true
    else
        domain_parts=(${DOMAIN//./ })
        if [[ ${#domain_parts[@]} -gt 2 ]]; then
            wildcard_domain="*.${DOMAIN#*.}"
            if echo "$cert_list" | grep -q "$wildcard_domain"; then
                search_domain="$wildcard_domain"
                found_in_list=true
            fi
        fi
    fi
    
    if [[ "$found_in_list" != true ]]; then
        log_error "未在证书列表中找到匹配的域名或泛域名证书"
        CERT_EXISTS=false
        current_cert_path=""
        return 1
    fi

    cert_info=$(eval "$ACME_CMD --info -d \"$search_domain\"" 2>/dev/null)

    installed_cert_file=""
    installed_key_file=""
    installed_matrix_file=""
        
    if [[ -n "$cert_info" ]]; then
        # 提取已安装的证书文件路径
        installed_cert_file=$(echo "$cert_info" | grep "Le_RealFullChainPath=" | cut -d'=' -f2 | xargs)
        installed_key_file=$(echo "$cert_info" | grep "Le_RealKeyPath=" | cut -d'=' -f2 | xargs)
        full_path=$(echo "$cert_info" | grep 'DOMAIN_CONF=' | cut -d'=' -f2 | xargs)
        installed_matrix_file=$(dirname "$full_path")
        # 如果上面没找到，尝试其他可能的字段名
        if [[ -z "$installed_cert_file" ]]; then
            installed_cert_file=$(echo "$cert_info" | grep -i "Le_RealCertPath=" | cut -d'=' -f2 | xargs)
        fi
        
        log_success "从证书信息提取的路径："
        log_success "证书安装目录：$installed_matrix_file"        
        log_success "证书文件：$installed_cert_file"
        log_success "私钥文件：$installed_key_file"

    fi
    
    # 检查提取的安装路径是否有效
    if [[ -n "$installed_cert_file" && -f "$installed_cert_file" && -n "$installed_key_file" && -f "$installed_key_file" ]]; then
        cert_file="$installed_cert_file"
        key_file="$installed_key_file"
        matrix_file="$installed_matrix_file"
        cert_path="$(dirname "$installed_cert_file")"
        
        # 检查证书有效期
        if openssl x509 -in "$cert_file" -noout -checkend 604800 2>/dev/null; then
            log_success "已安装的证书有效且未过期，将使用已安装的证书，证书文件：$cert_file，私钥文件：$key_file"
            CERT_EXISTS=true
            return 0
        else
            log_error "已安装的证书即将过期或已过期"
        fi
    else
        log_error "未找到有效的已安装证书路径，需要重新申请证书"
        CERT_EXISTS=false
        current_cert_path=""
        return 1
    fi
}

################################ 自定义设置 ################################
custom_nginx_settings() {
    while true; do
        clear
        read -p "请输入 Nginx 配置文件名称: " nginx_name
        if [[ -z "$nginx_name" ]]; then
            log_error "Nginx 配置文件名称不能为空，请重新输入"
        else
            break
        fi
    done

    while true; do
        clear
        white "请选择 Nginx 服务类型："
        white "1) 反向代理 [默认选项]"
        white "2) 企业微信转发"  
        read -p "请输入选择 (1 或 2): " nginx_service_choice
        nginx_service_choice=${nginx_service_choice:-1} 
        case $nginx_service_choice in
            1)
                nginx_service_choice="reverse_proxy"
                white "已选择：反向代理"
                break
                ;;
            2)
                nginx_service_choice="wework_forward"
                white "已选择：企业微信转发"
                break
                ;;
            *)
                red "无效选择，请输入 1 或 2"
                ;;
        esac
    done


    while [[ -z "${NGINX_LISTEN_PORT}" ]]; do
        clear
        read -p "请输入Nginx 服务 HTTPS 监听端口 [默认8443端口]： " NGINX_LISTEN_PORT
        NGINX_LISTEN_PORT=${NGINX_LISTEN_PORT:-8443}
        if [[ ! "$NGINX_LISTEN_PORT" =~ ^[0-9]{1,5}$ ]] || [[ "$NGINX_LISTEN_PORT" -lt 1 ]] || [[ "$NGINX_LISTEN_PORT" -gt 65535 ]]; then
            red "无效的端口号，请输入 1-65535 之间的数字"
            NGINX_LISTEN_PORT=""
        fi
    done

    while true; do
        clear
        read -p "请输入反向代理/企业微信转发监听的域名（如：example.com 或 *.example.com）[支持泛域名证书]: " DOMAIN
        if [[ "$DOMAIN" =~ ^\*\.[a-zA-Z0-9-]+\.[a-zA-Z0-9.-]+$ ]] || [[ "$DOMAIN" =~ ^[a-zA-Z0-9-]+\.[a-zA-Z0-9.-]+$ ]]; then
            if [[ ! "$DOMAIN" =~ \.\. ]] && [[ ! "$DOMAIN" =~ \.$ ]] && [[ ! "$DOMAIN" =~ ^[^*].*^\. ]]; then
                break
            else
                log_error "域名格式不正确，请输入正确的域名格式（如: example.com 或 *.example.com）"
            fi
        else
            log_error "域名格式不正确，请输入正确的域名格式（如: example.com 或 *.example.com）"
        fi
    done

    check_existing_cert

    if [[ "$CERT_EXISTS" == "false" ]]; then
        if [[ "$DOMAIN" == \*.* ]]; then
            white "${yellow}您申请的是泛域名$DOMAIN 证书${reset}"
            while true; do
                read -p "请输入反向代理域名: " config_domain
                if [[ "$config_domain" =~ ^[a-zA-Z0-9-]+\.[a-zA-Z0-9.-]+$ ]] && [[ ! "$config_domain" =~ ^\. ]] && [[ ! "$config_domain" =~ \.$ ]] && [[ ! "$config_domain" =~ \.\. ]]; then
                    break
                else
                    log_error "域名格式不正确，请输入正确的域名格式"
                fi
            done
        fi

        temp_config_files=($(ls /tmp/.acme_cf_config 2>/dev/null))
        if [[ ${#temp_config_files[@]} -gt 0 ]]; then
            latest_config=$(ls -t /tmp/.acme_cf_config 2>/dev/null | head -n1)
            if [[ -f "$latest_config" ]]; then
                source "$latest_config"
                green "Cloudflare 域名申请账户信息已填写，后续将直接申请证书"
                if [[ -n "$CF_TOKEN" ]] && [[ -n "$CF_ACCOUNT_ID" ]] && [[ -n "$CF_ZONE_ID" ]]; then
                    white "  - CF_TOKEN: 已设置 (${#CF_TOKEN} 字符)"
                    white "  - CF_ACCOUNT_ID: $CF_ACCOUNT_ID"
                    white "  - CF_ZONE_ID: $CF_ZONE_ID"
                fi
            fi
        fi

        if [[ -z "$CF_TOKEN" ]] || [[ -z "$CF_ACCOUNT_ID" ]] || [[ -z "$CF_ZONE_ID" ]]; then
            while [[ -z "$CF_TOKEN" ]]; do
                clear
                read -s -p "请输入Cloudflare API Token （API 令牌，非全局）: " CF_TOKEN
                if [[ -z "$CF_TOKEN" ]]; then
                    log_error "API Token （API 令牌）不能为空，请重新输入"
                fi
            done
            
            while [[ -z "$CF_ACCOUNT_ID" ]]; do
                clear
                read -p "请输入Cloudflare Account ID（申请CF账户的邮箱）: " CF_ACCOUNT_ID
                if [[ -z "$CF_ACCOUNT_ID" ]]; then
                    log_error "Account ID不能为空，请重新输入"
                fi
            done
            
            while [[ -z "$CF_ZONE_ID" ]]; do
                clear
                read -p "请输入Cloudflare Zone ID（域名区域 ID）: " CF_ZONE_ID
                if [[ -z "$CF_ZONE_ID" ]]; then
                    log_error "Zone ID不能为空，请重新输入"
                fi
            done
        fi
    fi

    if [[ "$nginx_service_choice" == "reverse_proxy" ]]; then       
        while true; do
            clear
            read -p "请输入反向代理内网服务IP:端口，如：http://10.10.10.1:80 或 https://10.10.10.1:80 ，须去掉结尾的/" UPSTREAM_IP
            if [[ -n "$UPSTREAM_IP" ]]; then
                break
            else
                log_error "IP地址不能为空"
            fi
        done    
    fi

    while true; do
        clear    
        read -p "主路由转发端口是否为 8443？(y/N): " is_8443
        is_8443=${is_8443:-N}
        case "$is_8443" in
            [Yy])
                MAIN_ROUTER_PORT="8443"
                break
                ;;
            [Nn])
                while [[ -z "${MAIN_ROUTER_PORT}" ]]; do
                    read -p "请输入您的主路由转发端口： " MAIN_ROUTER_PORT
                    if [[ ! "$MAIN_ROUTER_PORT" =~ ^[0-9]{1,5}$ ]] || [[ "$MAIN_ROUTER_PORT" -lt 1 ]] || [[ "$MAIN_ROUTER_PORT" -gt 65535 ]]; then
                        red "无效的端口号，请输入 1-65535 之间的数字"
                        MAIN_ROUTER_PORT=""
                    fi
                done 
                break
                ;;
            *)
                log_error "请输入 y 或 n"
                ;;
        esac
    done
}

################################ 安装 Acme 服务 ################################
install_acme_service(){
    white "检查acme.sh安装状态..."
    if command -v ~/.acme.sh/acme.sh &> /dev/null || command -v /root/.acme.sh/acme.sh &> /dev/null; then
        log_success "acme.sh已安装"
    else
        spin "acme.sh未安装，开始安装..."
        curl -fsSL https://get.acme.sh | sh >/dev/null 2>&1
        stopspin
        source ~/.bashrc

        if [[ -f ~/.acme.sh/acme.sh ]]; then
            log_success "acme.sh安装成功"
        else
            red "acme.sh安装失败"
            exit 1
        fi
    fi

    if [[ "$CERT_EXISTS" == "false" ]]; then   
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
        cert_dir="/usr/local/etc/nginx/ssl/$CERT_DOMAIN"
    
        if [[ ! -d "$cert_dir" ]]; then
            mkdir -p "$cert_dir"
            white "创建目录: $cert_dir"
        else
            white "目录已存在: $cert_dir"
        fi
        
        # 申请证书
        spin "正在为 $DOMAIN 申请Let's Encrypt证书..."
        ~/.acme.sh/acme.sh --issue --dns dns_cf -d "$DOMAIN" --server letsencrypt --force 1>/dev/null 
        stopspin
  
        if [[ $? -eq 0 ]]; then
            white "[OK]证书申请成功..."
        else
            red "[ERROR]证书申请失败"
            exit 1
        fi 
        white "正在安装证书到指定目录..."  
        
        # 定义证书文件路径（使用已处理的CERT_DOMAIN）
        key_file="$cert_dir/$CERT_DOMAIN.key"
        cert_file="$cert_dir/$CERT_DOMAIN.crt"
        
        ~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" --key-file "$key_file" --fullchain-file "$cert_file" 1>/dev/null
    
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
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade 1>/dev/null
    
        if [[ $? -eq 0 ]]; then
            white "自动更新设置成功"
        else
            log_error "自动更新设置可能失败，请手动检查"
        fi
        
        # 验证证书
        white "验证证书..."  
        cert_path="/root/.acme.sh/$DOMAIN"_ecc/fullchain.cer  
        if [[ -f $cert_path ]]; then
            white "验证证书DNS信息..."
            openssl x509 -in "$cert_path" -noout -text | grep DNS        
            if [[ $? -eq 0 ]]; then
                log_success "证书验证成功"
            else
                log_error "证书验证可能存在问题"
            fi
        else
            log_error "证书文件未找到，请检查证书申请是否成功"
        fi

        white "开始配置SSL证书续期脚本..."
        wget --quiet --show-progress -O /mnt/update_ssl.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/brutal/nginx/update_ssl_new.sh && chmod +x /mnt/update_ssl.sh
        if ! crontab -l 2>/dev/null | grep -F "bash /mnt/update_ssl.sh" >/dev/null; then
            (crontab -l 2>/dev/null; echo "0 3 * * * bash /mnt/update_ssl.sh") | crontab -
        fi
        log_success "SSL证书续期脚本配置完成"
    fi
}

################################ 安装 Nginx 服务 ################################
install_nginx_service() {
    if command -v nginx &> /dev/null; then
        green "Nginx已安装，版本信息："
        nginx -v
        return 0
    else
        spin "Nginx 未安装，开始安装..."
        apt-get install -y nginx 1>/dev/null 
        stopspin
        if command -v nginx &> /dev/null; then
            log_success "Nginx安装成功"
            systemctl enable nginx --now
        else
            red "Nginx安装失败"
            exit 1
        fi
    fi
}

################################ 配置 Nginx 配置 ################################
install_nginx_config() {

    if [ -z "$nginx_file_confpath" ]; then
        if command -v nginx >/dev/null 2>&1; then
            # 通过 nginx -T 获取配置文件路径
            nginx_conf_main=$(nginx -T 2>/dev/null | grep -E "^# configuration file" | head -1 | awk '{print $4}' | sed 's/:$//')
            
            # 如果方法1失败，尝试通过 nginx -t 获取
            if [ -z "$nginx_conf_main" ]; then
                nginx_conf_main=$(nginx -t 2>&1 | grep -E "(configuration file|config file)" | head -1 | sed -n 's/.*file \([^ ]*\).*/\1/p')
            fi
            
            # 如果前两种方法都失败，尝试常见路径
            if [ -z "$nginx_conf_main" ]; then
                for common_path in "/etc/nginx/nginx.conf" "/usr/local/nginx/conf/nginx.conf" "/usr/local/etc/nginx/nginx.conf"; do
                    if [ -f "$common_path" ]; then
                        nginx_conf_main="$common_path"
                        break
                    fi
                done
            fi
            
            if [ -n "$nginx_conf_main" ] && [ -f "$nginx_conf_main" ]; then
                nginx_conf_dir=$(dirname "$nginx_conf_main")
                
                # 检查 conf.d 目录是否存在
                if [ -d "$nginx_conf_dir/conf.d" ]; then
                    nginx_file_confpath="$nginx_conf_dir/conf.d"
                else
                    if mkdir -p "$nginx_conf_dir/conf.d" 2>/dev/null; then
                        nginx_file_confpath="$nginx_conf_dir/conf.d"
                    else
                        nginx_file_confpath="$nginx_conf_dir"
                    fi
                fi
                
                white "找到 nginx 配置目录: $nginx_file_confpath"
            else
                red "无法找到 nginx 配置文件路径"
                exit 1
            fi
        else
            red "nginx 未安装，请先安装 nginx"
            exit 1
        fi
    fi

    # 创建日志目录
    log_dir="${nginx_conf_dir}/log"
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir"
        white "创建日志目录: $log_dir"
    fi

    # 设置日志文件路径
    access_log_path="${log_dir}/${nginx_name}_access.log"
    error_log_path="${log_dir}/${nginx_name}_error.log"

    # 删除默认default
    default_config_path="${nginx_conf_dir}/sites-enabled/default"
    if [ ! -f "$default_config_path" ] || ! grep -q "# 默认服务器 - 处理未授权域名访问" "$default_config_path"; then
        if [ -f "$default_config_path" ]; then
            rm "$default_config_path"
        fi
        wget --quiet --show-progress -O $default_config_path https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/nginx/default
    fi

    #创建新的default并申请证书
    if [[ ! -f "/usr/local/etc/nginx/ssl/default/default.key" || ! -s "/usr/local/etc/nginx/ssl/default/default.key" || ! -f "/usr/local/etc/nginx/ssl/default/default.pem" || ! -s "/usr/local/etc/nginx/ssl/default/default.pem" ]]; then
        mkdir -p /usr/local/etc/nginx/ssl/default
        openssl ecparam -genkey -name prime256v1 -out /usr/local/etc/nginx/ssl/default/default.key
        openssl req -new -x509 -days 36500 -key /usr/local/etc/nginx/ssl/default/default.key -out /usr/local/etc/nginx/ssl/default/default.pem -subj "/CN=default"
    fi
    
    if [[ "$nginx_service_choice" == "wework_forward" ]]; then
        wget --quiet --show-progress -O $nginx_file_confpath/$nginx_name.conf https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/nginx/wechat_forward_nginx.conf
        if [ ! -f "$nginx_file_confpath/$nginx_name.conf" ]; then
            red "错误：配置文件 $singbox_config_file 不存在"
            red "请检查网络可正常访问github后运行脚本"
            rm -rf /mnt/nginx.sh    #delete
            exit 1
        fi        
        if [[ "$DOMAIN" == \*.* ]]; then
            sed -i "s|wechat_forward_domain|${config_domain}|g" $nginx_file_confpath/$nginx_name.conf
        else
            sed -i "s|wechat_forward_domain|${DOMAIN}|g" $nginx_file_confpath/$nginx_name.conf
        fi
        sed -i "s|8443|${NGINX_LISTEN_PORT}|g" $nginx_file_confpath/$nginx_name.conf
        sed -i "s|SSL_WXYK|SSL_${nginx_name}|g" $nginx_file_confpath/$nginx_name.conf
        sed -i "s|proxy_access.log|${access_log_path}|g" $nginx_file_confpath/$nginx_name.conf
        sed -i "s|proxy_error.log|${error_log_path}|g" $nginx_file_confpath/$nginx_name.conf
        sed -i "s|cert_crt.crt|${cert_file}|g" $nginx_file_confpath/$nginx_name.conf
        sed -i "s|cert_key.key|${key_file}|g" $nginx_file_confpath/$nginx_name.conf
        sed -i "s|8080|${MAIN_ROUTER_PORT}|g" $nginx_file_confpath/$nginx_name.conf
    elif [ "$nginx_service_choice" == "reverse_proxy" ]; then
        wget --quiet --show-progress -O $nginx_file_confpath/$nginx_name.conf https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/nginx/web_proxy_nginx.conf
        if [ ! -f "$nginx_file_confpath/$nginx_name.conf" ]; then
            red "错误：配置文件 $singbox_config_file 不存在"
            red "请检查网络可正常访问github后运行脚本"
            rm -rf /mnt/nginx.sh    #delete
            exit 1
        fi 
        if [[ "$DOMAIN" == \*.* ]]; then
            sed -i "s|web_proxy_domain|${config_domain}|g" $nginx_file_confpath/$nginx_name.conf
        else
            sed -i "s|web_proxy_domain|${DOMAIN}|g" $nginx_file_confpath/$nginx_name.conf
        fi
        sed -i "s|8443|${NGINX_LISTEN_PORT}|g" $nginx_file_confpath/$nginx_name.conf
        sed -i "s|SSL_homepage|SSL_${nginx_name}|g" $nginx_file_confpath/$nginx_name.conf
        sed -i "s|proxy_access.log|${access_log_path}|g" $nginx_file_confpath/$nginx_name.conf
        sed -i "s|proxy_error.log|${error_log_path}|g" $nginx_file_confpath/$nginx_name.conf
        sed -i "s|cert_crt.crt|${cert_file}|g" $nginx_file_confpath/$nginx_name.conf
        sed -i "s|cert_key.key|${key_file}|g" $nginx_file_confpath/$nginx_name.conf
        sed -i "s|8080|${MAIN_ROUTER_PORT}|g" $nginx_file_confpath/$nginx_name.conf
        safe_upstream=$(printf '%s\n' "$UPSTREAM_IP" | sed 's/[&/\]/\\&/g')
        sed -i "s|http://127.0.0.1:3002|$safe_upstream|g" "$nginx_file_confpath/$nginx_name.conf"
    fi

    white "测试Nginx配置..."   
    if nginx -t; then
        log_success "Nginx配置测试通过"
        
        white "重载Nginx配置..."
        if systemctl reload nginx; then
            log_success "Nginx配置重载成功"
        else
            red "Nginx配置重载失败"
            exit 1
        fi
    else
        red "Nginx配置测试失败"
        exit 1
    fi
}

################################# C功能模块 ################################
# 设置/更新变量
function_set_variables() {
    echo -e "请输入Cloudflare API Token （API 令牌，非全局）: "
    echo "提示：CF_TOKEN 是敏感信息，输入时不会显示"
    read -s CF_TOKEN
    echo
    if [[ -z "$CF_TOKEN" ]]; then
        echo -e "${RED}CF_TOKEN 不能为空${NC}"
        return 1
    fi
    echo -e "${GREEN}\n CF_TOKEN 已设置\n ${NC}"
    
    echo -e "请输入Cloudflare Account ID（申请CF账户的邮箱）: "
    read CF_ACCOUNT_ID
    if [[ -z "$CF_ACCOUNT_ID" ]]; then
        echo -e "${RED}CF_ACCOUNT_ID 不能为空${NC}"
        return 1
    fi
    echo -e "${GREEN}\n CF_ACCOUNT_ID 已设置\n ${NC}"
    
    echo -n -e "请输入Cloudflare Zone ID（域名区域 ID）: "
    read CF_ZONE_ID
    if [[ -z "$CF_ZONE_ID" ]]; then
        echo -e "${RED}CF_ZONE_ID 不能为空${NC}"
        return 1
    fi
    echo -e "${GREEN}\n CF_ZONE_ID 已设置\n ${NC}"
    
    cat > "$CF_CONFIG_TMP_FILE" << EOF
# ACME Cloudflare 临时配置文件
# 生成时间: $(date)
# 注意：此文件将在系统重启后自动删除

export CF_TOKEN="$CF_TOKEN"
export CF_ACCOUNT_ID="$CF_ACCOUNT_ID"
export CF_ZONE_ID="$CF_ZONE_ID"
EOF
    
    chmod 600 "$CF_CONFIG_TMP_FILE"
    echo -e "${GREEN}变量已临时保存（重启后自动失效）${NC}"
    echo -e "${YELLOW}临时文件位置: $CF_CONFIG_TMP_FILE${NC}"
    
    export CF_TOKEN CF_ACCOUNT_ID CF_ZONE_ID
}

# 显示当前变量
function_show_variables() {
    echo -e "当前变量状态:"
    
    if [[ -n "$CF_TOKEN" ]]; then
        echo -e "CF_TOKEN: ${GREEN}已设置${NC} (${#CF_TOKEN} 字符)"
    else
        echo -e "CF_TOKEN: ${RED}未设置${NC}"
    fi
    
    if [[ -n "$CF_ACCOUNT_ID" ]]; then
        echo -e "CF_ACCOUNT_ID: ${GREEN}$CF_ACCOUNT_ID${NC}"
    else
        echo -e "CF_ACCOUNT_ID: ${RED}未设置${NC}"
    fi
    
    if [[ -n "$CF_ZONE_ID" ]]; then
        echo -e "CF_ZONE_ID: ${GREEN}$CF_ZONE_ID${NC}"
    else
        echo -e "CF_ZONE_ID: ${RED}未设置${NC}"
    fi
    
    echo
    # 检查ACME要求
    if [[ -z "$CF_TOKEN" ]] || [[ -z "$CF_ACCOUNT_ID" ]] || [[ -z "$CF_ZONE_ID" ]]; then
        echo -e "${RED}ACME 所需变量未完整设置${NC}"
    else
        echo -e "${GREEN}ACME 所需变量已完整设置，可以申请证书${NC}"
    fi
}

# 清除临时变量
function_clear_variables() {
    echo -n -e "${YELLOW}确认清除临时变量? [y/N]: ${NC}"
    read confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # 删除临时文件
        if [[ -f "$CF_CONFIG_TMP_FILE" ]]; then
            rm -f "$CF_CONFIG_TMP_FILE"
            echo -e "${GREEN}临时配置文件已删除${NC}"
        fi
        
        # 清除环境变量
        unset CF_TOKEN CF_ACCOUNT_ID CF_ZONE_ID
        echo -e "${GREEN}环境变量已清空${NC}"
    else
        echo -e "${YELLOW}操作已取消${NC}"
    fi
}

################################# 卸载 Acem 证书并清理 Nginx ################################
uninstall_sslcert() {
    clear
    echo -e "${YELLOW}================================${NC}"
    echo -e "${YELLOW}      SSL证书删除工具${NC}"
    echo -e "${YELLOW}================================${NC}"
    echo
    while true; do
        echo -en "请输入要删除证书的域名（如 example.com 或 *.example.com）: "
        read DOMAIN
        if [[ -z "$DOMAIN" ]]; then
            echo "域名不能为空，请重新输入"
            continue
        else
            if [[ ! "$DOMAIN" =~ ^(\*\.)?[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
                echo "域名格式不正确，请重新输入"
                continue
            fi
            echo "您输入的域名是: $DOMAIN"
            break
        fi    
    done

    check_existing_cert

    # 查找nginx配置目录
    NGINX_CONF_DIR=$(find /etc /usr /opt -type d -name conf.d 2>/dev/null | grep nginx | head -n 1)
    if [[ -z "$NGINX_CONF_DIR" ]]; then
        log_warning "未找到 nginx 的 conf.d 配置目录，跳过引用检查"
    else
        log_info "已检测到 nginx 配置目录：$NGINX_CONF_DIR"
    fi

    # 检查nginx配置文件引用
    if [[ -n "$NGINX_CONF_DIR" ]]; then
        local impacted=()
        local base_domain="${DOMAIN/\*/}"
        while IFS= read -r -d '' file; do
            impacted+=("$file")
        done < <(find "$NGINX_CONF_DIR" -type f -name "*.conf" -exec grep -l "$base_domain" {} \; 2>/dev/null | tr '\n' '\0')
        if (( ${#impacted[@]} > 0 )); then

            log_warning "以下 Nginx 配置文件中使用了包含此域名的证书路径，删除后将导致这些配置出错："
            for f in "${impacted[@]}"; do
                echo -e "  - ${f}"
            done

            while true; do
                echo -en "${YELLOW}[确认]${NC} 仍然继续删除证书相关文件，删除后同时删除相关的 Nginx 配置文件？ (Y/n): "
                read yn
                yn="${yn:-y}"
                case $yn in
                    [Yy]*) break ;;
                    [Nn]*) exit 0 ;;
                    *) echo "请输入 y 或 n" ;;
                esac
            done
        fi
    fi

    log_info "开始执行删除操作..."
    "$ACME_CMD" --remove -d $DOMAIN 1>/dev/null 

    if [[ -d "$cert_path" ]]; then
        rm -rf -- "$cert_path"
    fi

    if [[ -d "$matrix_file" ]]; then
        rm -rf -- "$matrix_file"
    fi

    for conf_path in "${impacted[@]}"; do
        if [[ -f "$conf_path" ]]; then
            rm -rf -- "$conf_path"
        fi
    done

    if ! command -v nginx &> /dev/null; then
        nginx -t 1>/dev/null 
        systemctl reload nginx 1>/dev/null 
    fi

    echo -e "${YELLOW}================================${NC}"
    echo -e "${YELLOW}        证书删除操作完成 ${NC}"
    echo -e "${YELLOW}================================${NC}"
    log_info "域名：$DOMAIN"
    echo -e "${YELLOW}已删除证书源安装目录: $matrix_file${NC}"
    echo -e "${YELLOW}已删除证书安装目录 - $cert_path${NC}"
    for conf_path in "${impacted[@]}"; do
        echo -e "${YELLOW}已删除 Nginx 配置 - $conf_path${NC}"
    done
    echo
    log_success "脚本执行完成！"
}

################################# 卸载 Acem、Nginx 并清理 ################################
uninstall_all() {
    # 查找 nginx 配置目录（conf.d）
    spin "正在查找 Nginx 配置目录..."
    NGINX_CONF_DIR=$(find / -type d -name conf.d 2>/dev/null | grep nginx | head -n 1)
    stopspin
    if [[ -z "$NGINX_CONF_DIR" ]]; then
        log_warning "未找到 nginx 的 conf.d 配置目录，跳过引用检查"
        cert_del_path=()
    else
        log_info "已检测到 nginx 配置目录：$NGINX_CONF_DIR"
        
        # 初始化临时文件
        tmp_paths=$(mktemp)
        tmp_raw=$(mktemp)
        
        # 查找所有 .conf 文件中的 ssl_certificate 和 ssl_certificate_key 配置
        log_info "正在搜索证书配置..."
        
        # 搜索所有.conf文件中的ssl证书配置
        find "$NGINX_CONF_DIR" -name "*.conf" -type f -exec grep -nH 'ssl_certificate' {} + 2>/dev/null > "$tmp_raw"

        # 修正的证书路径提取逻辑
        cat "$tmp_raw" | \
        grep -E 'ssl_certificate(_key)?\s+' | \
        sed -E 's/^[^:]*:[0-9]+:\s*ssl_certificate(_key)?\s+([^;]+);.*/\2/' | \
        sed -E 's/^\s*//g; s/\s*$//g' | \
        sed -E 's/^["\x27]//g; s/["\x27]$//g' | \
        while IFS= read -r cert_path; do
            [[ -z "$cert_path" ]] && continue
            
            if [[ "$cert_path" != /* ]]; then
                cert_path="$NGINX_CONF_DIR/$cert_path"
            fi
            
            dirname="$(dirname "$cert_path")"
            if [[ -d "$dirname" ]]; then
                echo "$dirname"
            else
                log_warning "证书目录不存在，跳过: $dirname"
            fi
        done | sort -u > "$tmp_paths"
        
        mapfile -t cert_del_path < "$tmp_paths"
        
        rm -f "$tmp_paths" "$tmp_raw"
        
        if [[ ${#cert_del_path[@]} -gt 0 ]]; then
            log_info "找到的唯一证书目录路径如下："
            for path in "${cert_del_path[@]}"; do
                echo " - $path"
            done
        else
            log_warning "在配置文件中未找到任何有效的证书路径引用"
        fi
    fi

    echo -e "${YELLOW}开始SSL服务和工具完全卸载...${NC}"

    # 停止服务
    log_info "停止相关服务..."
    systemctl stop nginx 2>/dev/null || true
    systemctl disable nginx 2>/dev/null || true
    systemctl stop acme.sh.timer 2>/dev/null || true
    systemctl disable acme.sh.timer 2>/dev/null || true
    systemctl stop acme.sh.service 2>/dev/null || true
    systemctl disable acme.sh.service 2>/dev/null || true
    log_success "服务已停止"

    # 卸载Nginx
    spin "卸载Nginx..."
    if command -v apt >/dev/null 2>&1; then
        apt remove --purge -y nginx nginx-common nginx-core nginx-full >/dev/null 2>&1 || true
        apt autoremove -y 1>/dev/null || true
    fi
    rm -rf /etc/nginx/ /var/log/nginx/ /var/cache/nginx/ /var/lib/nginx/ /usr/share/nginx/ 2>/dev/null || true
    stopspin
    log_success "Nginx已卸载"

    # 卸载acme.sh
    spin "卸载acme.sh..."
    command -v acme.sh >/dev/null 2>&1 && acme.sh --uninstall 2>/dev/null || true
    find / -maxdepth 4 -type d -name ".acme.sh" -exec rm -rf {} + 2>/dev/null || true
    find /root /home /opt /usr/local -maxdepth 3 -name "*acme*" -type d -exec rm -rf {} + 2>/dev/null || true
    find /usr/local/bin /usr/bin /bin /root /home -name "acme.sh" -type f -delete 2>/dev/null || true
    stopspin
    log_success "acme.sh已卸载"
        
    # 清理定时任务
    log_info "清理定时任务..."
    crontab -l 2>/dev/null | grep -v -E "(acme\.sh|letsencrypt)" | crontab - 2>/dev/null || true
    find /etc/cron* -name "*acme*" -delete 2>/dev/null || true
    find /etc/cron* -name "*letsencrypt*" -delete 2>/dev/null || true
    find /etc/systemd /usr/lib/systemd /lib/systemd -name "*acme*" -delete 2>/dev/null || true
    systemctl daemon-reload 2>/dev/null || true
    log_success "定时任务已清理"

    # 清理证书目录
    log_info "清理证书目录..."
    find /etc /opt /usr/local /var -maxdepth 4 -type d \( -name "*ssl*" -o -name "*tls*" -o -name "*cert*" -o -name "*acme*" -o -name "*letsencrypt*" \) 2>/dev/null | grep -E "(acme|letsencrypt)" | xargs rm -rf 2>/dev/null || true
    find /root /home -maxdepth 3 -type d \( -name "*acme*" -o -name "*cert*" \) -exec rm -rf {} + 2>/dev/null || true

    # 删除从nginx配置中找到的证书目录
    if [[ ${#cert_del_path[@]} -gt 0 ]]; then
        log_info "删除从nginx配置中找到的证书目录..."
        for conf_path in "${cert_del_path[@]}"; do
            if [[ -n "$conf_path" && -d "$conf_path" ]]; then
                log_info "正在删除证书目录: $conf_path"
                rm -rf "$conf_path"
                log_success "已删除证书目录: $conf_path"
            elif [[ -n "$conf_path" ]]; then
                log_warning "证书目录不存在，跳过: $conf_path"
            fi
        done
    else
        log_info "没有找到需要删除的证书目录"
    fi

    log_success "证书目录已清理"

    # 清理环境配置
    log_info "清理环境配置..."
    find /root /home -maxdepth 2 \( -name ".*rc" -o -name ".*profile" \) -type f 2>/dev/null | while read config_file; do
        if grep -q -E "(acme|letsencrypt)" "$config_file" 2>/dev/null; then
            cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
            sed -i -E '/acme|letsencrypt/d' "$config_file" 2>/dev/null || true
        fi
    done
    if [[ -f /etc/profile ]] && grep -q -E "(acme|letsencrypt)" /etc/profile 2>/dev/null; then
        cp /etc/profile /etc/profile.backup.$(date +%Y%m%d_%H%M%S)
        sed -i -E '/acme|letsencrypt/d' /etc/profile
    fi
    if [[ -f /etc/environment ]] && grep -q -E "(acme|letsencrypt)" /etc/environment 2>/dev/null; then
        cp /etc/environment /etc/environment.backup.$(date +%Y%m%d_%H%M%S)
        sed -i -E '/acme|letsencrypt/d' /etc/environment
    fi
    find /etc/profile.d -name "*acme*" -delete 2>/dev/null || true
    log_success "环境配置已清理"

    # 深度清理残留文件
    log_info "深度清理残留文件..."
    find / -maxdepth 6 -type f -name "*acme*" -delete 2>/dev/null || true
    find /var/log -name "*acme*" -delete 2>/dev/null || true
    find /var/log -name "*letsencrypt*" -delete 2>/dev/null || true
    rm -rf /tmp/*acme* /tmp/*letsencrypt* 2>/dev/null || true
    rm -rf /var/tmp/*acme* /var/tmp/*letsencrypt* 2>/dev/null || true
    find /var -name "*acme*" -exec rm -rf {} + 2>/dev/null || true
    find /run -name "*acme*" -exec rm -rf {} + 2>/dev/null || true
    log_success "深度清理完成"

    # 验证清理结果
    echo -e "${YELLOW}验证清理结果:${NC}"

    systemctl is-active --quiet nginx 2>/dev/null && log_warning "Nginx服务仍在运行" || log_success "Nginx服务已停止"
    netstat -tlnp 2>/dev/null | grep -q ":80\|:443" && log_warning "端口80/443仍被占用" || log_success "端口80/443已释放"

    for cmd in nginx acme.sh; do
        command -v "$cmd" >/dev/null 2>&1 && log_warning "$cmd命令仍存在" || log_success "$cmd已完全卸载"
    done

    for dir in "/etc/nginx" "/root/.acme.sh"; do
        [[ -d "$dir" ]] && log_warning "目录仍存在: $dir"
    done

    crontab -l 2>/dev/null | grep -E "(acme\.sh|letsencrypt)" >/dev/null && log_warning "定时任务中仍有相关内容" || log_success "定时任务已清理"

    source ~/.bashrc && source ~/.profile
    echo
    log_success "SSL服务和工具完全卸载完成！"
}

################################ 转快速启动 ################################
quick() {
    spin  "开始转快速启动..."
    wget -q -O /usr/bin/ng https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/nginx.sh 2>/dev/null && chmod +x /usr/bin/ng
    stopspin
    log_success "已完成脚本转快速启动"    
    echo "=================================================================="
    echo -e "\t\t Nginx 脚本转快速启动 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo -e "欢迎使用转快速启动脚本，脚本运行完成后在shell界面输入${YELLOW}ng${NC}即可调用脚本"
    echo "=================================================================="
}

################################# DDNS 安装 ################################
setup_ddns() {
    [[ "$1" != "noclear" ]] && clear

    echo "请选择DDNS类型:"
    echo "1) 单独 DDNS IPv4 地址"
    echo "2) 单独 DDNS IPv6 地址"  
    echo "3) DDNS IPv4 + IPv6地址 [默认选项]"    
    while true; do
        read -p "请输入选项 (1-3): " choice
        choice=${choice:-3} 
        case $choice in
            1)
                ddns_type="ddnsv4"
                echo "已选择: 单独DDNSv4地址"
                break
                ;;
            2)
                ddns_type="ddnsv6"
                echo "已选择: 单独DDNSv6地址"
                break
                ;;
            3)
                ddns_type="ddnsall"
                echo "已选择: DDNSv4+v6地址"
                break
                ;;
            *)
                echo "无效选项，请重新输入!"
                ;;
        esac
    done
       
    # IPv6检测
    if [ "$ddns_type" = "ddnsv6" ] || [ "$ddns_type" = "ddnsall" ]; then
        spin "正在检测IPv6支持..."       
        # 检查系统是否支持IPv6
        if [ ! -f /proc/net/if_inet6 ]; then
            stopspin
            log_error "系统不支持IPv6"
            red "由于IPv6不可用，请重新选择DDNS类型"
            setup_ddns noclear 
            return
        fi
        
        # 检查是否有IPv6地址
        ipv6_addr=$(ip -6 addr show scope global | grep inet6 | head -1 | awk '{print $2}' | cut -d'/' -f1)
        if [ -z "$ipv6_addr" ]; then
            stopspin
            log_error "系统没有可用的IPv6地址"
            red "由于IPv6不可用，请重新选择DDNS类型"
            setup_ddns noclear
            return
        fi
        stopspin
        log_success "IPv6检测通过!"
    fi
    
    while true; do
        read -p "请输入DDNS的一级域名 (格式: example.com): " primary_domain
        if [[ $primary_domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.([a-zA-Z]{2,}|[a-zA-Z]{2,}\.[a-zA-Z]{2,})$ ]] && [[ $(echo "$primary_domain" | tr '.' '\n' | wc -l) -eq 2 ]]; then
            echo "一级域名格式正确: $primary_domain"
            break
        else
            echo "错误: 一级域名格式不正确，请输入格式如 'example.com' 的二级域名"
        fi
    done
    
    if [ "$ddns_type" = "ddnsv4" ]; then
        while true; do
            read -p "请输入DDNS的完整v4域名 (格式: ipv4.example.com 或 *.example.com): " v4_domain
            if [[ $v4_domain =~ ^(\*\.)?[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]] && [[ $(echo "$v4_domain" | tr '.' '\n' | wc -l) -ge 3 ]]; then
                break
            else
                echo "错误: 域名格式不正确，请输入至少三级域名格式，如 'ipv4.example.com' 或 '*.example.com'"
            fi
        done
    elif [ "$ddns_type" = "ddnsv6" ]; then
        while true; do
            read -p "请输入DDNS的完整v6域名 (格式: ipv6.example.com 或 *.example.com): " v6_domain
            if [[ $v6_domain =~ ^(\*\.)?[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]] && [[ $(echo "$v6_domain" | tr '.' '\n' | wc -l) -ge 3 ]]; then
                break
            else
                echo "错误: 域名格式不正确，请输入至少三级域名格式，如 'ipv6.example.com' 或 '*.example.com'"
            fi
        done
    elif [ "$ddns_type" = "ddnsall" ]; then
        while true; do
            read -p "请输入DDNS的完整v4域名 (格式: ipv4.example.com 或 *.example.com): " v4_domain
            if [[ $v4_domain =~ ^(\*\.)?[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]] && [[ $(echo "$v4_domain" | tr '.' '\n' | wc -l) -ge 3 ]]; then
                break
            else
                echo "错误: 域名格式不正确，请输入至少三级域名格式，如 'ipv4.example.com' 或 '*.example.com'"
            fi
        done
        while true; do
            read -p "请输入DDNS的完整v6域名 (格式: ipv6.example.com 或 *.example.com): " v6_domain
            if [[ $v6_domain =~ ^(\*\.)?[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]] && [[ $(echo "$v6_domain" | tr '.' '\n' | wc -l) -ge 3 ]]; then
                break
            else
                echo "错误: 域名格式不正确，请输入至少三级域名格式，如 'ipv6.example.com' 或 '*.example.com'"
            fi
        done
    fi
    
    read -p "请输入Cloudflare API Token: " cf_token
    
    log_info "正在检查ddclient安装状态..."
    
    if ! command -v ddclient &> /dev/null; then
            spin "ddclient未安装，正在安装..."
        
        apt-get install -y -qq ddclient > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            stopspin
            log_success "ddclient安装完成"
            ddclient_install_status=new
        else
            stopspin
            log_error "ddclient安装失败"
            exit 1
        fi

    else
        log_info "ddclient已安装"
        ddclient_install_status=old
        systemctl stop ddclient
    fi
    
    log_info "正在生成配置文件..."
    rm -rf /etc/ddclient.conf
    wget --quiet --show-progress -O /etc/ddclient.conf https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/nginx/$ddns_type.conf
    
    if [ ! -f "/etc/ddclient.conf" ]; then
        red "错误：配置文件 /etc/ddclient.conf 不存在"
        red "请检查网络可正常访问github后运行脚本"
        rm -rf /mnt/nginx.sh    #delete
        exit 1
    fi
    sed -i "s|host.com|${primary_domain}|g" /etc/ddclient.conf
    sed -i "s|111222333|${cf_token}|g" /etc/ddclient.conf  

    if [ "$ddns_type" = "ddnsv4" ]; then
        sed -i "s|xx.next.top|${v4_domain}|g" /etc/ddclient.conf
    elif [ "$ddns_type" = "ddnsv6" ]; then
        sed -i "s|xx.next.top|${v6_domain}|g" /etc/ddclient.conf      
    elif [ "$ddns_type" = "ddnsall" ]; then
        sed -i "s|xx4.next4.top|${v4_domain}|g" /etc/ddclient.conf        
        sed -i "s|xx6.next6.top|${v6_domain}|g" /etc/ddclient.conf
    fi
    log_success "配置文件生成完成"

    chmod 600 /etc/ddclient.conf
    
    if [ "$ddns_type" = "new" ]; then
        systemctl enable ddclient --now
    else
        rm -f /var/cache/ddclient/ddclient.cache && rm -f /tmp/ddclient.cache && rm -f /var/lib/ddclient/ddclient.cache
        systemctl restart ddclient
    fi

    log_success "脚本执行完成..."  

    echo "=================================================================="
    echo -e "\t\t DDNS 安装完成 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo -e "配置文件目录：\n${YELLOW}/etc/ddclient.conf${NC}"
    echo -e "脚本已运行完毕，后续每5分钟检查一次IP变动，${YELLOW}请关注CF域名DNS解析\n是否变动${NC}"
    echo "=================================================================="

}
################################# DDNS 卸载 ################################
del_ddns() {
    spin "正在删除ddclient..."
    # 检查是否安装了ddclient
    if ! dpkg -l | grep -q ddclient; then
        log_error "${RED}ddclient未安装，无需删除${NC}"
        exit 0
    fi

    # 停止ddclient服务（如果正在运行）
    if systemctl is-active --quiet ddclient 2>/dev/null; then
        systemctl stop ddclient >/dev/null 2>&1
    elif service ddclient status >/dev/null 2>&1; then
        service ddclient stop >/dev/null 2>&1
    fi

    # 禁用开机自启动
    if systemctl list-unit-files | grep -q ddclient; then
        sudo systemctl disable ddclient >/dev/null 2>&1
    fi

    # 删除ddclient包和配置文件
    apt-get purge -y ddclient >/dev/null 2>&1

    # 清理依赖包
    apt-get autoremove -y >/dev/null 2>&1

    # 更新包缓存
    apt-get autoclean >/dev/null 2>&1
    stopspin
    # 验证删除结果
    if ! command -v ddclient >/dev/null 2>&1; then
        log_success "ddclient已成功删除"
    else
        log_error "ddclient可能未完全删除"
    fi
}
################################# 说明页 ################################
one_page() {
    while true; do
        clear
        white "$yellow 欢迎使用 Nginx 相关脚本，请先阅读以下说明：$reset"
        white "$yellow 1. 本脚本支持安装acme并申请证书，安装nginx并配置相关服务，证书到期\n    前自动续期。$reset"
        white "$yellow 2. 本脚本仅支持域名解析放在Cloudflare解析的域名。$reset"
        white "$yellow 3. 如未做好CF域名解析，请先做好域名解析并保证可ping通状态。$reset" 
        white "$yellow 4. 提前获取Cloudflare API Token（非全局）、Cloudflare Account ID、\n    Cloudflare Zone ID 。$reset"
        white "$yellow    获取方法：$reset"    
        white "$yellow      ◇  Cloudflare API Token（非全局）：右上点账户，点配置文件，左边API\n         令牌申请。$reset"  
        white "$yellow      ◇  Cloudflare Account ID：申请Cloudflare所用的邮箱。$reset"  
        white "$yellow      ◇  Cloudflare Zone ID：点击域名，概述页右边最下找区域ID$reset"  
        white "$yellow 5. Nginx 配置已优化，http访问自动跳转https。$reset"
        echo -e "是否继续执行脚本？ [Y/n]: "
        read -r response
        if [[ -z "$response" || "$response" =~ ^[Yy] ]]; then
            break
        elif [[ "$response" =~ ^[Nn] ]]; then
            echo -e "${RED}脚本已取消执行${reset}"
            exit 0
        fi
    done
}

################################# CF变量选择 ################################
cf_choose() {
    # 只有在没有参数或参数不是"noclear"时才执行clear
    [[ "$1" != "noclear" ]] && clear

    echo "=================================================================="
    echo -e "\t\tCloudflare 变量管理 by 忧郁滴飞叶"
    echo -e "\t\n"
    echo "欢迎使用 Cloudflare 变量管理脚本"
    echo -e "${YELLOW}注意：变量仅在本次开机过程中有效，重启后需重新输入${NC}"    
    echo "请选择要执行的服务："
    echo "=================================================================="
    echo "1. 设置/更新 Cloudflare 变量"
    echo "2. 显示当前变量"
    echo "3. 清除临时变量"
    echo -e "\t"
    echo "-. 返回 Nginx 菜单"      
    echo "0) 退出脚本"
    read -p "请选择服务: " cf_config_choice
    case $cf_config_choice in
        1)
            function_set_variables
            cf_choose noclear 
            ;;
        2)
            function_show_variables
            cf_choose noclear
            ;;              
        3)
            function_clear_variables
            cf_choose noclear
            ;;
        0)
            red "退出脚本，感谢使用."
            rm -rf /mnt/nginx.sh     #delete      
            ;;
        -)
            white "脚本切换中，请等待..."
            nginx_choose
            ;;
        *)
            white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            cf_choose
            ;;    
    esac
}

################################# nginx选择 ################################
nginx_choose() {
    #设置CF缓存文件路径及自动加载
    CF_CONFIG_TMP_FILE="/tmp/.acme_cf_config"
    if [[ -s "$CF_CONFIG_TMP_FILE" ]]; then
        source "$CF_CONFIG_TMP_FILE"
    fi

    # 检查ACME状态
    if command -v acme.sh >/dev/null 2>&1; then
        # acme.sh已安装，检查是否有相关进程在运行
        if pgrep -f "acme.sh" >/dev/null 2>&1; then
            ACME_STATUS="${GREEN}运行中${NC}"
        else
            ACME_STATUS="未运行"
        fi
    elif [ -f ~/.acme.sh/acme.sh ]; then
        # 检查默认安装路径
        if pgrep -f "acme.sh" >/dev/null 2>&1; then
            ACME_STATUS="${GREEN}运行中${NC}"
        else
            ACME_STATUS="${YELLOW}未运行${NC}"
        fi
    else
        ACME_STATUS="${RED}未安装${NC}"
    fi

    # 检查NGINX状态
    if command -v nginx >/dev/null 2>&1; then
        if systemctl is-active --quiet nginx 2>/dev/null; then
            NGINX_STATUS="${GREEN}运行中${NC}"
        elif service nginx status >/dev/null 2>&1; then
            NGINX_STATUS="${GREEN}运行中${NC}"
        elif pgrep nginx >/dev/null 2>&1; then
            NGINX_STATUS="${GREEN}运行中${NC}"
        else
            NGINX_STATUS="${YELLOW}未运行${NC}"
        fi
    else
        NGINX_STATUS="${RED}未安装${NC}"
    fi

    # 检查DDCLIENT状态
    if command -v ddclient >/dev/null 2>&1; then
        if systemctl is-active --quiet ddclient 2>/dev/null; then
            DDCLIENT_STATUS="${GREEN}运行中${NC}"
        elif service ddclient status >/dev/null 2>&1; then
            DDCLIENT_STATUS="${GREEN}运行中${NC}"
        elif pgrep -x ddclient >/dev/null 2>&1; then
            DDCLIENT_STATUS="${GREEN}运行中${NC}"
        else
            DDCLIENT_STATUS="${YELLOW}未运行${NC}"
        fi
    else
        DDCLIENT_STATUS="${RED}未安装${NC}"
    fi

    # 检查Acme变量
    if [ -n "$CF_TOKEN" ]; then
        CF_TOKEN_SHOW="${GREEN}已设置${NC}"
    else
        CF_TOKEN_SHOW="${RED}未设置${NC}"
    fi
    if [ -n "$CF_ACCOUNT_ID" ]; then
        CF_ACCOUNT_ID_SHOW="${GREEN}已设置${NC}"
    else
        CF_ACCOUNT_ID_SHOW="${RED}未设置${NC}"
    fi
    if [ -n "$CF_ZONE_ID" ]; then
        CF_ZONE_ID_SHOW="${GREEN}已设置${NC}"
    else
        CF_ZONE_ID_SHOW="${RED}未设置${NC}"
    fi    
    clear
    echo "=================================================================="
    echo -e "\t\tNginx 相关脚本 by 忧郁滴飞叶"
    # echo -e "\t\n"
    echo "欢迎使用 Nginx 相关脚本，建议安装环境ubuntu25.04"
    echo -e "CF变量状态："
    echo -e "账号：$CF_ZONE_ID_SHOW  Token：$CF_TOKEN_SHOW  域名ID：$CF_ZONE_ID_SHOW"
    echo -e "程序状态："    
    echo -e "ACME ：$ACME_STATUS  Nginx ：$NGINX_STATUS  ddclinet：$DDCLIENT_STATUS"
    echo "请选择要执行的服务："
    echo "=================================================================="
    echo "1. Cloudflares 申请证书变量管理"
    white "2. 新增Acme证书及Nginx配置 $yellow[带安装程序]$reset"
    echo "3. 新增Acme证书及Nginx配置"
    echo "4. Nginx 配置校验及重载"
    echo "5. 删除已申请/安装的 SSL 证书及相关 Nginx 配置"
    echo "6. 彻底卸载 Acem、Nginx 并清理配置文件"
    echo "7. 安装 ddclient 执行 DDNS"
    echo "8. 重载 ddclient配置" 
    echo "9. 卸载 ddclient"  
    # echo -e "\t"
    echo "@. 本脚本转快速启动"          
    echo "-. 返回上级菜单"
    echo "0) 退出脚本"
    read -p "请选择服务: " choice
    choice=${choice:-3}
    case $choice in
        2)
            white "新增Acme证书及Nginx配置 [带安装程序]..."
            custom_nginx_settings
            basic_settings
            install_acme_service
            install_nginx_service
            install_nginx_config
            over_install_config
            ;;
        3)
            if [ "$ACME_STATUS" = "${RED}未安装${NC}" ] || [ "$NGINX_STATUS" = "${RED}未安装${NC}" ]; then
                log_warning "检测到以下服务未安装："
                [ "$ACME_STATUS" = "${RED}未安装${NC}" ] && echo -e "- ACME: $ACME_STATUS"
                [ "$NGINX_STATUS" = "${RED}未安装${NC}" ] && echo -e "- Nginx: $NGINX_STATUS"
                white "请选择2. 新增Acme证书及Nginx配置 $yellow[带安装程序]${reset}程序操作"
                while true; do
                    white "是否返回脚本主程序？ [Y/n]: "
                    read -r response
                    if [[ -z "$response" || "$response" =~ ^[Yy]$ ]]; then
                        nginx_choose
                        break
                    elif [[ "$response" =~ ^[Nn]$ ]]; then
                        red "退出脚本"
                        exit 0
                    else
                        red "输入错误，请输入 Y/y 继续或 N/n 退出"
                    fi
                done
            else
                white "仅新增Acme证书及Nginx配置..."
                custom_nginx_settings
                install_acme_service
                install_nginx_config
                over_install_config
            fi
            ;;               
        1)
            cf_choose
            ;;
        5)
            uninstall_sslcert
            ;;              
        6)
            uninstall_all
            ;;
        4)
            spin "正在检查 Nginx 配置..."
            if ! nginx -t 2>&1 | grep -q "test is successful"; then
                stopspin
                log_error "Nginx 配置测试失败...请修正配置"               
                exit 1
            else
                systemctl reload nginx
                stopspin
                log_success "Nginx 配置测试通过...配置已重载" 
            fi
            ;;
        7)    
            setup_ddns
            ;;
        8)  
            log_info "正在重载ddclient配置..."
            systemctl stop ddclient
            sleep 1
            rm -f /var/cache/ddclient/ddclient.cache && rm -f /tmp/ddclient.cache && rm -f /var/lib/ddclient/ddclient.cache
            systemctl start ddclient
            log_success "配置重载已完成"
            systemctl status ddclient
            ;;
        9)    
            del_ddns
            ;;                        
        @)
            quick
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
            nginx_choose
            ;;
    esac
}
################################ 结束通知 ################################
over_install_config() {
    [ -f /mnt/nginx.sh ] && rm -rf /mnt/nginx.sh     #delete
    echo "=================================================================="
    echo -e "\t\t\tNginx 配置添加完毕"
    echo -e "\n"
    echo -e "HTTP 监听端口为${yellow}80${reset}"
    echo -e "HTTPS 监听端口为${yellow}${NGINX_LISTEN_PORT}${reset}"
    echo -e "Nginx 运行目录为${yellow}${nginx_conf_dir}${reset}"
    echo -e "证书路径为路径为: \n Cert：${yellow}${cert_file}${reset}\n Key：${yellow}${key_file}${reset}"
    echo -e "请自行操作在路由安排${yellow}HTTP${NC}或${yellow}HTTPS${NC}端口转发"    
    echo -e "温馨提示:\n本脚本仅在ubuntu25.04环境下测试，其他环境未经验证 "
    echo "=================================================================="
    while true; do
        white "是否返回脚本主程序？ [Y/n]: "
        read -r response
        if [[ -z "$response" || "$response" =~ ^[Yy]$ ]]; then
            nginx_choose
            break
        elif [[ "$response" =~ ^[Nn]$ ]]; then
            red "退出脚本"
            exit 0
        else
            red "输入错误，请输入 Y/y 继续或 N/n 退出"
        fi
    done
}
################################# 主程序 ################################
one_page
nginx_choose