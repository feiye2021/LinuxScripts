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
current_hostname=$(hostname)
echo "=================================================================="
echo -e "\t\tHostName修改脚本 by 忧郁滴飞叶"
echo -e "\t\n"
echo -e "当前的主机名是:${yellow}$current_hostname${reset}，脚本完成后将自动重启以应用设置"
echo "=================================================================="
read -p "请输入新的主机名: " new_hostname
if [[ -z "$new_hostname" ]]; then
    white "主机名不能为空，脚本退出。"
    exit 1
fi
echo "$new_hostname" | sudo tee /etc/hostname
sudo sed -i "s/$current_hostname/$new_hostname/g" /etc/hosts
sudo hostnamectl set-hostname "$new_hostname"
echo -e "新的主机名已设置为:${yellow}$new_hostname${reset}，系统即将重启"
rm -rf /mnt/hostname_setting.sh
sleep 1
sudo reboot