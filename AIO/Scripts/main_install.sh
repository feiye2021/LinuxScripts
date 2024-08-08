#!/bin/bash

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
################################主菜单################################
main() {
    clear
    echo "=================================================================="
    echo -e "\t\tAIO 脚本 by 忧郁滴飞叶"
    echo -e "\t\n"
    echo -e "温馨提示：\n本脚本推荐使用ububtu22.04环境，其他环境未经验证 "
    echo "=================================================================="
    echo "1. IP"
    echo "2. HostName"
    echo "3. 基础环境设置"    
    echo "4. MosDNS"
    echo "5. Sing-box"
    echo "6. Docker"
    echo "7. PVE系列"   
    echo -e "\t"    
    echo "0. 退出脚本"        
    read -p "请选择服务: " choice
    case $choice in
        1)
            white "脚本切换中，请等待..."
            wget -q -O /mnt/ip.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/ip.sh && chmod +x /mnt/ip.sh && /mnt/ip.sh
            ;;
        2)
            white "脚本切换中，请等待..."
            wget -q -O /mnt/hostname_setting.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/hostname_setting.sh && chmod +x /mnt/hostname_setting.sh && /mnt/hostname_setting.sh
            ;;
        3)
            white "脚本切换中，请等待..."
            wget -q -O /mnt/basic_settings.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/basic_settings.sh && chmod +x /mnt/basic_settings.sh && /mnt/basic_settings.sh
            ;;            
        4)
            white "脚本切换中，请等待..."
            wget -q -O /mnt/mosdns.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/mosdns.sh && chmod +x /mnt/mosdns.sh && /mnt/mosdns.sh
            ;;
        5)
            white "脚本切换中，请等待..."
            wget -q -O /mnt/singbox.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/singbox.sh && chmod +x /mnt/singbox.sh && /mnt/singbox.sh
            ;;
        6)
            white "脚本切换中，请等待..."
            wget -q -O /mnt/docker.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/docker.sh && chmod +x /mnt/docker.sh && /mnt/docker.sh
            ;;
        7)
            white "脚本切换中，请等待..."
            wget -q -O /mnt/pve.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/pve.sh && chmod +x /mnt/pve.sh && /mnt/pve.sh
            ;;             
        0)
            red "退出脚本，感谢使用."
            rm -rf /mnt/main_install.sh
            ;;    
        *)
            white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            main
            ;;
esac 
}
################################ 主程序 ################################
main