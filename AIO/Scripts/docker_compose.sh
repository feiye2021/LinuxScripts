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
yellow_minute='\e[33m'
green_minute='\e[32m'
reset='\e[0m'
white(){
    echo -e "$1"
}
################################ docker-compose 选择 ################################
docker_compose_choose() {
    clear
    rm -rf /mnt/main_install.sh
    white "=================================================================="
    echo -e "\t\tDocker-compose配置生成脚本 by 忧郁滴飞叶"
    echo -e "\t\n"
    white "请选择要生成的容器配置："
    white "=================================================================="
    white "1.${yellow_minute}filebrower${reset}-${green_minute}文件管理器，荒野无灯大佬版（增强版）${reset}"
    white "2.${yellow_minute}dockercopilot${reset}-${green_minute}docker容器批量一键更新(除了个别)${reset}"
    white "3.${yellow_minute}adminer${reset}-${green_minute}数据库管理工具${reset}"
    white "4.${yellow_minute}alist${reset}-${green_minute}网盘聚合挂载神器${reset}"
    white "5.${yellow_minute}amilys${reset}-${green_minute}embyserver-emby开心版${reset}"
    white "6.${yellow_minute}bili-sync-rs${reset}-${green_minute}B站视频收藏夹同步到本地${reset}"    
    white "7.${yellow_minute}apachewebdav${reset}-${green_minute}基于Apache的非常简单的WebDAV服务器${reset}"
    white "8.${yellow_minute}clouddrive2${reset}-${green_minute}挂载网盘到本地虚拟文件${reset}"
    white "9.${yellow_minute}cloudflared-web${reset}-${green_minute}cf可供免费的内网穿透${reset}"
    white "10.${yellow_minute}watchtower${reset}-${green_minute}瞭望塔，自动更新docker容器${reset}"
    white "11.${yellow_minute}cookiecloud${reset}-${green_minute}cookie云备份${reset}"
    white "12.${yellow_minute}ddns-go${reset}-${green_minute}DDNS域名解析${reset}"
    white "13.${yellow_minute}kms-server${reset}-${green_minute}kms激活器${reset}"
    white "14.${yellow_minute}dockge${reset}-${green_minute}轻量级docker管理器，带docker命令行部署转compose${reset}"
    white "15.${yellow_minute}grafana-enterprise${reset}-${green_minute}全面定制面板。观察所有数据${reset}"
    white "16.${yellow_minute}squoosh${reset}-${green_minute}在线图片压缩${reset}"
    white "17.${yellow_minute}embyserver${reset}-${green_minute}综合最强的媒体库(官网版)${reset}"
    white "18.${yellow_minute}filecodebox${reset}-${green_minute}文件快递柜，简洁易用的文件分享平台，无需注册即可匿名分享文件和文本${reset}"
    white "19.${yellow_minute}hedgedoc${reset}-${green_minute}多人协同在线markdown${reset}"
    white "20.${yellow_minute}homarr${reset}-${green_minute}龙虾导航页${reset}"
    white "21.${yellow_minute}homepage${reset}-${green_minute}高度可定制的应用程序仪表板导航页${reset}"
    white "22.${yellow_minute}rustdesk${reset}-${green_minute}aio-远程桌面${reset}"
    white "23.${yellow_minute}iptv-tool${reset}-${green_minute}IPTV工具箱${reset}"
    white "24.${yellow_minute}it-tools${reset}-${green_minute}在线it工具箱${reset}"
    white "25.${yellow_minute}iyuuplus-dev${reset}-${green_minute}集成webui界面、辅种、转移、下载、定时访问URL、动态域名ddns等常用功能，提供完善的插件机制${reset}"
    white "26.${yellow_minute}jellyseerr${reset}-${green_minute}支持PEJ的媒体库选片系统${reset}"
    white "27.${yellow_minute}drawio${reset}-${green_minute}思维导图，拓扑图${reset}"
    white "28.${yellow_minute}kodbox${reset}-${green_minute}可道云私有云，支持协同办公${reset}"
    white "29.${yellow_minute}libretranslate${reset}-${green_minute}翻译${reset}"
    white "30.${yellow_minute}li-calendar${reset}-${green_minute}日历记事本${reset}"
    white "31.${yellow_minute}calibre-web${reset}-${green_minute}电子书库${reset}"
    white "32.${yellow_minute}duplicati${reset}-${green_minute}开源、可加密、压缩、增量备份的跨平台数据备份工具${reset}"
    white "33.${yellow_minute}embystat${reset}-${green_minute}emby&jf的数据统计${reset}"
    white "34.${yellow_minute}emulatorjs${reset}-${green_minute}在线掌机模拟器${reset}"
    white "35.${yellow_minute}firefox${reset}-${green_minute}火狐浏览器${reset}"
    white "36.${yellow_minute}jackett${reset}-${green_minute}站点索引器${reset}"
    white "37.${yellow_minute}kavita${reset}-${green_minute}电子书库${reset}"
    white "38.${yellow_minute}librespeed${reset}-${green_minute}轻量级的测速工具${reset}"
    white "39.${yellow_minute}lidarr${reset}-${green_minute}音乐收藏管理器${reset}"
    white "40.${yellow_minute}lychee${reset}-${green_minute}图册，只能导入不能扫本地${reset}"
    white "41.${yellow_minute}mariadb${reset}-${green_minute}海豚数据库，关系型数据库${reset}"
    white "42.${yellow_minute}overseerr${reset}-${green_minute}管理Radarr-Sonarr-PLEX媒体库的请求${reset}"
    white "43.${yellow_minute}piwigo${reset}-${green_minute}图册，只能导入不能扫本地${reset}"
    white "44.${yellow_minute}plex${reset}-${green_minute}扫库刮削速度飞快的私人媒体库${reset}"
    white "45.${yellow_minute}prowlarr-${green_minute}动漫资源搜刮器${reset}"
    white "46.${yellow_minute}qbittorrent${reset}-${green_minute}适合刷流下载的BT工具${reset}"
    white "47.${yellow_minute}radarr${reset}-${green_minute}电影搜刮器${reset}"
    white "48.${yellow_minute}sonarr${reset}-${green_minute}剧集搜刮器${reset}"
    white "49.${yellow_minute}transmission${reset}-${green_minute}适合挂机保种的BT工具${reset}"
    white "50.${yellow_minute}lovechen-embyserver${reset}-${green_minute}emby开心版${reset}"
    white "51.${yellow_minute}bazarr${reset}-${green_minute}Sonarr和Radarr的配套应用${reset}"
    white "52.${yellow_minute}lskypro${reset}-${green_minute}兰空图床${reset}"
    white "53.${yellow_minute}lucky${reset}-${green_minute}集ddns+反代+ssl申请+端口转发+其他为一体${reset}"
    white "54.${yellow_minute}memos${reset}-${green_minute}备忘录(可选mysql数据库)${reset}"
    white "55.${yellow_minute}minio${reset}-${green_minute}对象存储${reset}"
    white "56.${yellow_minute}moviepilot-${green_minute}PT媒体库自动化整理${reset}"
    white "57.${yellow_minute}mt-photos+ai+deepface${reset}-${green_minute}diynas相册最佳选择${reset}"
    white "58.${yellow_minute}mysll-ps-offline${reset}-${green_minute}在线PS工具photopea${reset}"
    white "59.${yellow_minute}navidrome & lyricapi${reset}-${green_minute}在线音乐媒体库&歌词和封面API程序${reset}"
    white "60.${yellow_minute}nginxWebUI${reset}-${green_minute}带webui管理的nginx${reset}"
    white "61.${yellow_minute}nyanmisaka-jellyfin${reset}-${green_minute}硬件转码最强的JF媒体库${reset}"
    white "62.${yellow_minute}ollama${reset}-${green_minute}本地运行大型语言模型框架${reset}"
    white "63.${yellow_minute}kkfileview${reset}-${green_minute}多种格式文件在线预览${reset}"
    white "64.${yellow_minute}pixman${reset}-${green_minute}IPTV直播源${reset}"
    white "65.${yellow_minute}postgresql${reset}-${green_minute}16-大象数据库，对象-关系数据库${reset}"
    white "66.${yellow_minute}pt-helper${reset}-${green_minute}PT小助手，刷流签到全自动${reset}"
    white "67.${yellow_minute}qdtoday${reset}-${green_minute}qd-自动化签到管理框架${reset}"
    white "68.${yellow_minute}qinglong${reset}-${green_minute}青龙面板${reset}"
    white "69.${yellow_minute}redis${reset}-${green_minute}关系型数据库${reset}"
    white "70.${yellow_minute}siyuan-note${reset}-${green_minute}思源笔记${reset}"
    white "71.${yellow_minute}stirling-pdf${reset}-${green_minute}PDF在线工具箱${reset}"
    white "72.${yellow_minute}sun-panel${reset}-${green_minute}导航页${reset}"
    white "73.${yellow_minute}syncthing${reset}-${green_minute}开源免费的全平台数据同步神器${reset}"
    white "74.${yellow_minute}synctv${reset}-${green_minute}和朋友一起看视频${reset}"
    white "75.${yellow_minute}tailscale${reset}-${green_minute}异地组网${reset}"
    white "76.${yellow_minute}vaultwarden${reset}-${green_minute}私人密码库${reset}"
    white "77.${yellow_minute}wiznote${reset}-${green_minute}为知笔记${reset}"
    white "78.${yellow_minute}tvhelper-docker${reset}-${green_minute}盒子助手Docker版${reset}"
    white "79.${yellow_minute}notify${reset}-${green_minute}IOS通知推送系统${reset}"
    white "80.${yellow_minute}xarr-rss${reset}-${green_minute}辅助Sonarr实现自动化追番${reset}"
    white "81.${yellow_minute}xiaoya-alist${reset}-${green_minute}小雅alist，具有庞大的网盘挂载资源${reset}"
    white "82.${yellow_minute}xiaoya-tv-box${reset}-${green_minute}tvbox工具，且内置小雅alist${reset}"
    white "83.${yellow_minute}xunlei${reset}-${green_minute}迅雷${reset}"
    white "84.${yellow_minute}iptvchecker${reset}-${green_minute}获取IPTV直播源(含v4v6)${reset}"
    white "85.${yellow_minute}gohttpserver${reset}-${green_minute}HTTP文件分享服务器${reset}"
    white "86.${yellow_minute}changedetection${reset}-${green_minute}网页内容监控、通知${reset}"
    # white "87. "
    # white "88. "
    # white "89. "
    # white "90. "
    # white "91. "
    # white "92. "
    # white "93. "
    # white "94. "
    # white "95. "
    # white "96. "
    # white "97. "
    # white "98. "
    # white "99. "
    # white "100. "
    echo -e "\t"
    white "-. 返回上级菜单"    
    white "0. 退出脚本"
    read -p "请选择服务: " choice
    case $choice in
        1)
            docker_compose_setting "filebrower"
            ;;
        2)
            docker_compose_setting "dockercopilot"
            ;;
        3)
            docker_compose_setting "adminer"
            ;;
        4)
            docker_compose_setting "alist"
            ;;
        5)
            docker_compose_setting "amilys"
            ;;
        6)
            docker_compose_setting "bili_sync_rs"
            ;;
        7)
            docker_compose_setting "webdav"
            ;;
        8)
            docker_compose_setting "clouddrive2"
            ;;
        9)
            docker_compose_setting "cloudflared_web_cf"
            ;;
        10)
            docker_compose_setting "watchtower"
            ;;
        11)
            docker_compose_setting "cookiecloud"
            ;;
        12)
            docker_compose_setting "ddns_go"
            ;;
        13)
            docker_compose_setting "kms"
            ;;
        14)
            docker_compose_setting "dockge"
            ;;
        15)
            docker_compose_setting "grafana"
            ;;
        16)
            docker_compose_setting "squoosh"
            ;;
        17)
            docker_compose_setting "emby"
            ;;
        18)
            docker_compose_setting "filecodebox"
            ;;
        19)
            docker_compose_setting "hedgedoc"
            ;;
        20)
            docker_compose_setting "homarr"
            ;;
        21)
            docker_compose_setting "homepage"
            ;;
        22)
            docker_compose_setting "rustdesk"
            ;;
        23)
            docker_compose_setting "iptv_tool"
            ;;
        24)
            docker_compose_setting "it_tools"
            ;;
        25)
            docker_compose_setting "iyuuplus"
            ;;
        26)
            docker_compose_setting "jellyseerr"
            ;;
        27)
            docker_compose_setting "drawio"
            ;;
        28)
            docker_compose_setting "kodbox"
            ;;
        29)
            docker_compose_setting "libretranslate"
            ;;
        30)
            docker_compose_setting "li_calendar"
            ;;
        31)
            docker_compose_setting "calibre_web"
            ;;
        32)
            docker_compose_setting "duplicati"
            ;;
        33)
            docker_compose_setting "embystat"
            ;;
        34)
            docker_compose_setting "emulatorjs"
            ;;
        35)
            docker_compose_setting "firefox"
            ;;
        36)
            docker_compose_setting "jackett"
            ;;
        37)
            docker_compose_setting "kavita"
            ;;
        38)
            docker_compose_setting "librespeed"
            ;;
        39)
            docker_compose_setting "lidarr"
            ;;
        40)
            docker_compose_setting "lychee"
            ;;
        41)
            docker_compose_setting "mariadb"
            ;;
        42)
            docker_compose_setting "overseerr"
            ;;
        43)
            docker_compose_setting "piwigo"
            ;;
        44)
            docker_compose_setting "plex"
            ;;
        45)
            docker_compose_setting "prowlarr"
            ;;
        46)
            docker_compose_setting "qbittorrent"
            ;;
        47)
            docker_compose_setting "radarr"
            ;;
        48)
            docker_compose_setting "sonarr"
            ;;
        49)
            docker_compose_setting "transmission"
            ;;
        50)
            docker_compose_setting "lovechen"
            ;;
        51)
            docker_compose_setting "bazarr"
            ;;
        52)
            docker_compose_setting "lskypro"
            ;;
        53)
            docker_compose_setting "lucky"
            ;;
        54)
            docker_compose_setting "memos"
            ;;
        55)
            docker_compose_setting "minio"
            ;;
        56)
            docker_compose_setting "moviepilot"
            ;;
        57)
            docker_compose_setting "mt_photos"
            ;;
        58)
            docker_compose_setting "mysll_ps"
            ;;
        59)
            docker_compose_setting "navidrome"
            ;;
        60)
            docker_compose_setting "nginxWebUI"
            ;;
        61)
            docker_compose_setting "nyanmisaka_jellyfin"
            ;;
        62)
            docker_compose_setting "ollama"
            ;;
        63)
            docker_compose_setting "kkfileview"
            ;;
        64)
            docker_compose_setting "pixman"
            ;;
        65)
            docker_compose_setting "postgresql16"
            ;;
        66)
            docker_compose_setting "pt_helper"
            ;;
        67)
            docker_compose_setting "qd"
            ;;
        68)
            docker_compose_setting "qinglong"
            ;;
        69)
            docker_compose_setting "redis"
            ;;
        70)
            docker_compose_setting "siyuan"
            ;;
        71)
            docker_compose_setting "stirling_pdf"
            ;;
        72)
            docker_compose_setting "sun_panel"
            ;;
        73)
            docker_compose_setting "syncthing"
            ;;
        74)
            docker_compose_setting "synctv"
            ;;
        75)
            docker_compose_setting "tailscale"
            ;;
        76)
            docker_compose_setting "vaultwarden"
            ;;
        77)
            docker_compose_setting "wiznote"
            ;;
        78)
            docker_compose_setting "tvhelper"
            ;;
        79)
            docker_compose_setting "notify"
            ;;
        80)
            docker_compose_setting "xarr_rss"
            ;;
        81)
            docker_compose_setting "xiaoya_alist"
            ;;
        82)
            docker_compose_setting "xiaoya_tvbox"
            ;;
        83)
            docker_compose_setting "xunlei"
            ;;
        84)
            docker_compose_setting "iptvchecker"
            ;;
        85)
            docker_compose_setting "gohttpserver"
            ;;
        86)
            docker_compose_setting "changedetection"
            ;;
        # 87)
        #     docker_compose_setting ""
        #     ;;
        # 88)
        #     docker_compose_setting ""
        #     ;;
        # 89)
        #     docker_compose_setting ""
        #     ;;
        # 90)
        #     docker_compose_setting ""
        #     ;;
        # 91)
        #     docker_compose_setting ""
        #     ;;
        # 92)
        #     docker_compose_setting ""
        #     ;;
        # 93)
        #     docker_compose_setting ""
        #     ;;
        # 94)
        #     docker_compose_setting ""
        #     ;;
        # 95)
        #     docker_compose_setting ""
        #     ;;
        # 96)
        #     docker_compose_setting ""
        #     ;;
        # 97)
        #     docker_compose_setting ""
        #     ;;
        # 98)
        #     docker_compose_setting ""
        #     ;;
        # 99)
        #     docker_compose_setting ""
        #     ;;
        # 100)
        #     docker_compose_setting ""
        #     ;;
        0)
            red "退出脚本，感谢使用."
            rm -rf /mnt/docker_compose.sh   #delete
            ;;
        -)
            white "脚本切换中，请等待..."
            rm -rf /mnt/docker_compose.sh    #delete
            wget -q -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
            ;;
        *)
            white "无效的选项，1秒后返回当前菜单，请重新选择有效的选项."
            sleep 1
            docker_compose_choose
            ;;
    esac 
}
################################ docker-compose 配置生成 ################################
docker_compose_setting() {
    compose_name="$1"
    white "选择创建${compose_name}容器配置，请稍候..."
    
    while true; do
        read -p "请输入安装路径（示例：/opt/docker，文件夹后无需输入“/”，默认为示例路径）： " compose_path
        compose_path="${compose_path:-/opt/docker}"
        
        if [[ $compose_path =~ ^/[a-zA-Z0-9/]*$ ]]; then
            break  
        else
            echo -e "${red}输入的路径格式不正确，请正确路径${reset}"
        fi
    done

echo -e "您输入的安装路径为：${yellow}${compose_path}${reset}"

    
    # 创建目录，如果失败则退出
    mkdir -p "${compose_path}/${compose_name}" || { 
        red "无法在${compose_path}路径下创建${compose_name}文件夹，请确认有写入权限后运行脚本"
        rm -rf /mnt/docker_compose.sh    #delete        
        exit 1
    }
    
    cd "${compose_path}/${compose_name}"
    
    white "开始生成配置文件..."

    # 下载compose文件
    wget -q -O docker-compose.yaml "https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Configs/docker_compose/${compose_name}.yaml"



    # 检查是否成功下载
    if [ ! -f "docker-compose.yaml" ]; then
        red "未能下载docker-compose文件，请检查网络连接"
        rm -rf /mnt/docker_compose.sh    #delete
        exit 1
    fi
    if [[ "$compose_path" == "/" ]]; then
        show_path="/${compose_name}"
    else
        show_path="${compose_path}/${compose_name}"
    fi

    rm -rf /mnt/docker_compose.sh   #delete
    
    white "=================================================================="
    echo -e "\t\t${compose_name} docker-compose配置生成完成"
    echo -e "\n"
    echo -e "docker-compose配置所在目录为${yellow}${show_path}${reset}"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，请\n调整配置文件后，运行${yellow}docker compose up -d ${reset}命令创建容器。"
    white "=================================================================="
}
################################ 主程序 ################################
docker_compose_choose