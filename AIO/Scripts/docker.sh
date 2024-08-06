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
    echo "5. 卸载docker"
    echo "6. 卸载docker-compose"    
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
            del_docker
            # echo -e "代码未完成，请耐心等待..."
            # /mnt/docker.sh            
            ;;            
        6)
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

# 停止 Docker 服务
sudo systemctl stop docker
sudo systemctl stop docker.socket

# 卸载 Docker 相关的包
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io
sudo apt-get autoremove -y --purge docker-ce docker-ce-cli containerd.io

# 删除所有 Docker 数据
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

# 删除 Docker 配置文件
sudo rm /etc/docker/daemon.json

# 删除 Docker 服务文件
sudo rm /etc/systemd/system/docker.service
sudo rm /etc/systemd/system/docker.socket
sudo rm /lib/systemd/system/docker.service
sudo rm /lib/systemd/system/docker.socket

# 重新加载系统守护进程
sudo systemctl daemon-reload
sudo systemctl reset-failed

echo "Docker 已成功卸载。"

# 检查 Docker 是否被完全卸载
if ! which docker > /dev/null; then
    echo -e "\n\e[1m\e[37m\e[42mdocker卸载成功\e[0m\n"
else
    echo -e "\n\e[1m\e[37m\e[41mDocker 卸载失败，请检查剩余的 Docker 组件\e[0m\n"
    rm -rf /mnt/docker.sh    #delete   
    exit 1
fi
    sudo systemctl daemon-reload
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
while true; do
    read -p "请输入日志文件的最大大小（单位m，例如：20、50等，默认50）： " LOG_SIZE
    LOG_SIZE="${LOG_SIZE:-50}"
    if [[ $LOG_SIZE =~ ^[0-9]+$ ]]; then
        break
    else
        echo -e "\e[31m日志文件的大小格式输入不正确，请重新输入\e[0m"
    fi
done

# 创建临时文件用于日志设置
TMP_FILE=$(mktemp)

# 将用户输入的数值与固定的单位 "m" 写入临时文件
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
if [ -f /etc/docker/daemon.json ]; then
    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
else
    echo "{}" | sudo tee /etc/docker/daemon.json > /dev/null
fi

# 如果 daemon.json 为空，则用 {} 替换其内容以保证是有效的 JSON 对象
if [ ! -s /etc/docker/daemon.json ]; then
    echo "{}" | sudo tee /etc/docker/daemon.json > /dev/null
fi

# 合并日志设置与现有的 daemon.json
jq -s '.[0] * .[1]' /etc/docker/daemon.json $TMP_FILE | sudo tee /etc/docker/daemon.json > /dev/null

# 清理临时文件
rm $TMP_FILE

# 重新启动 Docker 服务以应用新的设置
sudo systemctl restart docker

# 删除脚本文件
# rm -rf /mnt/docker.sh

echo "Docker 日志设置已更新，最大日志文件大小为 ${LOG_SIZE}m"


}
################################ 开启docker IPV6 ################################
docker_IPV6() {
# 创建临时文件用于 IPv6 设置
TMP_FILE=$(mktemp)

# 将 IPv6 设置写入临时文件
cat > $TMP_FILE <<EOF
{
    "ipv6": true,
    "fixed-cidr-v6": "fd00:dead:beef:c0::/80",
    "experimental": true,
    "ip6tables": true
}
EOF

# 备份现有的 daemon.json
if [ -f /etc/docker/daemon.json ]; then
    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
else
    echo "{}" | sudo tee /etc/docker/daemon.json > /dev/null
fi

# 检查 daemon.json 是否为空
if [ -s /etc/docker/daemon.json ]; then
    # 合并 IPv6 设置与现有的 daemon.json
    jq -s '.[0] * .[1]' /etc/docker/daemon.json $TMP_FILE | sudo tee /etc/docker/daemon.json > /dev/null
else
    # daemon.json 为空，直接写入新的内容
    sudo cp $TMP_FILE /etc/docker/daemon.json
fi

# 清理临时文件
rm $TMP_FILE

# 重新启动 Docker 服务以应用新的设置
sudo systemctl restart docker

# 删除脚本文件
# rm -rf /mnt/docker.sh

echo "Docker IPv6 设置已更新"


}
################################ 主程序 ################################
docker_choose