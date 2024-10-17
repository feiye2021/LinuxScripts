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

################################## Linux基础命令脚本 ################################
command_choose() {
    clear
    echo "=================================================================="
    echo -e "\t\tubuntu/debian 基础命令脚本 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo "欢迎使用 ubuntu/debian 基础命令脚本"
    echo "请选择要执行的服务："
    echo "=================================================================="
    echo "1. 启动服务（程序）"
    echo "2. 停止服务（程序）"    
    echo "3. 重启服务（程序）"
    echo "4. 查询服务（程序）状态"        
    echo "5. 重新加载配置"
    echo "6. 一键停止、重加载、重启服务（程序）" 
    echo "7. 查看服务（程序）报错日志"
    echo "8. 清屏"    
    echo -e "\t"
    echo "9. 当前脚本转快速启动"  
    echo "-. 返回上级菜单"      
    echo "0) 退出脚本"
    read -p "请选择服务: " choice
    # read choice
    case $choice in
        1)
            sotp_restart "start"
            ;;
        2)
            sotp_restart "stop"
            ;;              
        3)
            sotp_restart "restart"
            ;;
        4)
            sotp_restart "status"
            ;;
        5)
            systemctl daemon-reload    
            green "重新加载配置完成"
            [ -f /mnt/basic_command.sh ] && rm -rf /mnt/basic_command.sh    #delete    
            ;;
        6)
            all_sotp_restart
            ;;
        7)
            check_error 
            ;;            
        8)    
            clear
            [ -f /mnt/basic_command.sh ] && rm -rf /mnt/basic_command.sh    #delete    
            ;;            
        9)
            quick
            ;;            
        0)
            red "退出脚本，感谢使用."
            [ -f /mnt/basic_command.sh ] && rm -rf /mnt/basic_command.sh    #delete              
            ;;
        -)
            white "脚本切换中，请等待..."
            [ -f /mnt/basic_command.sh ] && rm -rf /mnt/basic_command.sh    #delete        
            wget -q -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
            ;;
        *)
            white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            command_choose
            ;;
    esac
}
################################ 停止、重加载、重启服务 ################################
sotp_restart() {
    action_name="$1"
    read -p "请输入执行操作的服务（程序）的名称： " service_name
    systemctl $action_name $service_name
    if [[ "$action_name" == "start" ]]; then
        green "启动 ${service_name} 成功"
    elif [[ "$action_name" == "stop" ]]; then
        green "停止 ${service_name} 成功"
    elif [[ "$action_name" == "restart" ]]; then
        green "重启 ${service_name} 成功"
    fi
    [ -f /mnt/basic_command.sh ] && rm -rf /mnt/basic_command.sh    #delete    
}
################################ 一键停止、重加载、重启服务 ################################
all_sotp_restart() {
    read -p "请输入执行操作的服务（程序）的名称： " service_name
    systemctl stop ${service_name} && systemctl daemon-reload && systemctl restart ${service_name}
    green "一键停止、重加载、重启 ${service_name} 服务成功"
    [ -f /mnt/basic_command.sh ] && rm -rf /mnt/basic_command.sh    #delete    
}
################################ 查看服务（程序）报错日志 ################################
check_error() {
    read -p "请输入要查询的服务（程序）的名称： " service_name
    [ -f /mnt/basic_command.sh ] && rm -rf /mnt/basic_command.sh    #delete 
    green "开始输出错误日志："
    journalctl -xe | grep ${service_name}
}
################################ 转快速启动 ################################
quick() {
    echo "=================================================================="
    echo -e "\t ubuntu/debian 基础命令脚本转快速启动 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo -e "欢迎使用 ubuntu/debian 基础命令脚本转快速启动脚本，脚本\n运行完成后在shell界面输入 esay 即可调用脚本"
    echo "=================================================================="
    white "开始转快速启动..."
    wget -O /usr/bin/easy https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/basic_command.sh
    chmod +x /usr/bin/easy
    green "ubuntu/debian 基础命令脚本转快捷启动已完成，shell界面输入 easy 即可调用脚本"
    [ -f /mnt/basic_command.sh ] && rm -rf /mnt/basic_command.sh    #delete    
}
################################ 主程序 ################################
command_choose