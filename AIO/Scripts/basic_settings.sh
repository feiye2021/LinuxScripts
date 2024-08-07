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
            rm -rf /mnt/basic_settings.sh    #delete                   
            ;;
        2)
            apt_install
            rm -rf /mnt/basic_settings.sh    #delete                   
            ;;    
        3)
            set_timezone
            rm -rf /mnt/basic_settings.sh    #delete                   
            ;;
        4)
            set_ntp
            rm -rf /mnt/basic_settings.sh    #delete                   
            ;;                        
        5)
            modify_dns_stub_listener
            rm -rf /mnt/basic_settings.sh    #delete                   
            ;;
        9)
            echo "一键安装所有基础设置..."
            apt_update_upgrade
            apt_install
            set_timezone
            set_ntp
            modify_dns_stub_listener
            rm -rf /mnt/basic_settings.sh    #delete                   
            ;;
        0)
            echo -e "\e[31m退出脚本，感谢使用.\e[0m"
            rm -rf /mnt/basic_settings.sh    #delete         
            ;;
        -)
            echo "脚本切换中，请等待..."
            rm -rf /mnt/basic_settings.sh    #delete
            wget -q -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
            ;;                              
        *)
            echo "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            /mnt/basic_settings.sh
            ;;
    esac 
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
################################ 主程序 ################################
basic_choose