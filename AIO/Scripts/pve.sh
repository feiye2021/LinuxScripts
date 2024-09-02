#!/bin/bash

clear
rm -rf /mnt/main_install.sh

red(){
    echo -e "\e[31m$1\e[0m"
}
green(){
    echo -e "\n\e[1m\e[37m\e[42m$1\e[0m\n"
}
yellow='\e[1m\e[33m'
yellow_minute='\e[33m'
green_minute='\e[32m'
reset='\e[0m'
white(){
    echo -e "$1"
}
# 检查是否以 root 用户身份运行
if [[ $EUID -ne 0 ]]; then
    red "此脚本必须以 root 身份运行" 
    [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete    
    exit 1
fi
# 验证输入是否为纯数字
is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}
################################ PVE 选择 ################################
pve_choose() {
    clear
    rm -rf /mnt/main_install.sh
    echo "=================================================================="
    echo -e "\t\tPVE 综合脚本 by 忧郁滴飞叶"
    echo -e "\t\n"
    echo "请选择服务："
    echo "=================================================================="
    echo "1. 开启硬件直通"
    echo "2. 虚拟机/LXC容器 解锁"
    echo "3. img转系统盘"
    echo "4. LXC容器调用核显"    
    echo "5. 关闭指定虚拟机后开启指定虚拟机"        
    echo -e "\t"
    echo "9. 当前脚本转快速启动"        
    echo "-. 返回主菜单"    
    echo "0. 退出脚本"
    read -p "请选择服务: " choice
    case $choice in
        1)
            hardware_passthrough
            ;;    
        2)
            unlcok_PVE
            ;;
        3)
            importdisk
            ;;
        4)
            configure_gpu_and_lxc
            ;;
        5)
            close_and_start
            ;;
        9)
            quick
            ;;
        0)
            red "退出脚本，感谢使用."
            [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete         
            ;;
        -)
            white "脚本切换中，请等待..."
            [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete
            wget -q -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
            ;;
        *)
            white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            pve_choose
            ;;
    esac 
}
################################ 开启硬件直通 ################################
hardware_passthrough() {
    # 提示用户选择芯片类型并设定变量，直到输入正确
    while true; do
        read -p "请选择芯片类型（1: Intel, 2: AMD）： " chip_type
        if [[ "$chip_type" == "1" || "$chip_type" == "2" ]]; then
            break
        else
            red "无效的选择，请重新输入"
        fi
    done

    # 启用 IOMMU
    echo "启用 IOMMU..."
    if [ "$chip_type" == "1" ]; then
        white "选择 ${yellow}Intel 芯片${reset}，启用  ${yellow}Intel IOMMU${reset}..."
        sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt/' /etc/default/grub
    elif [ "$chip_type" == "2" ]; then
        white "选择 ${yellow}AMD 芯片${reset}，启用 ${yellow}AMD IOMMU${reset}..."
        sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt/' /etc/default/grub
    fi

    # 更新 GRUB 配置
    white "更新 GRUB 配置..."
    update-grub

    white "检查并加载必要的内核模块..."
    
    # 需要添加的模块列表
    modules=("vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd")
    
    # 检查并添加模块
    for module in "${modules[@]}"; do
        if ! grep -q "^$module$" /etc/modules; then
            echo "$module" >> /etc/modules
        fi
    done
    white "更新 /etc/modules 配置..."    
    update-initramfs -u -k all

    # 重启以应用更改
    white "需要${yellow}重启${reset}系统以应用更改。"
    read -p "是否立即重启系统？ (Y/n): " confirm
    confirm=${confirm:-y}
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        reboot
    else
        white "请${yellow}手动重启${reset}系统以应用更改"
    fi
}    
################################ 虚拟机/LXC容器 解锁 ################################
unlcok_PVE() {
# 提示用户输入选项并设定变量，直到输入正确
while true; do
    echo "请选择需解锁的设备类型:"
    echo "1) 虚拟机（VM）"
    echo "2) LXC容器（LXC）"
    read -p "请输入选项： " option
    if [[ "$option" == "1" || "$option" == "2" ]]; then
        if [[ "$option" == "1" ]]; then
            white "您选择解锁的设备类型为${yellow}虚拟机（VM）${reset}" 
            else           
            white "您选择解锁的设备类型为${yellow}LXC容器（LXC）${reset}"
        fi    
        break
    else
        red "无效的选项，请重新输入"
    fi
done
# 提示用户输入数字变量，直到输入正确
while true; do
    read -p "请输入需解锁的设备编号： " number
    if [[ "$number" =~ ^[0-9]+$ ]]; then
            white "您输入需解锁的设备编号为${yellow}$number${reset}"
        break
    else
        red "无效的选项，请重新输入"
    fi
done
# 根据选项组合并执行相应的命令
if [ "$option" == "1" ]; then
    white "即将执行${yellow}qm unlock "$number"${reset}"
    qm unlock $number
    [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete         
    green "执行qm unlock "$number"完毕"
elif [ "$option" == "2" ]; then
    white "即将执行${yellow}pct unlock "$number"${reset}"
    pct unlock $number
    [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete             
    green "执行pct unlock "$number"完毕"
fi
}
################################ img转系统盘 ################################
importdisk() {
    # 提示用户输入虚拟机ID并验证输入
    while true; do
        read -p "请输入虚拟机ID: " vm_id
        if is_number "$vm_id"; then
            echo -e "您输入的虚拟机ID为：${yellow}$vm_id${reset}"
            break
        else
            red "请输入有效的虚拟机ID（纯数字）"
        fi
    done

    # 提示用户输入文件名
    read -p "请输入需转换的文件名: " filename
    echo -e "您输入需转换的文件名为：${yellow}$filename${reset}"

    # 提示用户选择路径并验证输入
    while true; do
        echo "请选择路径或自定义路径:"
        echo "1) TRUENAS：/mnt/pve/TRUENAS/template/iso/"
        echo "2) 系统存储：/var/lib/vz/template/iso"
        read -p "请输入选项或路径 (默认为1): " path_choice

        if [[ -z "$path_choice" || "$path_choice" == "1" ]]; then
            path="/mnt/pve/TRUENAS/template/iso"
            echo -e "您选择的路径为：${yellow}$path${reset}"
            break
        elif [[ "$path_choice" == "2" ]]; then
            path="/var/lib/vz/template/iso"
            echo -e "您选择的路径为：${yellow}$path${reset}"
            break
        else
            path="$path_choice"
            echo -e "您自定义的路径为：${yellow}$path${reset}"
            break
        fi
    done

    # 提示用户选择存储并验证输入
    while true; do
        echo "请选择存储:"
        echo "1) local"
        echo "2) local-lvm"
        read -p "请输入选项 (默认为1): " storage_choice

        if [[ -z "$storage_choice" || "$storage_choice" == "1" ]]; then
            storage="local"
            echo -e "您选择的存储为：${yellow}$storage${reset}"
            break
        elif [[ "$storage_choice" == "2" ]]; then
            storage="local-lvm"
            echo -e "您选择的存储为：${yellow}$storage${reset}"
            break
        elif ! is_number "$storage_choice"; then
            red "请输入有效的选项（1 或 2）"
        fi
    done

    # 运行qm importdisk命令
    white "即将执行${yellow}qm importdisk "$vm_id" "$path/$filename" "$storage"${reset}"
    [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete  
    qm importdisk "$vm_id" "$path/$filename" "$storage"
       
}
################################ 核显数据采集 ################################
# 获取并选择GPU设备
select_gpu() {
    local gpu_info=$(ls -la /dev/dri/)
    local cards=()
    local renders=()

    # 分别提取卡和渲染设备
    while read -r line; do
        if echo "$line" | grep -q 'card'; then
            cards+=("$line")
        elif echo "$line" | grep -q 'render'; then
            renders+=("$line")
        fi
    done <<< "$gpu_info"

    local groups=()
    for card in "${cards[@]}"; do
        local card_major_minor=$(echo "$card" | awk '{print $5":"$6}' | sed 's/,//g')
        local card_name=$(echo "$card" | awk '{print $NF}')
        for render in "${renders[@]}"; do
            local render_major_minor=$(echo "$render" | awk '{print $5":"$6}' | sed 's/,//g')
            local render_name=$(echo "$render" | awk '{print $NF}')
            if [[ "${card_major_minor%%:*}" == "${render_major_minor%%:*}" ]]; then
                groups+=("$card_name $card_major_minor $render_name $render_major_minor")
            fi
        done
    done

    if [ "${#groups[@]}" -eq 0 ]; then
        [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete  
        red "未检测到有效的GPU设备。"
        exit 1
    elif [ "${#groups[@]}" -eq 1 ]; then
        selected_group="${groups[0]}"
    else
        white "检测到多个GPU设备组，请选择要共享的组："
        for i in "${!groups[@]}"; do
            white "[$i] ${groups[$i]}"
        done
        while true; do
            read -p "请选择设备组（输入编号）： " group_index
            if is_number "$group_index" && [ "$group_index" -ge 0 ] && [ "$group_index" -lt "${#groups[@]}" ]; then
                selected_group="${groups[$group_index]}"
                break
            else
                red "无效的选择，请重新输入。"
            fi
        done
    fi

    # 提取选定组的信息
    local card_name=$(echo "$selected_group" | awk '{print $1}')
    local card_major_minor=$(echo "$selected_group" | awk '{print $2}')
    local render_name=$(echo "$selected_group" | awk '{print $3}')
    local render_major_minor=$(echo "$selected_group" | awk '{print $4}')

    # 输出日志信息
    white "选择的GPU设备名称：${yellow}${card_name}${reset}，设备号：${yellow}${card_major_minor}${reset}"
    white "选择的GPU设备名称：${yellow}${render_name}${reset}，设备号：${yellow}${render_major_minor}${reset}"

}
################################ LXC 共享核显 ################################
# 提示用户选择核显类型并安装相应驱动，并配置LXC使其可以使用核显
configure_gpu_and_lxc() {
    while true; do
        read -p "请选择芯片类型（1: Intel, 2: AMD）： " chip_type
        if [[ "$chip_type" == "1" || "$chip_type" == "2" ]]; then
            break
        else
            red "无效的选择，请重新输入"
        fi
    done

    while true; do
        read -p "请输入需配置的LXC编号： " lxc_id
        if is_number "$lxc_id"; then
            break
        else
            red "无效的输入，请重新输入"
        fi
    done

    if [ "$chip_type" == "1" ]; then
        white "选择 ${yellow}Intel 芯片${reset}，安装 ${yellow}Intel 驱动${reset}..."
        apt install -y intel-media-va-driver-non-free intel-gpu-tools
        white "验证 Intel 驱动安装..."
        intel_gpu_top &
    elif [ "$chip_type" == "2" ]; then
        white "选择 ${yellow}AMD 芯片${reset}，安装 ${yellow}AMD 驱动${reset}..."
        apt install -y radeontop
        white "验证 AMD 驱动安装..."
        radeontop &
    fi

    white "检查并加载必要的内核模块..."
    
    # 需要添加的模块列表
    modules=("vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd")
    
    # 创建一个临时文件来存储新的内容
    temp_file=$(mktemp)

    # 保留原有内容并添加模块
    cp /etc/modules "$temp_file"
    for module in "${modules[@]}"; do
        if ! grep -q "^$module$" /etc/modules; then
            echo "$module" >> "$temp_file"
        fi
    done
    
    # 替换原文件
    mv "$temp_file" /etc/modules

    update-initramfs -u -k all

    config_file="/etc/pve/lxc/${lxc_id}.conf"

    if [ -f "$config_file" ]; then
        white "正在配置 ${yellow}LXC $lxc_id${reset}..."
        sed -i '/^unprivileged: 1/d' "$config_file"
        
        # 选择并配置GPU
        select_gpu

        local card_name=$(echo "$selected_group" | awk '{print $1}')
        local card_major_minor=$(echo "$selected_group" | awk '{print $2}' | tr ',' ':')
        local render_name=$(echo "$selected_group" | awk '{print $3}')
        local render_major_minor=$(echo "$selected_group" | awk '{print $4}' | tr ',' ':')

        echo "lxc.cgroup2.devices.allow: c $card_major_minor rwm" >> "$config_file"
        echo "lxc.cgroup2.devices.allow: c $render_major_minor rwm" >> "$config_file"
        echo "lxc.mount.entry: /dev/dri/${card_name} dev/dri/${card_name} none bind,optional,create=file" >> "$config_file"
        echo "lxc.mount.entry: /dev/dri/${render_name} dev/dri/${render_name} none bind,optional,create=file" >> "$config_file"
        echo "lxc.apparmor.profile: unconfined" >> "$config_file"
        echo "lxc.cap.drop:" >> "$config_file"
        [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete          
        green "配置完成，重启LXC后生效。"
    else
        [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete  
        red "配置文件 $config_file 不存在，请检查LXC编号。"
    fi
}
################################ 关闭选定虚拟机后开启选定虚拟机 ################################
close_and_start() {
    clear
    echo "=================================================================="
    echo -e "\t\t PVE虚拟机关闭并开启 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo -e "欢迎使用PVE虚拟机关闭并开启脚本，本脚本用于远程网络调试时开启关闭\n网络虚拟机保证断网切换虚拟机"
    echo "请根据提示进行操作："
    echo "=================================================================="
    # 获取并验证需关闭的虚拟机编号
    close_vm_id=$(validate_number "" "请输入需关闭的虚拟机编号 : ")

    # 获取并验证需关闭的虚拟机类型
    close_vm_type=$(validate_type "" "请选择需关闭的虚拟机类型 (1为虚拟机，2为LXC): ")

    # 获取并验证需开启的虚拟机编号
    start_vm_id=$(validate_number "" "请输入需开启的虚拟机编号 : ")

    # 获取并验证需开启的虚拟机类型
    start_vm_type=$(validate_type "" "请选择需开启的虚拟机类型 (1为虚拟机，2为LXC): ")

    # 根据选择设定虚拟机类型
    if [ "$close_vm_type" == "1" ]; then
        close_type_cmd="虚拟机"
    elif [ "$close_vm_type" == "2" ]; then
        close_type_cmd="LXC"
    fi
    if [ "$start_vm_type" == "1" ]; then
        start_type_cmd="虚拟机"
    elif [ "$start_vm_type" == "2" ]; then
        start_type_cmd="LXC"
    fi

    white "\n您设定关闭 ${yellow}$close_type_cmd${reset} ${yellow}$close_vm_id${reset}"
    white "您即将开启 ${yellow}$start_type_cmd${reset} ${yellow}$start_vm_id${reset}"
    sleep 1

    # 根据类型构建关闭和状态检查命令
    if [ "$close_vm_type" == "1" ]; then
        close_cmd="qm stop $close_vm_id"
        status_cmd="qm status $close_vm_id"
    elif [ "$close_vm_type" == "2" ]; then
        close_cmd="pct stop $close_vm_id"
        status_cmd="pct status $close_vm_id"
    fi

    white "\n正在关闭 ${yellow}$close_type_cmd${reset} ${yellow}$close_vm_id${reset} ..."
    $close_cmd
    white "已关闭 ${yellow}$close_type_cmd${reset} ${yellow}$close_vm_id${reset} ，等待30秒后状态检查..."

    sleep 30
    white "开始检查 ${yellow}$close_type_cmd${reset} ${yellow}$close_vm_id${reset} 虚拟机状态..."
    vm_status=$($status_cmd)

    # 检查虚拟机状态并执行操作
    while [ "$(echo $vm_status | grep 'status: running')" != "" ]; do
        white "\n${yellow}$close_type_cmd${reset} ${yellow}$close_vm_id${reset} 仍在运行，尝试再次关闭..."
        $close_cmd
        white "已再次关闭 ${yellow}$close_type_cmd${reset} ${yellow}$close_vm_id${reset} ，等待30秒后状态检查..."
        sleep 30
        white "开始检查 ${yellow}$close_type_cmd${reset} ${yellow}$close_vm_id${reset} 状态..."
        vm_status=$($status_cmd)
        
        if [ "$(echo $vm_status | grep 'status: running')" == "" ]; then
            break
        fi

        # 检查网络状态
        ping -c 3 www.baidu.com &> /dev/null
        if [ $? -eq 0 ]; then
            white "\n${yellow}$close_type_cmd${reset} ${yellow}$close_vm_id${reset} 仍未关闭，且网络连接正常"
            red "$close_type_cmd $close_vm_id 处于运行状态无法关闭，退出脚本"
            [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete  
            exit 0
        else
            white "\n网络连接失败，重启 ${yellow}$close_type_cmd${reset} ${yellow}$close_vm_id${reset} ..."

            # 根据类型重新启动虚拟机
            if [ "$close_vm_type" == "1" ]; then
                qm start $close_vm_id
            elif [ "$close_vm_type" == "2" ]; then
                pct start $close_vm_id
            fi
            [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete  
            red "$close_type_cmd $close_vm_id 处于运行状态无法关闭，退出脚本"
            exit 0
        fi
    done

    # 启动需开启的虚拟机
    if [ "$start_vm_type" == "1" ]; then
        white "\n正在启动 ${yellow}$start_type_cmd${reset} ${yellow}$start_vm_id${reset} ..."
        qm start $start_vm_id
    elif [ "$start_vm_type" == "2" ]; then
        white "\n正在启动 ${yellow}$start_type_cmd${reset} ${yellow}$start_vm_id${reset} ..."
        pct start $start_vm_id
    fi

    [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete  
    green "关闭 $close_type_cmd $close_vm_id ，启动 $start_type_cmd $start_vm_id 操作完成"    
}
################################ 转快速启动 ################################
quick() {
    echo "=================================================================="
    echo -e "\t\t PVE脚本转快速启动 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo -e "欢迎使用PVE脚本转快速启动脚本，脚本运行完成后在shell界面输入pve即可调用脚本"
    echo "=================================================================="
    white "开始转快速启动..."
    wget -O /usr/bin/pve https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/pve.sh 
    chmod +x /usr/bin/pve
    green "PVE脚本转快捷启动已完成，shell界面输入pve即可调用脚本"
}
################################ 主程序 ################################
pve_choose