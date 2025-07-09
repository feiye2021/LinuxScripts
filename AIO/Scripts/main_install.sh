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
    echo "4. ubuntu/debian 基础命令"
    echo "5. MosDNS"
    echo "6. PVE系列" 
    echo "7. 智能家居系列"   
    echo "8. Docker"
    echo "9. Docker-Compose配置生成"
    echo "10. Unbound & Redis"

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
            wget -q -O /mnt/basic_command.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/basic_command.sh && chmod +x /mnt/basic_command.sh && /mnt/basic_command.sh
            ;;
        5)
            white "脚本切换中，请等待..."
            wget -q -O /mnt/mosdns.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/mosdns.sh && chmod +x /mnt/mosdns.sh && /mnt/mosdns.sh
            ;;
        6)
            white "脚本切换中，请等待..."
            wget -q -O /mnt/pve.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/pve.sh && chmod +x /mnt/pve.sh && /mnt/pve.sh
            ;;  
        7)
            white "脚本切换中，请等待..."
            wget -q -O /mnt/smarthome.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/smarthome.sh && chmod +x /mnt/smarthome.sh && /mnt/smarthome.sh
            ;;                                                 
        8)
            white "脚本切换中，请等待..."
            wget -q -O /mnt/docker.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/docker.sh && chmod +x /mnt/docker.sh && /mnt/docker.sh
            ;;
        9)
            white "脚本切换中，请等待..."
            wget -q -O /mnt/docker_compose.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/docker_compose.sh && chmod +x /mnt/docker_compose.sh && /mnt/docker_compose.sh
            ;;
        10)
            white "脚本切换中，请等待..."
            wget -q -O /mnt/unbound.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/unbound.sh && chmod +x /mnt/unbound.sh && /mnt/unbound.sh
            ;;          
        0)
            red "退出脚本，感谢使用."
            rm -rf /mnt/main_install.sh
            ;;
        999)
            quick
            ;;            
        *)
            white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            main
            ;;
        66)
            white "脚本切换中，请等待..."
            wget -q -O /mnt/psb.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/psb.sh && chmod +x /mnt/psb.sh && /mnt/psb.sh
            ;;              
esac 
}
################################ 转快速启动 ################################
quick() {
    echo "=================================================================="
    echo -e "\t\t 脚本转快速启动 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo -e "欢迎使用脚本转快速启动脚本，脚本运行完成后在shell界面输入main即可调用脚本"
    echo "=================================================================="
    white "开始转快速启动..."
    wget --quiet --show-progress -O /usr/bin/main https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh 
    chmod +x /usr/bin/main
    green "脚本转快捷启动已完成，shell界面输入main即可调用脚本"
}
################################ 主程序 ################################
main