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
    echo "6. ubuntu/debian云镜像创建虚拟机（VM）"      
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
        6)
            cloud_vm_make
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

#################################### UBUNTU 版本选择 #############################################
ubuntu_VERSION_CHOOSE() {

    declare -A ubuntu_check_versions=(
        ["oracular"]="24.10"
        ["noble"]="24.04"
        ["jammy"]="22.04"
        ["focal"]="20.04"
        ["bionic"]="18.04"
    )

    ubuntu_check_order=("oracular" "noble" "jammy" "focal" "bionic")

    ubuntu_check_options=()
    for version in "${ubuntu_check_order[@]}"; do
        ubuntu_check_options+=("${version} (${ubuntu_check_versions[$version]})")
    done

    white "请选择Ubuntu版本："
    select ubuntu_check_choice in "${ubuntu_check_options[@]}"; do
        if [[ -n "${ubuntu_check_choice}" ]]; then
            ubuntu_check_version=$(echo "${ubuntu_check_choice}" | awk '{print $1}')
            ubuntu_check_version_number="${ubuntu_check_versions[$ubuntu_check_version]}"
            white "您选择了 ${ubuntu_check_version} (${ubuntu_check_version_number})"
            break
        else
            red "无效选择，请重试"
        fi
    done

    ubuntu_check_URL="https://cloud-images.ubuntu.com/${ubuntu_check_version}/"

    ubuntu_check_latest_date=$(curl -s ${ubuntu_check_URL} | grep -Eo 'href="[0-9]{8}/"' | sed 's/href="//;s/\///' | sort -r | head -n 1 | tr -d '"')

    if [ -z "$ubuntu_check_latest_date" ]; then
        red "无法获取最新版本日期"
    else
        white "最新版本日期: ${yellow}${ubuntu_check_latest_date} (Ubuntu ${ubuntu_check_version} ${ubuntu_check_version_number})"
        white "版本号: ${yellow}${ubuntu_check_version_number}${reset}"
    fi 

    UBUNTU_URL="https://cloud-images.ubuntu.com/${ubuntu_check_version}/${ubuntu_check_latest_date}/${ubuntu_check_version}-server-cloudimg-amd64.img"
    UBUNTU_FILENAME="/var/lib/vz/template/iso/cloud_ubuntu${ubuntu_check_version_number}.img"
    URL=$UBUNTU_URL
    FILENAME=$UBUNTU_FILENAME

}

#################################### UBUNTU 版本选择 #############################################
debian_VERSION_CHOOSE() {
    DEBIAN_URL="https://cloud.debian.org/images/cloud/bookworm/20231013-1532/debian-12-generic-amd64-20231013-1532.qcow2"
    DEBIAN_FILENAME="/var/lib/vz/template/iso/cloud_debian12.qcow2"

    URL=$DEBIAN_URL
    FILENAME=$DEBIAN_FILENAME
}   

#################################### 执行程序 #############################################
cloud_vm_make() {
    total_cpu_cores=$(grep -c '^processor' /proc/cpuinfo)

    # 询问用户选择镜像类型，默认选择Ubuntu
    while true; do
        white "请选择镜像类型:"
        white "1) Ubuntu [默认选项]"
        white "2) Debian 12"
        read -p "请选择: " os_choice
        os_choice=${os_choice:-1}
        if [[ $os_choice =~ ^[1-2]$ ]]; then
            break
        else
            red "无效选择，请输入1或2"
        fi
    done
    case $os_choice in
        1) ubuntu_VERSION_CHOOSE ;;
        2) debian_VERSION_CHOOSE ;;
    esac
    # 检查并输入虚拟机 ID
    while true; do
        read -p "请输入虚拟机ID (大于100): " vm_id
        if qm status $vm_id &>/dev/null || pct status $vm_id &>/dev/null; then
            red "虚拟机或LXC编号已存在，请输入其他编号"
        elif [ "$vm_id" -gt 100 ]; then
            break
        else
            red "请输入大于100的虚拟机ID"
        fi
    done

    # 询问用户输入虚拟机名称
    while true; do
        read -p "请输入虚拟机名称: " vm_name
        if [[ -n "$vm_name" ]]; then
            break
        else
            red "虚拟机名称不能为空，请重新输入。"
        fi
    done

    # 询问用户输入内存大小，确保是有效数字
    while true; do
        read -p "请输入虚拟机内存大小 (MB) [默认2048MB]: " memory_size
        memory_size=${memory_size:-2048}
        if [[ "$memory_size" =~ ^[0-9]+$ && "$memory_size" -gt 0 ]]; then
            break
        else
            red "无效的内存大小，请输入正整数"
        fi
    done

    # 询问用户输入CPU核心数，同时确保核心数不超过系统总核心数
    while true; do
        read -p "请输入CPU核心数 (当前系统的 CPU 核心总数为 $total_cpu_cores ，最大不可超过 $total_cpu_cores ) [默认$total_cpu_cores]: " cpu_cores
        cpu_cores=${cpu_cores:-$total_cpu_cores}
        if [ "$cpu_cores" -le "$total_cpu_cores" ]; then
            break
        else
            red "输入的 CPU 核心数超过了系统的最大核心数，请重新输入"
        fi
    done

    # 询问存储位置是local还是local-lvm
    while true; do
        white "请选择存储类型:"
        white "1) local [默认选项]"
        white "2) local-lvm"
        white "3) local-btrfs"
        read -p "请选择: " storage_choice
        storage_choice=${storage_choice:-1}
        if [ "$storage_choice" -eq 1 ]; then
            storage="local"
            break
        elif [ "$storage_choice" -eq 2 ]; then
            storage="local-lvm"
            break
        elif [ "$storage_choice" -eq 3 ]; then
            storage="local-btrfs"
            break    
        else
            red "无效选择，请输入1、2或3"
        fi
    done

    # 检查是否需要扩容磁盘
    while true; do
        read -p "是否需要扩容磁盘? (y/n) [默认y]: " expand_disk
        expand_disk=${expand_disk:-y}
        if [[ "$expand_disk" == "y" || "$expand_disk" == "n" ]]; then
            if [ "$expand_disk" == "y" ]; then
                read -p "请输入扩容大小，仅需输入扩容数字，默认扩容大小为8（单位：GB）: " resize_size_num
                resize_size_num=${resize_size_num:-8}
                resize_size=${resize_size_num}G
            fi
            break
        else
            red "无效选择，请输入 y 或 n"
        fi
    done

    # 询问IP地址，默认IP改为10.10.10.70
    read -p "请输入虚拟机的IP地址 [默认10.10.10.70]: " ip_address
    ip_address=${ip_address:-10.10.10.70}

    # 询问网关地址，默认网关改为10.10.10.1
    read -p "请输入网关地址 [默认10.10.10.1]: " gateway_address
    gateway_address=${gateway_address:-10.10.10.1}

    if [[ -f "$FILENAME" && $(stat -c%s "$FILENAME") -gt $((200 * 1024 * 1024)) ]]; then
        white "${yellow}镜像文件已存在，跳过下载...${reset}"
    else
        white "${yellow}正在下载镜像文件...${reset}"
        wget --quiet --show-progress -O "$FILENAME" "$URL"
        if [[ -f "$FILENAME" && $(stat -c%s "$FILENAME") -gt $((200 * 1024 * 1024)) ]]; then
            green "镜像文件下载完成"
        else
            red "文件不存在或大小小于200MB，请检查镜像文件"
            [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete  
            exit 1
        fi

    fi

    command="qm create $vm_id --name $vm_name --cpu host --cores $cpu_cores --memory $memory_size --net0 virtio,bridge=vmbr0 --machine q35 --scsihw virtio-scsi-single --bios ovmf --efidisk0 $storage:1,format=raw,efitype=4m,pre-enrolled-keys=1"
    white "开始创建${yellow}${vm_id} ${vm_name}虚拟机${reset}..."
    eval $command

    qm set $vm_id --scsi1 $storage:0,import-from=$FILENAME

    if [ "$expand_disk" == "y" ]; then
        qm resize $vm_id scsi1 "+${resize_size}"
        white "磁盘已扩容 ${yellow}${resize_size}${reset}"
    fi

    qm set $vm_id --ide2 $storage:cloudinit

    qm set $vm_id --ipconfig0 ip=$ip_address/24,gw=$gateway_address

    qm set $vm_id --boot c --bootdisk scsi1

    [ -f /mnt/pve.sh ] && rm -rf /mnt/pve.sh    #delete  
    green "虚拟机创建完成，ID为 $vm_id，名称为 $vm_name "
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