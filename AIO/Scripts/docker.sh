#!/bin/bash

clear
rm -rf /mnt/main_install.sh

################################ IP 选择 ################################
docker_choose() {
    clear
    rm -rf /mnt/main_install.sh
    echo "=================================================================="
    echo -e "\t\tDocker综合脚本 by 忧郁滴飞叶"
    echo -e "\t\n"
    echo "请选择要设备的网络环境："
    echo "=================================================================="
    echo "1. 安装docker"
    echo "2. 安装docker-compose"
    echo "3. 设定docker日志文件大小"
    echo "4. 开启docker IPV6"
    echo "5. 开启docker API - 2375端口"
    echo "6. 卸载docker"
    echo "7. 卸载docker-compose"    
    echo -e "\t"
    echo "-. 返回上级菜单"    
    echo "0. 退出脚本"
    read -p "输入选项： " choice
    case $choice in
        1)
            basic_settings
            docker_install
            ;;
        2)
            docker_compose_install
            ;;
        3)
            docker_log_setting
            ;;
        4)
            docker_IPV6
            ;;
        5)
            docker_api
            ;;            
        6)
            del_docker
            ;;            
        7)
            del_docker_compose           
            ;;   
        0)
            echo -e "\e[31m退出脚本，感谢使用.\e[0m"
            rm -rf /mnt/docker.sh    #delete         
            ;;
        -)
            echo "脚本切换中，请等待..."
            rm -rf /mnt/docker.sh    #delete
            wget -q -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
            ;;
        *)
            echo "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            /mnt/docker.sh
            ;;
    esac 
}
################################ 基础环境设置 ################################
basic_settings() {
    echo -e "配置基础设置并安装依赖..."
    sleep 1
    apt update -y || { echo "\n\e[1m\e[37m\e[41m环境更新失败！退出脚本\e[0m\n"; exit 1; }
    apt -y upgrade || { echo "\n\e[1m\e[37m\e[41m环境更新失败！退出脚本\e[0m\n"; exit 1; }
    echo -e "\n\e[1m\e[37m\e[42m环境更新成功\e[0m\n"
    echo -e "环境依赖安装开始..."
    apt install wget curl vim jq -y || { echo -e "\n\e[1m\e[37m\e[41m环境依赖安装失败！退出脚本\e[0m\n"; exit 1; }
    echo -e "\n\e[1m\e[37m\e[42m依赖安装成功\e[0m\n"
    timedatectl set-timezone Asia/Shanghai || { echo -e "\n\e[1m\e[37m\e[41m时区设置失败！退出脚本\e[0m\n"; exit 1; }
}
################################ docker安装 ################################
docker_install() {
    echo -e "开始安装docker..." 
    wget -qO- get.docker.com | bash
    systemctl enable docker --now
    if ! systemctl is-active --quiet docker; then
    echo -e "\n\e[1m\e[37m\e[41mdocker安装失败！退出脚本\e[0m\n"
    rm -rf /mnt/docker.sh    #delete    
    exit 1
    fi
    systemctl restart docker
    rm -rf /mnt/docker.sh    #delete      
    echo "=================================================================="
    echo -e "\t\tDocker 安装完成"
    echo -e "\n"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，已查\n询程序运行状态，如出现\e[1m\e[32m active (running)\e[0m，程序已启动成功。"
    echo "=================================================================="
    systemctl status docker
}
################################ docker卸载 ################################
del_docker() {
    echo -e "开始卸载docker..."     
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
        echo -e "\n\e[1m\e[37m\e[42mdocker卸载成功\e[0m\n"
    else
        echo -e "\n\e[1m\e[37m\e[41mDocker 卸载失败，请检查剩余的 Docker 组件\e[0m\n"
        rm -rf /mnt/docker.sh    #delete   
        exit 1
    fi
        systemctl daemon-reload
    rm -rf /mnt/docker.sh    #delete         
}
################################ docker-compose安装 ################################
docker_compose_install() {
    echo -e "开始安装docker-compose..."
    # Compose_Version=$(curl -s https://github.com/docker/compose/releases | grep '/releases/tag/v' | head -n 1 | awk -F'/releases/tag/' '{print $2}' | awk -F'"' '{print $1}')
    # curl -L "https://github.com/docker/compose/releases/download/${Compose_Version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    curl -L "https://github.com/docker/compose/releases/download/v2.29.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    if docker-compose --version | grep -q '^Docker Compose version v[0-9]\+\.[0-9]\+\.[0-9]\+$'; then
        docker-compose --version
    else
        echo -e "\n\e[1m\e[37m\e[41mdocker安装失败！退出脚本\e[0m\n"
        rm -rf /mnt/docker.sh    #delete    
        exit 1
    fi
    rm -rf /mnt/docker.sh    #delete      
    echo "=================================================================="
    echo -e "\t\tDocker-Compose 安装完成"
    echo -e "\n"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证"
    echo "=================================================================="
    systemctl restart docker
}
################################ docker-compose卸载 ################################
del_docker_compose() {
    echo -e "开始卸载docker-compose..."     
    rm -rf /usr/local/bin/docker-compose
    rm -rf /mnt/docker.sh    #delete         
    echo -e "\n\e[1m\e[37m\e[42mdocker-compose卸载成功\e[0m\n"
}
################################ 设定docker日志文件大小 ################################
docker_log_setting() {
    if ! command -v jq &> /dev/null; then
        echo "部分依赖未安装，安装依赖..."
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
        echo "/etc/docker 文件夹不存在，正在创建..."
        mkdir -p /etc/docker
    else
        echo "开始添加配置..."
    fi
    if [ -f /etc/docker/daemon.json ]; then
        sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
    else
        echo "{}" | sudo tee /etc/docker/daemon.json > /dev/null
    fi
    if [ ! -s /etc/docker/daemon.json ]; then
        echo "{}" | sudo tee /etc/docker/daemon.json > /dev/null
    fi
    echo "正在合并配置..."
    MERGED_FILE=$(mktemp)
    jq -s 'add' /etc/docker/daemon.json $TMP_FILE | sudo tee $MERGED_FILE > /dev/null
    if [ $? -ne 0 ]; then
        echo "合并时发生错误，请检查 JSON 格式是否正确。"
        sudo cp /etc/docker/daemon.json.bak /etc/docker/daemon.json
        rm -rf /mnt/docker.sh    #delete   
        exit 1
    fi    
    sudo mv $MERGED_FILE /etc/docker/daemon.json
    rm $TMP_FILE
    chmod 644 /etc/docker/daemon.json
    systemctl daemon-reload
    systemctl restart docker
    rm -rf /mnt/docker.sh    #delete         
    echo "=================================================================="
    echo -e "\t\t设定docker日志文件大小 已完成"
    echo -e "\n"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证\nDocker 日志设置已更新，最大日志文件大小为\e[1m\e[33m${LOG_SIZE}m\e[0m\n已在\e[1m\e[33m/etc/docker\e[0m目录下生成备份\e[1m\e[33mdaemon.json.bak\e[0m\n如出现问题，请自行恢复"
    echo "=================================================================="
}
################################ 开启docker IPV6 ################################
docker_IPV6() {
    if ! command -v jq &> /dev/null; then
        echo "部分依赖未安装，安装依赖..."
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
        echo "/etc/docker 文件夹不存在，正在创建..."
        mkdir -p /etc/docker
    else
        echo "开始添加配置..."
    fi
    if [ -f /etc/docker/daemon.json ]; then
        sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
    else
        echo "{}" | sudo tee /etc/docker/daemon.json > /dev/null
    fi
    if [ ! -s /etc/docker/daemon.json ]; then
        echo "{}" | sudo tee /etc/docker/daemon.json > /dev/null
    fi
    echo "正在合并配置..."
    MERGED_FILE=$(mktemp)
    jq -s 'add' /etc/docker/daemon.json $TMP_FILE | sudo tee $MERGED_FILE > /dev/null
    if [ $? -ne 0 ]; then
        echo "合并时发生错误，请检查 JSON 格式是否正确。"
        sudo cp /etc/docker/daemon.json.bak /etc/docker/daemon.json
        rm -rf /mnt/docker.sh    #delete   
        exit 1
    fi
    sudo mv $MERGED_FILE /etc/docker/daemon.json
    rm $TMP_FILE
    chmod 644 /etc/docker/daemon.json
    systemctl daemon-reload
    systemctl restart docker
    rm -rf /mnt/docker.sh    #delete         
    echo "=================================================================="
    echo -e "\t\tDocker IPv6 设置 已完成"
    echo -e "\n"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证\n已在\e[1m\e[33m/etc/docker\e[0m目录下生成备份\e[1m\e[33mdaemon.json.bak\e[0m\n如出现问题，请自行恢复"
    echo "=================================================================="    
}
################################ 开启docker API ################################
docker_api() {
    echo "开始配置开启2375端口..."
    cp /usr/lib/systemd/system/docker.service /usr/lib/systemd/system/docker.service.bak
    sed -i 's|-H fd://|-H tcp://0.0.0.0:2375 -H fd://|g' /usr/lib/systemd/system/docker.service
    chmod 644 /etc/docker/daemon.json
    systemctl daemon-reload
    systemctl restart docker
    rm -rf /mnt/docker.sh    #delete         
    echo -e "\n\e[1m\e[37m\e[42mDocker API 2375端口已开启\e[0m\n"
    echo "=================================================================="
    echo -e "\t\t开启docker API 2375端口 已完成"
    echo -e "\n"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证\n已在\e[1m\e[33m/usr/lib/systemd/system\e[0m目录下生成备份\e[1m\e[33mdocker.service.bak\e[0m\n如出现问题，请自行恢复"
    echo "=================================================================="   
}
################################ 主程序 ################################
docker_choose