#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
export APT_LISTCHANGES_FRONTEND=none

clear
[ -f /mnt/main_install.sh ] && rm -rf /mnt/main_install.sh
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

################################ 基础环境设置 ################################
basic_settings() {
    white "配置基础设置并安装依赖..."
    sleep 1
    apt-get update -y && apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || { red "环境更新失败！退出脚本"; exit 1; }
    green "环境更新成功"
    white "环境依赖安装开始..."
    apt install wget curl vim jq -y || { red "依赖安装失败！退出脚本"; exit 1; }
    green "依赖安装成功"
    timedatectl set-timezone Asia/Shanghai || { red "时区设置失败！退出脚本"; exit 1; }
}
################################ docker安装 ################################
docker_install() {
    white "开始安装docker..." 
    wget -qO- get.docker.com | bash
    systemctl enable docker --now
    if ! systemctl is-active --quiet docker; then
        red "docker安装失败！退出脚本."
        [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete     
        exit 1
    fi
}
docker_install_over() {    
    systemctl restart docker
    [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete       
    echo "=================================================================="
    echo -e "\t\tDocker 安装完成"
    echo -e "\n"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，已查\n询程序运行状态，如出现\e[1m\e[32m active (running)\e[0m，程序已启动成功。"
    echo "=================================================================="
    systemctl status docker
}
################################ docker卸载 ################################
del_docker() {
    white "开始卸载docker..."     
    systemctl stop docker
    systemctl stop docker.socket
    apt-get purge -y docker-ce docker-ce-cli containerd.io
    apt-get autoremove -y --purge docker-ce docker-ce-cli containerd.io
    rm -rf /var/lib/docker
    rm -rf /var/lib/containerd
    rm /etc/docker/daemon.json
    rm /etc/docker/daemon.json.bak
    rm /etc/systemd/system/docker.service
    rm /etc/systemd/system/docker.socket
    rm /lib/systemd/system/docker.service
    rm /lib/systemd/system/docker.socket
    systemctl daemon-reload
    systemctl reset-failed
    if ! which docker > /dev/null; then
        green "docker卸载成功"
    else
        red "Docker 卸载失败，请检查剩余的 Docker 组件"
        [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete    
        exit 1
    fi
        systemctl daemon-reload
    [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete          
}
################################ docker-compose安装 ################################
docker_compose_install() {
    white "开始安装docker-compose..."
    # Compose_Version=$(curl -s https://github.com/docker/compose/releases | grep '/releases/tag/v' | head -n 1 | awk -F'/releases/tag/' '{print $2}' | awk -F'"' '{print $1}')
    # curl -L "https://github.com/docker/compose/releases/download/${Compose_Version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    curl -L "https://github.com/docker/compose/releases/download/v2.29.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    if docker-compose --version | grep -q '^Docker Compose version v[0-9]\+\.[0-9]\+\.[0-9]\+$'; then
        docker-compose --version
    else
        red "docker-compose安装失败！退出脚本"
        [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete     
        exit 1
    fi
}    
docker_compose_install_over() {    
    [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete       
    echo "=================================================================="
    echo -e "\t\tDocker-Compose 安装完成"
    echo -e "\n"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证"
    echo "=================================================================="
    systemctl restart docker
}
################################ docker-compose卸载 ################################
del_docker_compose() {
    white "开始卸载docker-compose..."     
    rm -rf /usr/local/bin/docker-compose
    [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete          
    gereen "docker-compose卸载成功"
}
################################ 设定docker日志文件大小 ################################
docker_log_setting() {
    if ! command -v jq &> /dev/null; then
        white "部分依赖未安装，安装依赖..."
        apt install jq -y
    fi
    # 读取用户输入的日志文件最大大小
    while true; do
        read -p "请输入日志文件的最大大小（单位m，例如：20、50等，默认20）： " LOG_SIZE
        LOG_SIZE="${LOG_SIZE:-20}"
        if [[ $LOG_SIZE =~ ^[0-9]+$ ]]; then
            break
        else
            echo -e "\e[31m日志文件的大小格式输入不正确，请重新输入\e[0m"
        fi
    done
    TMP_FILE=$(mktemp)
cat > $TMP_FILE <<EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "${LOG_SIZE}m",
        "max-file": "3"
    }
}
EOF
    # 备份现有的 daemon.json
    if [ ! -d /etc/docker ]; then
        white "/etc/docker 文件夹不存在，正在创建..."
        mkdir -p /etc/docker
    else
        white "开始添加配置..."
    fi
    if [ -f /etc/docker/daemon.json ]; then
        sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
    else
        echo "{}" | sudo tee /etc/docker/daemon.json > /dev/null
    fi
    if [ ! -s /etc/docker/daemon.json ]; then
        echo "{}" | sudo tee /etc/docker/daemon.json > /dev/null
    fi
    white "正在合并配置..."
    MERGED_FILE=$(mktemp)
    jq -s 'add' /etc/docker/daemon.json $TMP_FILE | sudo tee $MERGED_FILE > /dev/null
    if [ $? -ne 0 ]; then
        red "合并时发生错误，请检查 JSON 格式是否正确。"
        sudo cp /etc/docker/daemon.json.bak /etc/docker/daemon.json
        [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete    
        exit 1
    fi    
    sudo mv $MERGED_FILE /etc/docker/daemon.json
    rm $TMP_FILE
    chmod 644 /etc/docker/daemon.json
    systemctl daemon-reload
    systemctl restart docker
    [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete          
    echo "=================================================================="
    echo -e "\t\t设定docker日志文件大小 已完成"
    echo -e "\n"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证\nDocker 日志设置已更新，最大日志文件大小为${yellow}${LOG_SIZE}m${reset}\n已在${yellow}/etc/docker${reset}目录下生成备份${yellow}daemon.json.bak${reset}\n如出现问题，请自行恢复"
    echo "=================================================================="
}
################### 一键安装docker、docker-compose及设定docker日志文件大小 ######################
docker_install_compose_install_log_setting() {

    while true; do
        read -p "请输入日志文件的最大大小（单位m，例如：20、50等，默认20）： " LOG_SIZE
        LOG_SIZE="${LOG_SIZE:-20}"
        if [[ $LOG_SIZE =~ ^[0-9]+$ ]]; then
            break
        else
            echo -e "\e[31m日志文件的大小格式输入不正确，请重新输入\e[0m"
        fi
    done
    TMP_FILE=$(mktemp)

    # 读取用户输入的日志文件最大大小
    basic_settings
    docker_install
    docker_compose_install    
    if ! command -v jq &> /dev/null; then
        white "jq工具未安装，安装依赖..."
        apt install jq -y
    fi
cat > $TMP_FILE <<EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "${LOG_SIZE}m",
        "max-file": "3"
    }
}
EOF
    # 备份现有的 daemon.json
    if [ ! -d /etc/docker ]; then
        white "/etc/docker 文件夹不存在，正在创建..."
        mkdir -p /etc/docker
    else
        white "开始添加配置..."
    fi
    if [ -f /etc/docker/daemon.json ]; then
        sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
    else
        echo "{}" | sudo tee /etc/docker/daemon.json > /dev/null
    fi
    if [ ! -s /etc/docker/daemon.json ]; then
        echo "{}" | sudo tee /etc/docker/daemon.json > /dev/null
    fi
    white "正在合并配置..."
    MERGED_FILE=$(mktemp)
    jq -s 'add' /etc/docker/daemon.json $TMP_FILE | sudo tee $MERGED_FILE > /dev/null
    if [ $? -ne 0 ]; then
        red "合并时发生错误，请检查 JSON 格式是否正确。"
        sudo cp /etc/docker/daemon.json.bak /etc/docker/daemon.json
        [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete    
        exit 1
    fi    
    sudo mv $MERGED_FILE /etc/docker/daemon.json
    rm $TMP_FILE
    chmod 644 /etc/docker/daemon.json
    systemctl daemon-reload
    systemctl restart docker
    [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete  
    echo "=================================================================="
    echo -e "\t一键安装docker、docker-compose及设定docker日志文件大小 配置完成"
    echo -e "\n"
    echo -e "docker版本："
    docker -v
    echo -e "docker-compose版本："
    docker-compose --version
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证\nDocker 日志设置已更新，最大日志文件大小为${yellow}${LOG_SIZE}m${reset}\n已在${yellow}/etc/docker${reset}目录下生成备份${yellow}daemon.json.bak${reset}\n如出现问题，请自行恢复"
    echo "=================================================================="
}
################################ 开启docker IPV6 ################################
docker_IPV6() {
    if ! command -v jq &> /dev/null; then
        white "部分依赖未安装，安装依赖..."
        apt install jq -y
    fi
    TMP_FILE=$(mktemp)
cat > $TMP_FILE <<EOF
{
    "ipv6": true,
    "fixed-cidr-v6": "fd00:dead:beef:c0::/80",
    "experimental": true,
    "ip6tables": true
}
EOF
    if [ ! -d /etc/docker ]; then
        white "/etc/docker 文件夹不存在，正在创建..."
        mkdir -p /etc/docker
    else
        white "开始添加配置..."
    fi
    if [ -f /etc/docker/daemon.json ]; then
        sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
    else
        echo "{}" | sudo tee /etc/docker/daemon.json > /dev/null
    fi
    if [ ! -s /etc/docker/daemon.json ]; then
        echo "{}" | sudo tee /etc/docker/daemon.json > /dev/null
    fi
    white "正在合并配置..."
    MERGED_FILE=$(mktemp)
    jq -s 'add' /etc/docker/daemon.json $TMP_FILE | sudo tee $MERGED_FILE > /dev/null
    if [ $? -ne 0 ]; then
        red "合并时发生错误，请检查 JSON 格式是否正确。"
        sudo cp /etc/docker/daemon.json.bak /etc/docker/daemon.json
        [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete    
        exit 1
    fi
    sudo mv $MERGED_FILE /etc/docker/daemon.json
    rm $TMP_FILE
    chmod 644 /etc/docker/daemon.json
    systemctl daemon-reload
    systemctl restart docker
    [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete          
    echo "=================================================================="
    echo -e "\t\tDocker IPv6 设置 已完成"
    echo -e "\n"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证\n已在${yellow}/etc/docker${reset}目录下生成备份${yellow}daemon.json.bak${reset}\n如出现问题，请自行恢复"
    echo "=================================================================="    
}
################################ 开启docker API ################################
docker_api() {
    white "开始配置开启2375端口..."
    cp /usr/lib/systemd/system/docker.service /usr/lib/systemd/system/docker.service.bak
    sed -i 's|-H fd://|-H tcp://0.0.0.0:2375 -H fd://|g' /usr/lib/systemd/system/docker.service
    chmod 644 /etc/docker/daemon.json
    systemctl daemon-reload
    systemctl restart docker
    [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete          
    green "Docker API 2375端口已开启"
    echo "=================================================================="
    echo -e "\t\t开启docker API 2375端口 已完成"
    echo -e "\n"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证\n已在${yellow}/usr/lib/systemd/system${reset}目录下生成备份${yellow}docker.service.bak${reset}\n如出现问题，请自行恢复"
    echo "=================================================================="   
}
################################ 端口占用查询 ################################
port_check_for_docker() {
    if ! command -v netstat &> /dev/null; then
    apt-get install -y net-tools >/dev/null 2>&1
    fi

    white "开始查询docker占用端口..."
    ports_info=$(netstat -tulnp | awk 'NR>2 {print $4,$7}' | sed 's/:::/0.0.0.0:/; s/.*://')

    declare -A port_program_map

    while read -r port pid_prog; do
    pid=$(echo $pid_prog | cut -d'/' -f1)
    prog=$(echo $pid_prog | cut -d'/' -f2-)
    port_program_map["$port"]="$pid/$prog"
    done <<< "$ports_info"

    # 查找Docker容器和对应的端口
    docker_ports_info=$(docker ps --format "{{.ID}} {{.Names}} {{.Ports}}" | grep '0.0.0.0:' | sed 's/->.*//g')

    declare -A port_container_map

    while read -r container_id container_name ports; do
    for port in $(echo "$ports" | tr ',' '\n'); do
        port_number=$(echo "$port" | awk -F':' '{print $2}')
        if [[ -n "$port_number" ]]; then
        port_container_map["$port_number"]+="$container_name "
        fi
    done
    done <<< "$docker_ports_info"

    # 输出结果
    for port in "${!port_program_map[@]}"; do
    pid_prog="${port_program_map[$port]}"
    container_info="${port_container_map[$port]:-无}"
    echo "端口 $port 被程序 $pid_prog 占用，容器信息: $container_info"
    done | sort -n
}
################################ 转快速启动 ################################
quick_docker() {
    echo "=================================================================="
    echo -e "\t\t docker脚本转快速启动 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo -e "欢迎使用docker脚本转快速启动脚本，脚本运行完成后在shell界面输入docker即可调用脚本"
    echo "=================================================================="
    white "开始转快速启动..."
    wget -O /usr/bin/docker-menu https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/docker.sh 
    chmod +x /usr/bin/docker-menu
    green "docker脚本转快捷启动已完成，shell界面输入docker即可调用脚本"
}

################################ docker 选择 ################################
docker_choose() {
    clear
    rm -rf /mnt/main_install.sh
    echo "=================================================================="
    echo -e "\t\tDocker综合脚本 by 忧郁滴飞叶"
    echo -e "\t\n"
    echo "请选择服务："
    echo "=================================================================="
    echo "1. 安装docker"
    echo "2. 安装docker-compose"
    echo "3. 设定docker日志文件大小"
    echo "4. 一键安装docker、docker-compose及设定docker日志文件大小"
    echo "5. 开启docker IPV6"
    echo "6. 开启docker API - 2375端口"
    echo "7. 卸载docker"
    echo "8. 卸载docker-compose"
    echo "9. 端口占用查询"    
    echo -e "\t"
    echo "=. 当前脚本转快速启动"    
    echo "-. 返回上级菜单"    
    echo "0. 退出脚本"
    read -p "请选择服务: " choice
    case $choice in
        1)
            basic_settings
            docker_install
            docker_install_over
            ;;
        2)
            docker_compose_install
            docker_compose_install_over
            ;;
        3)
            docker_log_setting
            ;;
        4)
            docker_install_compose_install_log_setting
            ;;            
        5)
            docker_IPV6
            ;;
        6)
            docker_api
            ;;            
        7)
            del_docker
            ;;            
        8)
            del_docker_compose           
            ;;   
        9)
            port_check_for_docker           
            ;; 
        =)
            quick_docker           
            ;;             
        0)
            red "退出脚本，感谢使用."
            [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete 
            ;;
        -)
            white "脚本切换中，请等待..."
            [ -f /mnt/docker.sh ] && rm -rf /mnt/docker.sh    #delete 
            wget -q -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
            ;;
        *)
            white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            docker_choose
            ;;
    esac 
}
################################ 主程序 ################################
docker_choose