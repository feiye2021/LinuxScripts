#!/bin/bash

################################ IP 选择 ################################
ip_choose() {
    clear
    rm -rf /mnt/main_install.sh
    echo "=================================================================="
    echo -e "\t\tIP 选择脚本 by 忧郁滴飞叶"
    echo -e "\t\n"
    echo "请选择要设置的网络模式，设置完成后脚本将自动重启系统："
    echo "=================================================================="
    echo "1. 静态IP"
    echo "2. DHCP"
    echo -e "\t"
    echo "-. 返回上级菜单"    
    echo "0. 退出脚本"
    read -p "输入选项（1或2）： " choice
    case $choice in
        1)
            ip_checking
            static_ip_setting
            ;;
        2)
            ip_checking
            dhcp_setting
            ;;
        0)
            echo -e "\e[31m退出脚本，感谢使用.\e[0m"
            rm -rf /mnt/ip.sh    #delete         
            ;;
        -)
            echo "脚本切换中，请等待。"
            wget -q -O mosdns_singbox_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/mosdns_singbox_install.sh && chmod +x mosdns_singbox_install.sh && ./mosdns_singbox_install.sh
            ;;            
        *)
            echo "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            /mnt/ip.sh
            ;;
    esac 
}
################################ 网卡及网络设置文件检测 ################################
ip_checking() {
    NETPLAN_DIR="/etc/netplan"
    NETPLAN_FILES=($NETPLAN_DIR/*.yaml)
    INTERFACES=($(ls /sys/class/net | grep -v lo))
    if [[ ${#INTERFACES[@]} -gt 1 ]]; then
        echo "检测到多个网卡，请选择要修改的网卡："
        select INTERFACE in "${INTERFACES[@]}"; do
            if [[ -n "$INTERFACE" ]]; then
                NET_INTERFACE="$INTERFACE"
                break
            fi
        done
    elif [[ ${#INTERFACES[@]} -eq 1 ]]; then
        NET_INTERFACE="${INTERFACES[0]}"
    else
        echo "未找到网络接口，脚本退出。"
        exit 1
    fi
    if [[ ${#NETPLAN_FILES[@]} -gt 1 ]]; then
        echo "检测到多个Netplan文件，请选择要修改的文件："
        select FILE in "${NETPLAN_FILES[@]}"; do
            if [[ -n "$FILE" ]]; then
                NETPLAN_FILE="$FILE"
                break
            fi
        done
    elif [[ ${#NETPLAN_FILES[@]} -eq 1 ]]; then
        NETPLAN_FILE="${NETPLAN_FILES[0]}"
    else
        echo "未找到Netplan网络配置文件，脚本退出。"
        exit 1
    fi
}
################################ 设置静态IP ################################
static_ip_setting() {
    read -p "请输入静态IP地址（例如10.10.10.2）： " static_ip
    echo -e "您输入的静态IP地址为：\e[1m\e[33m$static_ip\e[0m。"
    read -p "请输入子网掩码（例如24，回车默认为24）： " netmask
    netmask="${netmask:-24}"
    echo -e "您输入的子网掩码为：\e[1m\e[33m$netmask\e[0m。"
    read -p "请输入网关地址（例如10.10.10.1）： " gateway
    echo -e "您输入的网关地址为：\e[1m\e[33m$gateway\e[0m。"
    read -p "请输入DNS服务器地址（例如10.10.10.3）： " dns
    echo -e "您输入的DNS服务器地址为：\e[1m\e[33m$dns\e[0m。"
    sudo cp "$NETPLAN_FILE" "$NETPLAN_FILE.bak"
    sudo bash -c "cat > $NETPLAN_FILE" <<EOL
network:
    version: 2
    ethernets:
        $NET_INTERFACE:
            addresses:
                - $static_ip/$netmask
            nameservers:
                addresses:
                    - $dns
            routes:
                - to: default
                  via: $gateway
EOL
    sudo netplan apply
    if [[ $? -eq 0 ]]; then
        echo -e "静态IP已设置为：\e[1m\e[33m$static_ip\e[0m，系统即将重启。"
        sleep 1
        rm -rf /mnt/ip.sh    #delete 
        sudo reboot
    else
        echo "设置静态IP失败，请检查配置。"
        rm -rf /mnt/ip.sh    #delete 
        exit 1
    fi
}
################################ 设置DHCP ################################
dhcp_setting() {
    if grep -q "dhcp4: true" "$NETPLAN_FILE"; then
        echo "当前已经是DHCP配置，无需修改。"
        rm -rf /mnt/ip.sh    #delete 
    else
        sudo cp "$NETPLAN_FILE" "$NETPLAN_FILE.bak"
        sudo bash -c "cat > $NETPLAN_FILE" <<EOL
network:
    version: 2
    ethernets:
        $NET_INTERFACE:
            dhcp4: true
EOL
        sudo netplan apply
        if [[ $? -eq 0 ]]; then
            echo -e "已设置为\e[1m\e[33mDHCP模式\e[0m，系统即将重启。"
            sleep 1
            rm -rf /mnt/ip.sh    #delete 
            sudo reboot
        else
            echo "设置DHCP模式失败，请检查配置。"
            rm -rf /mnt/ip.sh    #delete 
            exit 1
        fi
    fi
}
################################ 主程序 ################################
ip_choose