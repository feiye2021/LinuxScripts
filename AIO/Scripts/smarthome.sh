 #!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
export APT_LISTCHANGES_FRONTEND=none

clear
[ -f /mnt/main_install.sh ] && rm -rf /mnt/main_install.sh
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
################################ Smart Home 选择 ################################
SmartHome_choose() {
    clear
    rm -rf /mnt/main_install.sh
    echo "=================================================================="
    echo -e "\t\t智能家居系列脚本 by 忧郁滴飞叶"
    echo -e "\t\n"
    white "${yellow}特别说明：\n本系列脚本涉及docker、docker-compose等附加程序安装及使用，\n需具备一定基础，出现错误后进行查错、纠错。${reset}"    
    echo -e "\n请选择服务："
    echo "=================================================================="
    white "1. 安装FunAsr（本地语音转文字模型）${yellow}[硬盘大小需16G以上]${reset}"
    white "2. DDNS脚本"    
    echo -e "\t" 
    echo "-. 返回上级菜单"    
    echo "0. 退出脚本"
    read -p "请选择服务: " choice
    case $choice in
        1)
            funasr_customize_settings
            basic_settings
            docker_install
            funasr_install
            funasr_download_model
            funasr_over
            ;;
        2)
            DDNS_setting
            DDNS_install
            ;;    
        0)
            red "退出脚本，感谢使用."
            [ -f /mnt/smarthome.sh ] && rm -rf /mnt/smarthome.sh    #delete 
            ;;
        -)
            white "脚本切换中，请等待..."
            [ -f /mnt/smarthome.sh ] && rm -rf /mnt/smarthome.sh    #delete 
            wget -q -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
            ;;
        *)
            white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            SmartHome_choose
            ;;
    esac 
}
################################ 基础环境设置 ################################
basic_settings() {
    white "配置基础设置并安装依赖..."
    sleep 1
    apt-get update -y && apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" || { red "环境更新失败！退出脚本"; exit 1; }
    green "环境更新成功"
    white "环境依赖安装开始..."
    apt install wget curl vim jq -y || { red "依赖安装失败！退出脚本"; exit 1; }
    green "依赖安装成功"
    timedatectl set-timezone Asia/Shanghai || { red "时区设置失败！退出脚本"; exit 1; }
}
################################ docker 基础环境安装 ################################
docker_install() {
    white "开始安装docker..."
    wget -qO- get.docker.com | bash

    white "设置开机启动docker..."     
    systemctl enable docker --now
    if ! systemctl is-active --quiet docker; then
        red "docker安装失败！退出脚本."
        [ -f /mnt/smarthome.sh ] && rm -rf /mnt/smarthome.sh    #delete     
        exit 1
    fi
    green "docker程序安装完成"

    white "开始按用户设定限制docker日志大小..." 
    if ! command -v jq &> /dev/null; then
        white "部分依赖未安装，安装依赖..."
        apt install jq -y
    fi

    TMP_FILE=$(mktemp)
cat > $TMP_FILE <<EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "${LOG_SIZE}m",
        "max-file": "3"
    }
}
EOF
    # 备份现有的 daemon.json
    if [ ! -d /etc/docker ]; then
        white "/etc/docker 文件夹不存在，正在创建..."
        mkdir -p /etc/docker
    else
        white "开始添加配置..."
    fi
    if [ -f /etc/docker/daemon.json ]; then
        sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak
    else
        echo "{}" | sudo tee /etc/docker/daemon.json > /dev/null
    fi
    if [ ! -s /etc/docker/daemon.json ]; then
        echo "{}" | sudo tee /etc/docker/daemon.json > /dev/null
    fi
    white "正在合并配置..."
    MERGED_FILE=$(mktemp)
    jq -s 'add' /etc/docker/daemon.json $TMP_FILE | sudo tee $MERGED_FILE > /dev/null
    if [ $? -ne 0 ]; then
        red "合并时发生错误，请检查 JSON 格式是否正确。"
        cp /etc/docker/daemon.json.bak /etc/docker/daemon.json
        [ -f /mnt/smarthome.sh ] && rm -rf /mnt/smarthome.sh    #delete    
        exit 1
    fi    
    mv $MERGED_FILE /etc/docker/daemon.json
    rm $TMP_FILE
    chmod 644 /etc/docker/daemon.json
    systemctl daemon-reload
    systemctl restart docker
    green "docker日志大小限定设置完成"

    white "开始安装docker-compose..."
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    if docker-compose --version 2>&1 | grep -q 'command not found'; then
        red "docker-compose未安装！退出脚本"
        [ -f /mnt/smarthome.sh ] && rm -rf /mnt/smarthome.sh  # 删除文件
        exit 1
    else
        docker-compose --version
    fi
    green "docker-compose安装完成"
}

################################funasr用户自定义设置################################
funasr_customize_settings() {
    # 读取用户输入的docker日志文件最大大小
    while true; do
        read -p "请输入docker日志文件的最大大小（单位m，例如：20、50等，默认20）： " LOG_SIZE
        LOG_SIZE="${LOG_SIZE:-20}"
        if [[ $LOG_SIZE =~ ^[0-9]+$ ]]; then
            break
        else
            red "日志文件的大小格式输入不正确，请重新输入"
        fi
    done

    # 读取用户输入的docker funasr映射端口，默认80
    while true; do
        read -p "请输入docker容器funasr映射的主机端口（默认80）: " funasrport
        funasrport="${funasrport:-80}"
        if [[ $funasrport =~ ^[0-9]+$ ]]; then
            break
        else
            red "端口号格式不正确，请重新输入"
        fi
    done

    # 读取用户输入的docker funasr映射路径
    while true; do
        read -p "请输入docker容器funasr安装映射的主机路径：（示例：/mnt/docker/funasr，文件夹后无需输入“/”，默认为示例路径） " funasr_models_path
        funasr_models_path="${funasr_models_path:-/mnt/docker/funasr}"
        
        if [[ $funasr_models_path =~ ^/[a-zA-Z0-9/]*$ ]]; then
            break  
        else
           red "输入docker容器funasr models文件夹映射的主机路径格式不正确，请正确路径"
        fi
    done

    # 读取用户选定的语音模型，默认选项为3
    while true; do
        white "请根据描述选择语音识别模型，语音模型越大，识别率越高，识别时间越长，综合考虑后选择模型："
        white "1. faster-tiny（不足100MB）"
        white "2. faster-base（150MB左右）"
        white "3. faster-small（500MB左右）"
        white "4. faster-medium（1.5GB左右）"
        read -p "请输入选定的语音模型（默认3）: " funasr_models_num
        funasr_models_num="${funasr_models_num:-3}"
        if [[ $funasr_models_num =~ ^[1-4]$ ]]; then
            break
        else
            red "输入选定的语音模型号码不正确，请重新输入"
        fi
    done
    case $funasr_models_num in
        1) funasr_models_name="faster-tiny" ;;
        2) funasr_models_name="faster-base" ;;
        3) funasr_models_name="faster-small" ;;
        4) funasr_models_name="faster-medium" ;;
    esac

    clear
    white "参数设定如下："
    white "您设定docker日志文件的最大大小为：${yellow}${LOG_SIZE}MB${reset}"
    white "您设定docker容器funasr映射的主机端口是: ${yellow}${funasrport}${reset}"
    white "您设定的docker容器funasr安装映射的主机路径为：${yellow}${funasr_models_path}${reset}"
    white "您选定的语音模型为：${yellow}${funasr_models_name}${reset}"
    white "\n"
}

################################ 安装 FunAsr ################################
funasr_install() {
    mkdir -p $funasr_models_path
    if [ ! -d "$funasr_models_path" ]; then
        red "未检测到 docker容器funasr文件夹，请检查文件夹是否存在，退出脚本"
        [ -f /mnt/smarthome.sh ] && rm -rf /mnt/smarthome.sh    #delete         
        exit 1
    else
        cd $funasr_models_path
        mkdir ./models
        if [ ! -d "$funasr_models_path/models" ]; then
        red "未检测到 docker容器funasr/models文件夹，请检查文件夹是否存在，退出脚本"
        [ -f /mnt/smarthome.sh ] && rm -rf /mnt/smarthome.sh    #delete         
        exit 1
        fi
cat << 'EOF' > docker-compose.yml
version: '3'
services:
    fun-asr:
        image: 'yaming116/fun-asr'
        volumes:
            - 'funasr_models_path/models:/models'
        container_name: fun-asr
        hostname: fun-asr
        ports:
            - 'funasrport:5001'
        tty: true
        stdin_open: true
        restart: always
EOF
        sed -i "s|funasr_models_path/models:/models|${funasr_models_path}/models:/models|g" $funasr_models_path/docker-compose.yml
        sed -i "s|funasrport:5001|${funasrport}:5001|g" $funasr_models_path/docker-compose.yml
        
        cd $funasr_models_path
        docker-compose up -d

        white "正在获取FunAsr容器运行状态，请等待..."
        sleep 1
        container_status=$(docker ps --filter "name=fun-asr" --filter "status=running" --format "{{.Names}}")
        if [ "$container_status" != "fun-asr" ]; then
            red "FunAsr容器未正常运行，请检查容器安装情况"
            [ -f /mnt/smarthome.sh ] && rm -rf /mnt/smarthome.sh    #delete                
            exit 1
        else
            green "FunAsr容器已正常正常运行，安装完成"
        fi
    fi   
}

################################ FunAsr 下载语音模型 ################################
funasr_download_model() {
    white "开始下载用户指定语音模型..."
    wget --quiet --show-progress -O $funasr_models_path/$funasr_models_name.7z https://github.com/jianchang512/stt/releases/download/0.0/$funasr_models_name.7z

    if ! dpkg -l | grep -q p7zip-full; then
        white "p7zip 未安装，正在安装..."
        apt update
        apt install -y p7zip-full
        if ! dpkg -l | grep -q p7zip-full; then
            red "p7zip 安装失败，请检查网络或包管理器设置。"
            exit 1
        else
            white "p7zip 安装成功"
        fi
    else
        white "p7zip 已安装"
    fi

    mkdir /mnt/moxing
    if [ ! -d "/mnt/moxing" ]; then
        red "未检测到 /mnt/moxing文件夹，请检查文件夹是否存在，退出脚本"
        [ -f /mnt/smarthome.sh ] && rm -rf /mnt/smarthome.sh    #delete         
        exit 1
    fi    
    YINFILE=$funasr_models_path/$funasr_models_name.7z
    YIN_DEST_DIR="/mnt/moxing"
    if [ -f "$YINFILE" ]; then
        white "正在解压 $YINFILE 到 $YIN_DEST_DIR..."
        7z x "$YINFILE" -o"$YIN_DEST_DIR"
        # 验证解压目录是否有文件或文件夹
        if [ -z "$(ls -A "$YIN_DEST_DIR")" ]; then
            red "解压失败，YIN_DEST_DIR 目录为空，请检查文件"
            [ -f /mnt/smarthome.sh ] && rm -rf /mnt/smarthome.sh    #delete     
            exit 1
        fi
        
        if [ $? -eq 0 ]; then
            white "语音模型解压成功"
            if [ -d "$funasr_models_path/models" ]; then
                white "正在移动文件到 $funasr_models_path/models..."
                mv "$YIN_DEST_DIR"/* "$funasr_models_path/models/"
                
                if [ $? -eq 0 ]; then
                    white "文件已成功移动到 $funasr_models_path/models。"
                else
                    red "移动文件时出错，请检查目标文件夹。"
                    [ -f /mnt/smarthome.sh ] && rm -rf /mnt/smarthome.sh    #delete      
                    exit 1
                fi
            else
                red "目标文件夹 $funasr_models_path/models 不存在，请检查路径。"
                [ -f /mnt/smarthome.sh ] && rm -rf /mnt/smarthome.sh    #delete                     
                exit 1
            fi
        else
            red "解压失败，请检查文件或磁盘空间"
            [ -f /mnt/smarthome.sh ] && rm -rf /mnt/smarthome.sh    #delete      
            exit 1
        fi
    else
        red "文件 $YINFILE 不存在，请检查路径。"
        [ -f /mnt/smarthome.sh ] && rm -rf /mnt/smarthome.sh    #delete      
        exit 1
    fi

    green "本地语音模型安装完毕"
}

##################################### DDNS 用户自定义########################################
DDNS_setting(){
    clear
    white "${yellow}温馨提示：\n本脚本需先行在DnsPod（腾讯云）建立解析域名，完成后方可正常运行脚本！！！${reset}\n"
    while true; do
        white "请输入DDNS域名解析运营商："
        white "1. ${yellow}DnsPod${reset}（腾讯云）"
        read -p "请选择（默认1）: " ddns_choose_for_all
        ddns_choose_for_all="${ddns_choose_for_all:-1}"
        if [[ $ddns_choose_for_all =~ ^[1-3]$ ]]; then
            break
        else
            red "输入选定的版本数字不正确，请重新输入"
        fi
    done
    case $ddns_choose_for_all in
        1) ddns_choose_for_all_name="DnsPod（腾讯云）" ;;
    esac

    while true; do
    read -p "请输入DNSPod Token（非腾讯云 API 密钥） (格式：ID,Token): " DDNS_token
    if [[ "$DDNS_token" =~ ^[A-Za-z0-9]+,[A-Za-z0-9]+$ ]]; then
        break
    else
        echo "无效的格式，请确保格式为 'ID,Token'，且内容只能包含字母和数字"
    fi
    done

    while true; do
        read -p "请输入主域名 (例如：yourdomain.com): " DDNS_domain
        if [[ "$DDNS_domain" =~ ^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        break
        else
        red "无效的域名格式，请重新输入"
        fi
    done

    while true; do
    read -p "请输入子域名 (例如：www): " DDNS_subdomain
    if [[ "$DDNS_subdomain" =~ ^[A-Za-z0-9]+$ ]]; then
        break
    else
        echo "无效的子域名格式，请重新输入"
    fi
    done
    DDNS_ALL_DOMAIN=$DDNS_subdomain.$DDNS_domain

    clear
    white "您设定的参数："
    white "DDNS所在运营商：${yellow}$ddns_choose_for_all_name${reset}"
    white "DDNS域名：${yellow}$DDNS_ALL_DOMAIN${reset}"
    white "Token：${yellow}$DDNS_token${reset}"

}
##################################### DDNS 配置脚本及定时 ########################################
DDNS_install() {
    mkdir -p /mnt/ddns

    DDNS_logfile="/mnt/ddns/log.txt"

    DDNS_recordid=$(curl -s -X POST "https://dnsapi.cn/Record.List" \
        -d "login_token=$DDNS_token&format=json&domain=$DDNS_domain" | \
        jq -r ".records[] | select(.name == \"$DDNS_subdomain\") | .id")

    if [[ -z "$DDNS_recordid" ]]; then
        echo "无法获取记录ID，请检查您的Token、域名和子域名" | tee -a $DDNS_logfile
        [ -f /mnt/smarthome.sh ] && rm -rf /mnt/smarthome.sh    #delete 
        exit 1
    fi

    case $ddns_choose_for_all in
        1) wget --quiet --show-progress -O /mnt/ddns/DDNS.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/ddns/dnspod.sh ;;
    esac

    sed -i "s|DDNS_ALL_DOMAIN|${DDNS_ALL_DOMAIN}|g" /mnt/ddns/DDNS.sh
    sed -i "s|DDNS_token|${DDNS_token}|g" /mnt/ddns/DDNS.sh
    sed -i "s|DDNS_domain|${DDNS_domain}|g" /mnt/ddns/DDNS.sh
    sed -i "s|DDNS_subdomain|${DDNS_subdomain}|g" /mnt/ddns/DDNS.sh
    sed -i "s|DDNS_recordid|${DDNS_recordid}|g" /mnt/ddns/DDNS.sh
    chmod +x /mnt/ddns/DDNS.sh
    green "脚本已创建完成"

    (crontab -l 2>/dev/null; echo "*/5 * * * * /mnt/ddns/DDNS.sh") | crontab -

    green "已设置定时任务，每5分钟更新一次IP"

    case $ddns_choose_for_all in
        1) dnspod_over ;;
    esac
}

dnspod_over() {    
    echo "=================================================================="
    echo -e "\t\tDDNS DnsPod（腾讯云）配置完毕"
    echo -e "\n"
    echo -e "脚本运行目录\n${yellow}/mnt/ddns${reset}"
    echo -e "更近日志目录\n${yellow}${DDNS_logfile}${reset}"    
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证"
    echo "=================================================================="
}

################################ FunAsr 结束语 ################################
funasr_over() {
    cd $funasr_models_path 
    docker-compose restart
    rm -rf $funasr_models_name.7z
    rm -rf /mnt/moxing
    local_ip=$(hostname -I | awk '{print $1}')
    echo "=================================================================="
    echo -e "\t\tFunAsr（本地语音转文字模型）安装完毕"
    echo -e "\n"
    echo -e "FunAsr运行目录\n${yellow}${funasr_models_path}${reset}"
    echo -e "FunAsr API 地址\n${yellow}http://$local_ip:$funasrport${reset}"
    echo -e "华为测试音频链接：\n${yellow}https://sis-sample-audio.obs.cn-north-1.myhuaweicloud.com/16k16bit.mp3${reset}"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，模型\n配置启动预计需要${yellow}5分钟${reset}左右时间，请耐心等待。如${yellow}5分钟${reset}后仍未\n启动成功，请进入FunAsr运行目录通过${yellow}docker-compose logs${reset}命令\n查看日志"
    echo "=================================================================="
}

################################ 主程序 ################################
SmartHome_choose