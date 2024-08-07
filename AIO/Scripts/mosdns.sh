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

################################ MosDNS选择 ################################
mosdns_choose() {
    clear
    echo "=================================================================="
    echo -e "\t\tMosDNS相关脚本 by 忧郁滴飞叶"
    echo -e "\t\n"  
    echo "请选择要执行的服务："
    echo "=================================================================="
    echo "1. 安装Mosdns"
    echo "2. 重置Mosdns缓存"
    echo "3. 安装Mosdns UI"
    echo "4. 卸载Mosdns"
    echo "5. 卸载Mosdns UI"
    echo -e "\t"
    echo "8. 一键安装Mosdns及UI面板"
    echo "9. 一键卸载Mosdns及UI面板"
    echo "-. 返回上级菜单"          
    echo "0) 退出脚本"        
    read choice
    case $choice in
        1)
            echo "安装Mosdns"
            install_mosdns
            ;;
        2)
            echo "重置Mosdns缓存"
            del_mosdns_cache || exit 1
            ;;        
        3)
            echo "安装Mosdns UI"
            install_mosdns_ui
            ;;
        4)
            echo "卸载Mosdns"
            del_mosdns || exit 1
            rm -rf /mnt/mosdns.sh    #delete                
            ;;
        5)
            echo "卸载Mosdns UI"
            del_mosdns_ui || exit 1
            rm -rf /mnt/mosdns.sh    #delete                 
            ;;
        8)
            echo "一键安装Mosdns及UI面板"
            install_mosdns_ui_all
            ;;
        9)
            echo "一键卸载Mosdns及UI面板"
            del_mosdns || exit 1
            del_mosdns_ui || exit 1
            rm -rf /mnt/mosdns.sh    #delete                
            ;;
        0)
            echo -e "\e[31m退出脚本，感谢使用.\e[0m"
            rm -rf /mnt/mosdns.sh    #delete             
            ;;
        -)
            echo "脚本切换中，请等待..."
            rm -rf /mnt/mosdns.sh    #delete       
            wget -q -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
            ;;                            
        *)
            echo "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            /mnt/mosdns.sh
            ;;
    esac
}
################################安装 mosdns################################
install_mosdns() {
    mkdir /mnt/mosdns && cd /mnt/mosdns
    local mosdns_host="https://github.com/IrineSistiana/mosdns/releases/download/v5.3.1/mosdns-linux-amd64.zip"
    mosdns_customize_settings || exit 1
    basic_settings || exit 1
    download_mosdns || exit 1
    extract_and_install_mosdns || exit 1
    configure_mosdns || exit 1
    enable_autostart || exit 1
    install_complete
}
################################ MosDNS及UI一键 ################################
install_mosdns_ui_all() {
    echo "开始安装MosDNS ..."   
    mkdir /mnt/mosdns && cd /mnt/mosdns
    local mosdns_host="https://github.com/IrineSistiana/mosdns/releases/download/v5.3.1/mosdns-linux-amd64.zip"
    mosdns_customize_settings || exit 1
    basic_settings || exit 1
    download_mosdns || exit 1
    extract_and_install_mosdns || exit 1
    configure_mosdns || exit 1
    enable_autostart || exit 1
    systemctl restart mosdns
    echo "开始安装MosDNS UI..."    
    install_loki || exit 1
    install_vector || exit 1
    install_prometheus || exit 1
    install_grafana || exit 1
    install_complete_all
}
################################用户自定义设置################################
mosdns_customize_settings() {
    echo -e "\n自定义设置（以下设置可直接回车使用默认值）"
    read -p "输入sing-box入站地址：端口（默认10.10.10.2:6666）：" uiport
    uiport="${uiport:-10.10.10.2:6666}"
    echo -e "已设置Singbox入站地址：\e[1m\e[33m$uiport\e[0m"
    read -p "输入国内DNS解析地址：端口（默认223.5.5.5:53）：" localport
    localport="${localport:-223.5.5.5:53}"
    echo -e "已设置国内DNS地址：\e[1m\e[33m$localport\e[0m"
}
################################ 基础环境设置 ################################
basic_settings() {
    echo -e "配置基础设置并安装依赖..."
    sleep 1
    apt update -y
    apt -y upgrade || { echo "\n\e[1m\e[37m\e[41m环境更新失败！退出脚本\e[0m\n"; exit 1; }
    echo -e "\n\e[1m\e[37m\e[42m环境更新成功\e[0m\n"
    echo -e "环境依赖安装开始..."
    apt install curl wget tar gawk sed cron unzip nano sudo vim sshfs net-tools nfs-common bind9-host adduser libfontconfig1 musl git build-essential libssl-dev libevent-dev zlib1g-dev gcc-mingw-w64 -y || { echo -e "\n\e[1m\e[37m\e[41m环境依赖安装失败！退出脚本\e[0m\n"; exit 1; }
    echo -e "\n\e[1m\e[37m\e[42mmosdns依赖安装成功\e[0m\n"
    timedatectl set-timezone Asia/Shanghai || { echo -e "\n\e[1m\e[37m\e[41m时区设置失败！退出脚本\e[0m\n"; exit 1; }
    echo -e "\n\e[1m\e[37m\e[42m时区设置成功\e[0m\n"
    ntp_config="NTP=ntp.aliyun.com"
    echo "$ntp_config" | sudo tee -a /etc/systemd/timesyncd.conf > /dev/null
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-timesyncd
    echo -e "\n\e[1m\e[37m\e[42m已将 NTP 服务器配置为 ntp.aliyun.com\e[0m\n"
    sed -i '/^#*DNSStubListener/s/#*DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf || { echo -e "\n\e[1m\e[37m\e[41m关闭53端口监听失败！退出脚本\e[0m\n"; exit 1; }
    systemctl restart systemd-resolved.service || { echo -e "\n\e[1m\e[37m\e[41m重启 systemd-resolved.service 失败！退出脚本\e[0m\n"; exit 1; }
    echo -e "\n\e[1m\e[37m\e[42m关闭53端口监听成功\e[0m\n"
}    
################################下载 mosdns################################
download_mosdns() {
    echo "开始下载 mosdns v5.3.1"
    wget "${mosdns_host}" || { echo -e "\n\e[1m\e[37m\e[41m下载失败！退出脚本\e[0m\n"; exit 1; }
}
################################解压并安装 mosdns################################
extract_and_install_mosdns() {
    echo "开始安装MosDNS..."
    unzip mosdns-linux-amd64.zip -d /etc/mosdns
    cd /etc/mosdns
    chmod +x mosdns
    cp mosdns /usr/local/bin
    cd /etc/systemd/system/
    touch mosdns.service
cat << 'EOF' > mosdns.service
[Unit]
Description=mosdns daemon, DNS server.
After=network-online.target

[Service]
Type=simple
Restart=always
ExecStart=/usr/local/bin/mosdns start -c /etc/mosdns/config.yaml -d /etc/mosdns

[Install]
WantedBy=multi-user.target
EOF

    echo -e "\n\e[1m\e[37m\e[42mMosDNS服务已安装完成\e[0m\n"
}
################################# 配置 mosdns ################################
configure_mosdns() {
    echo "开始配置MosDNS规则..."
    mkdir /etc/mosdns/rule
    cd /etc/mosdns/rule
    wget -q -O /etc/mosdns/rule/blocklist.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mos_rule/blocklist.txt
    wget -q -O /etc/mosdns/rule/localptr.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mos_rule/localptr.txt
    wget -q -O /etc/mosdns/rule/greylist.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mos_rule/greylist.txt
    wget -q -O /etc/mosdns/rule/whitelist.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mos_rule/whitelist.txt
     wget -q -O /etc/mosdns/rule/ddnslist.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mos_rule/ddnslist.txt
    wget -q -O /etc/mosdns/rule/hosts.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mos_rule/hosts.txt
    wget -q -O /etc/mosdns/rule/redirect.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mos_rule/redirect.txt
    wget -q -O /etc/mosdns/rule/adlist.txt https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mos_rule/adlist.txt
    echo -e "\n\e[1m\e[37m\e[42m所有规则文件修改操作已完成\e[0m\n"
    echo "开始配置MosDNS config文件..."
    rm -rf /etc/mosdns/config.yaml
    wget -q -O /etc/mosdns/config.yaml https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mosdns.yaml
    sed -i "s/- addr: 10.10.10.2:6666/- addr: ${uiport}/g" /etc/mosdns/config.yaml
    sed -i "s/- addr: 223.5.5.5:53/- addr: ${localport}/g" /etc/mosdns/config.yaml
    echo -e "\n\e[1m\e[37m\e[42mMosDNS config文件已配置完成\e[0m\n"    
    echo "开始配置定时更新规则与清理日志..."
    cd /etc/mosdns
    touch {geosite_cn,geoip_cn,geosite_geolocation_noncn,gfw}.txt
    wget -q -O /etc/mosdns/mos_rule_update.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/mos_rule_update.sh
    chmod +x mos_rule_update.sh
    ./mos_rule_update.sh
    (crontab -l 2>/dev/null; echo "0 0 * * 0 sudo truncate -s 0 /etc/mosdns/mosdns.log && /etc/mosdns/mos_rule_update.sh") | crontab -
    echo -e "\n\e[1m\e[37m\e[42m定时更新规则与清理日志添加完成\e[0m\n"
}
################################ 开机自启动 服务 ################################
enable_autostart() {
    echo "设置mosdns开机自启动"
    # 启用并立即启动 mosdns 服务
    systemctl enable mosdns --now
    echo -e "\n\e[1m\e[37m\e[42mmosdns开机启动完成\e[0m\n"
}
################################ 重置Mosdns缓存 ################################
del_mosdns_cache() {
    echo "停止MosDNS并开始删除MosDNS缓存"
    systemctl stop mosdns && rm -f /etc/mosdns/cache.dump
    sleep 1
    echo "重载配置并启动MosDNS"    
    systemctl daemon-reload && systemctl start mosdns
    echo -e "\n\e[1m\e[37m\e[42mMosdns缓存已重置\e[0m\n"
    sleep 1
}
################################ Mosdns UI安装 ################################
install_mosdns_ui() {
    echo "开始安装MosDNS UI..."    
    basic_settings || exit 1
    install_loki || exit 1
    install_vector || exit 1
    install_prometheus || exit 1
    install_grafana || exit 1
    install_complete_ui
}
################################ Loki 安装 ################################
install_loki() {
    echo "开始安装Loki..."
    mkdir /mnt/ui && cd /mnt/ui
    wget https://github.com/grafana/loki/releases/download/v3.1.0/loki_3.1.0_amd64.deb
    dpkg -i loki_3.1.0_amd64.deb
    systemctl enable loki --now
    echo -e "\n\e[1m\e[37m\e[42mLoki已安装完成\e[0m\n"
}
################################ Vector 安装 ################################
install_vector() {
    echo "开始安装Vector..."
    cd /mnt/ui
    curl --proto '=https' --tlsv1.2 -sSfL https://sh.vector.dev | bash -s -- -y
    rm -rf /root/.vector/config/vector.yaml
    wget -q -O /root/.vector/config/vector.yaml https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/vector.yaml
    cd /etc/systemd/system/
    touch vector.service
cat << 'EOF' > vector.service
[Unit]
Description=Vector Service
After=network.target

[Service]
Type=simple
User=root
ExecStartPre=/bin/sleep 10
ExecStartPre=/bin/mkdir -p /tmp/vector
ExecStart=/root/.vector/bin/vector --config /root/.vector/config/vector.yaml
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable vector --now
    echo -e "\n\e[1m\e[37m\e[42mVector已安装完成\e[0m\n"
}
################################ Prometheus 安装 ################################
install_prometheus() {
    echo "开始安装Prometheus..."
    sudo apt-get install -y prometheus
# 添加 mosdns 任务配置
cat << EOF | sudo tee -a /etc/prometheus/prometheus.yml
  - job_name: mosdns
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:8338']
EOF
    # 重启 Prometheus
    sudo systemctl enable prometheus --now
    sudo systemctl restart prometheus
    echo -e "\n\e[1m\e[37m\e[42mPrometheus已安装完成\e[0m\n"
}
################################ Grafana 安装 ################################
install_grafana() {
    echo "开始安装Grafana..."
    cd /mnt/ui
    wget https://dl.grafana.com/enterprise/release/grafana-enterprise_11.0.0_amd64.deb
    sudo dpkg -i grafana-enterprise_11.0.0_amd64.deb
    # 重新加载 systemd 并启用/启动 Grafana 服务器
    sudo systemctl daemon-reload
    sudo systemctl enable grafana-server
    sudo systemctl start grafana-server
    # 确认 Grafana 服务器状态
    if systemctl is-active --quiet grafana-server; then
        echo -e "\n\e[1m\e[37m\e[42mGrafana已安装并成功启动\e[0m\n"
    else
        echo -e "\n\e[1m\e[37m\e[41mGrafana安装失败或未能启动\e[0m\n" || exit 1
    fi
}
################################ 卸载Mosdns ################################
del_mosdns() {
    echo "停止MosDNS服务并删除"
    sudo systemctl stop mosdns || exit 1
    sudo systemctl disable mosdns || exit 1
    sudo rm /etc/systemd/system/mosdns.service || exit 1
    sudo rm -r /etc/mosdns || exit 1
    (crontab -l 2>/dev/null | grep -v 'truncate -s 0 /etc/mosdns/mosdns.log && /etc/mosdns/mos_rule_update.sh') | crontab - || exit 1
    echo -e "\n\e[1m\e[37m\e[42m卸载Mosdns已完成\e[0m\n"
}
################################ 卸载Mosdns UI ################################
del_mosdns_ui() {
    echo "停止MosDNS UI服务并删除"
    sudo systemctl stop loki
    sudo systemctl disable loki
    sudo dpkg -r loki
    sudo rm -rf /etc/loki /var/lib/loki /var/log/loki
    sudo find /etc/systemd /lib/systemd /run/systemd -name 'loki.service' -exec sudo rm {} \;
    sudo systemctl stop vector
    sudo systemctl disable vector
    sudo rm -rf /root/.vector
    sudo rm /etc/systemd/system/vector.service
    sudo rm -rf /root/.vector/config/vector.yaml
    sudo systemctl stop prometheus
    sudo systemctl disable prometheus
    sudo apt-get remove --purge -y prometheus
    sudo rm -rf /etc/prometheus /var/lib/prometheus
    sudo rm -rf /usr/bin/prometheus
    sudo rm -rf /usr/bin/prometheus-node-exporter
    sudo rm /lib/systemd/system/prometheus-node-*
    sudo rm /etc/systemd/system/multi-user.target.wants/prometheus-node-*
    sudo systemctl stop grafana-server
    sudo systemctl disable grafana-server
    sudo dpkg -r grafana-enterprise
    sudo rm -rf /etc/grafana /var/lib/grafana /var/log/grafana
    sudo rm /lib/systemd/system/grafana-server.service
    sudo rm /etc/systemd/system/grafana-server.service
    sudo rm /etc/systemd/system/multi-user.target.wants/grafana-server.service
    sudo rm /etc/init.d/grafana-server
    sudo systemctl daemon-reload
    sudo systemctl reset-failed
    echo -e "\n\e[1m\e[37m\e[42m卸载Mosdns UI已完成\e[0m\n"
}
################################ Mosdns安装结束 ################################
install_complete() {
    systemctl restart mosdns
    sudo rm -r /mnt/mosdns || exit 1
    rm -rf /mnt/mosdns.sh    #delete       
echo "=================================================================="
echo -e "\t\tMosdns 安装完成"
echo -e "\n"
echo -e "Mosdns运行目录为\e[1m\e[33m/etc/mosdns\e[0m"
echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，已查\n询程序运行状态，如出现\e[1m\e[32m active (running)\e[0m，程序已启动成功。\n网关自行配置为sing-box，dns为Mosdns地址"
echo "=================================================================="
systemctl status mosdns
}
################################ Mosdns UI 安装结束 ################################
install_complete_ui() {
    systemctl restart loki
    systemctl restart vector
    systemctl restart prometheus
    systemctl restart grafana-server
    sudo rm -r /mnt/ui || exit 1
    local_ip=$(hostname -I | awk '{print $1}')
    rm -rf /mnt/mosdns.sh    #delete       
echo "=================================================================="
echo -e "\t\tMosdns UI 安装完成"
echo -e "\n"
echo -e "请打开：\e[1m\e[33mhttp://$local_ip:3000\e[0m,进入ui管理界面，默认账号及密码均为\e[1m\e[33madmin\e[0m"
echo "=================================================================="
}
################################ Mosdns 一键安装结束 ################################
install_complete_all() {
    systemctl restart mosdns
    sudo rm -r /mnt/mosdns || exit 1
    systemctl restart loki
    systemctl restart vector
    systemctl restart prometheus
    systemctl restart grafana-server
    sudo rm -r /mnt/ui || exit 1
    local_ip=$(hostname -I | awk '{print $1}')
    rm -rf /mnt/mosdns.sh    #delete       
echo "=================================================================="
echo -e "\t\tMosdns及UI一键安装完成"
echo -e "\n"
echo -e "Mosdns运行目录为\e[1m\e[33m/etc/mosdns\e[0m"
echo -e "请打开：\e[1m\e[33mhttp://$local_ip:3000\e[0m,进入ui管理界面，默认账号及密码均为：\n\e[1m\e[33madmin\e[0m"
echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，已查\n询程序运行状态，如出现\e[1m\e[32m active (running)\e[0m，程序已启动成功。\n网关自行配置为sing-box，dns为Mosdns地址"
echo "=================================================================="
systemctl status mosdns
}
################################ 主程序 ################################
mosdns_choose