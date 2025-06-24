#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
export APT_LISTCHANGES_FRONTEND=none

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
    echo "6. 一键安装以上所有基础设置"
    echo "7. 一键安装1、3、4选项设置"
    echo "8. 添加/删除SWAP"
    echo "9. 一键开通SSH登录"   
    echo -e "\t"
    echo "-. 返回上级菜单"      
    echo "0. 退出脚本"            
    read -p "请选择服务: " choice
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
        6)
            white "一键安装所有基础设置..."
            apt_update_upgrade
            apt_install
            set_timezone
            set_ntp
            modify_dns_stub_listener
            rm -rf /mnt/basic_settings.sh    #delete                   
            ;;                
        7)
            white "一键安装1、3、4选项设置..."
            apt_update_upgrade
            set_timezone
            set_ntp
            modify_dns_stub_listener
            rm -rf /mnt/basic_settings.sh    #delete                   
            ;;
        8)            
            swap_choose
            ;;
        9)            
            openSSH
            ;;            
        0)
            red "退出脚本，感谢使用."
            rm -rf /mnt/basic_settings.sh    #delete         
            ;;
        -)
            white "脚本切换中，请等待..."
            rm -rf /mnt/basic_settings.sh    #delete
            wget -q -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
            ;;                              
        *)
            white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            /mnt/basic_settings.sh
            ;;
    esac 
}
################################更新环境################################
apt_update_upgrade() {
    white "配置基础设置并安装依赖..."
    sleep 1
    apt-get update -y && apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || { red "环境更新失败！退出脚本"; exit 1; }
    green "环境更新成功"
}
################################安装相关依赖################################
apt_install() {
    white "环境依赖安装开始..."
    apt install curl wget tar gawk sed cron unzip nano sudo vim sshfs net-tools nfs-common bind9-host adduser libfontconfig1 musl git build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64 -y || { red "环境依赖安装失败！退出脚本"; exit 1; }
    green "环境依赖安装成功"
}
################################设置时区################################
set_timezone() {
    timedatectl set-timezone Asia/Shanghai || { red "时区设置失败！退出脚本"; exit 1; }
    green "时区设置成功"
}
################################设置NTP################################    
set_ntp() {    
    ntp_config="NTP=ntp.aliyun.com"
    echo "$ntp_config" | sudo tee -a /etc/systemd/timesyncd.conf > /dev/null
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-timesyncd
    green "已将 NTP 服务器配置为 ntp.aliyun.com"
}
################################ 关闭 53监听 ################################
modify_dns_stub_listener() {
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
                green "53端口占用已解除"
            else
                green "未找到53端口占用配置，无需操作"
            fi
        elif [ "$dns_stub_listener" = "DNSStubListener=yes" ]; then
            # 如果找到 DNSStubListener=yes，则修改为 no
            sed -i 's/^DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
            systemctl restart systemd-resolved.service
            green "53端口占用已解除"
        elif [ "$dns_stub_listener" = "DNSStubListener=no" ]; then
            # 如果 DNSStubListener 已为 no，提示用户无需修改
            green "53端口未被占用，无需操作"
        fi
    else
        green "/etc/systemd/resolved.conf 不存在，无需操作"
    fi
}
################################ 添加SWAP ################################
add_swap(){
    white "请输入需要添加的swap，建议为${yellow}内存的2倍${reset}！"
    while true; do
        read -p "请输入swap数值:" swapsize
        if [[ $swapsize =~ ^[0-9]+$ ]]; then
            break
        else
            red "swap数值格式不正确，请重新输入"
        fi
    done
    #检查是否存在swapfile
    grep -q "swapfile" /etc/fstab
    #如果不存在将为其创建swap
    if [ $? -ne 0 ]; then
        white "swapfile未发现，正在为其创建swapfile"
        fallocate -l ${swapsize}M /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap defaults 0 0' >> /etc/fstab
        green "swap创建成功，并查看信息："
        cat /proc/swaps
        cat /proc/meminfo | grep Swap
        rm -rf /mnt/basic_settings.sh    #delete     
    else
        red "swapfile已存在，swap设置失败，请先运行脚本删除swap后重新设置！"
        rm -rf /mnt/basic_settings.sh    #delete
        exit 1
    fi
}
################################ 删除SWAP ################################
del_swap(){
#检查是否存在swapfile
    grep -q "swapfile" /etc/fstab
    #如果存在就将其移除
    if [ $? -eq 0 ]; then
        white "swapfile已发现，正在将其移除..."
        sed -i '/swapfile/d' /etc/fstab
        echo "3" > /proc/sys/vm/drop_caches
        swapoff -a
        rm -f /swapfile
        green "swap已删除！"
        rm -rf /mnt/basic_settings.sh    #delete 
    else
        red "swapfile未发现，swap删除失败！"
        rm -rf /mnt/basic_settings.sh    #delete
        exit 1 
    fi
}
################################ SWAP选择 ################################
swap_choose(){
    clear
    echo "=================================================================="
    echo -e "\t\t SWAP 添加/删除脚本 by 忧郁滴飞叶"
    echo -e "\t\n"   
    echo "请选择要操作的基本设置："
    echo "=================================================================="   
    echo "1. 添加swap"
    echo "2. 删除swap"
    echo -e "\t" 
    echo "-. 返回上级菜单"      
    echo "0. 退出脚本"         
    read -p "请选择服务: " num
    case "$num" in
        1)
        add_swap
        ;;
        2)
        del_swap
        ;;
        -)
        white "脚本切换中，请等待..."
        basic_choose
        ;;
        0)
        red "退出脚本，感谢使用."
        rm -rf /mnt/basic_settings.sh    #delete         
        ;;
        *)
        white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
        sleep 1
        swap_choose
        ;;
    esac
    }
################################ 一键开通SSH登录 ################################
openSSH() {
    white "正在开启SSH登录相关配置..."
    sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config
    sed -i 's/^#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
    sed -i 's/^#PasswordAuthentication/PasswordAuthentication/' /etc/ssh/sshd_config
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    systemctl reload sshd
    systemctl restart sshd
    rm -rf /mnt/basic_settings.sh    #delete     
    green "SSH登录已开启，22端口登录"
}
################################ 主程序 ################################
basic_choose