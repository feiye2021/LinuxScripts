#!/bin/bash

current_hostname=$(hostname)
clear
rm -rf /mnt/main_install.sh
echo "=================================================================="
echo -e "\t\tHostName修改脚本 by 忧郁滴飞叶"
echo -e "\t\n"
echo -e "当前的主机名是:\e[1m\e[33m$current_hostname\e[0m，脚本完成后将自动重启以应用设置。"
echo "=================================================================="
read -p "请输入新的主机名: " new_hostname
if [[ -z "$new_hostname" ]]; then
    echo "主机名不能为空，脚本退出。"
    exit 1
fi
echo "$new_hostname" | sudo tee /etc/hostname
sudo sed -i "s/$current_hostname/$new_hostname/g" /etc/hosts
sudo hostnamectl set-hostname "$new_hostname"
echo -e "新的主机名已设置为:\e[1m\e[33m$new_hostname\e[0m，系统即将重启。"
rm -rf /mnt/hostname_setting.sh
sleep 1
sudo reboot