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
################################ docker-compose 选择 ################################
docker_compose_choose() {
    clear
    rm -rf /mnt/main_install.sh
    echo "=================================================================="
    echo -e "\t\tDocker-compose配置生成脚本 by 忧郁滴飞叶"
    echo -e "\t\n"
    echo "请选择要生成的容器配置："
    echo "=================================================================="
    echo "1. filebrower-文件管理器，荒野无灯大佬版（增强版）"
    echo "2. dockercopilot-docker容器批量一键更新(除了个别)"
    echo "3. adminer-数据库管理工具"
    echo "4. alist-网盘聚合挂载神器"
    echo "5. amilys-embyserver-emby开心版"
    echo "6. amtoaer-bili-sync-rs-B站视频收藏夹同步到本地"    
    echo "7. apachewebdav-基于Apache的非常简单的WebDAV服务器"
    echo "8. clouddrive2-挂载网盘到本地虚拟文件"
    echo "9. cloudflared-web-cf可供免费的内网穿透"
    echo "10. watchtower-瞭望塔，自动更新docker容器"
    echo "11. cookiecloud-cookie云备份"
    echo "12. ddns-go-DDNS域名解析"
    echo "13. kms-server-kms激活器"
    echo "14. dockge-轻量级docker管理器，带docker命令行部署转compose"
    echo "15. grafana-enterprise-全面定制面板。观察所有数据"
    echo "16. squoosh-在线图片压缩"
    echo "17. embyserver-综合最强的媒体库(官网版)"
    echo "18. filecodebox-文件快递柜，简洁易用的文件分享平台，无需注册即可匿名分享文件和文本"
    echo "19. hedgedoc-多人协同在线markdown"
    echo "20. homarr-龙虾导航页"
    echo "21. homepage-高度可定制的应用程序仪表板导航页"
    echo "22. rustdesk-aio-远程桌面"
    echo "23. iptv-tool-IPTV工具箱"
    echo "24. it-tools-在线it工具箱"
    echo "25. iyuuplus-dev-集成webui界面、辅种、转移、下载、定时访问URL、动态域名ddns等常用功能，提供完善的插件机制"
    echo "26. jellyseerr-支持PEJ的媒体库选片系统"
    echo "27. jgraph-drawio-思维导图，拓扑图"
    echo "28. kodbox-可道云私有云，支持协同办公"
    echo "29. libretranslate-翻译"
    echo "30. li-calendar-日历记事本"
    echo "31. calibre-web-电子书库"
    echo "32. duplicati-开源、可加密、压缩、增量备份的跨平台数据备份工具"
    echo "33. embystat-emby&jf的数据统计"
    echo "34. emulatorjs-在线掌机模拟器"
    echo "35. firefox-火狐浏览器"
    echo "36. jackett-站点索引器"
    echo "37. kavita-电子书库"
    echo "38. librespeed-轻量级的测速工具"
    echo "39. lidarr-音乐收藏管理器"
    echo "40. lychee-图册，只能导入不能扫本地"
    echo "41. mariadb-海豚数据库，关系型数据库"
    echo "42. overseerr-管理Radarr-Sonarr-PLEX媒体库的请求"
    echo "43. piwigo-图册，只能导入不能扫本地"
    echo "44. plex-扫库刮削速度飞快的私人媒体库"
    echo "45. prowlarr-动漫资源搜刮器"
    echo "46. qbittorrent-适合刷流下载的BT工具"
    echo "47. radarr-电影搜刮器"
    echo "48. sonarr-剧集搜刮器"
    echo "49. transmission-适合挂机保种的BT工具"
    echo "50. lovechen-embyserver-emby开心版"
    echo "51. bazarr-Sonarr和Radarr的配套应用"
    echo "52. lskypro-兰空图床"
    echo "53. lucky-集ddns+反代+ssl申请+端口转发+其他为一体"
    echo "54. memos-备忘录(可选mysql数据库)"
    echo "55. minio-对象存储"
    echo "56. moviepilot-PT媒体库自动化整理"
    echo "57. mt-photos+ai+deepface-diynas相册最佳选择"
    echo "58. mysll-ps-offline-在线PS工具photopea"
    echo "59. navidrome & lyricapi-在线音乐媒体库&歌词和封面API程序"
    echo "60. nginxWebUI-带webui管理的nginx"
    echo "61. nyanmisaka-jellyfin-硬件转码最强的JF媒体库"
    echo "62. ollama-本地运行大型语言模型框架"
    echo "63. kkfileview-多种格式文件在线预览"
    echo "64. pixman-IPTV直播源"
    echo "65. postgresql-16-大象数据库，对象-关系数据库"
    echo "66. pt-helper-PT小助手，刷流签到全自动"
    echo "67. qdtoday-qd-自动化签到管理框架"
    echo "68. qinglong-青龙面板"
    echo "69. redis-关系型数据库"
    echo "70. siyuan-note-思源笔记"
    echo "71. stirling-pdf-PDF在线工具箱"
    echo "72. sun-panel-导航页"
    echo "73. syncthing-开源免费的全平台数据同步神器"
    echo "74. synctv-和朋友一起看视频"
    echo "75. tailscale-异地组网"
    echo "76. vaultwarden-私人密码库"
    echo "77. wiznote-为知笔记"
    echo "78. tvhelper-docker-盒子助手Docker版"
    echo "79. notify-通知推送系统"
    echo "80. xarr-rss-辅助Sonarr实现自动化追番"
    echo "81. xiaoya-alist-小雅alist，具有庞大的网盘挂载资源"
    echo "82. xiaoya-tv-box-tvbox工具，且内置小雅alist"
    echo "83. xunlei-迅雷"
    echo "84. iptvchecker-获取IPTV直播源(含v4v6)"
    # echo "85. "
    # echo "86. "
    # echo "87. "
    # echo "88. "
    # echo "89. "
    # echo "90. "
    # echo "91. "
    # echo "92. "
    # echo "93. "
    # echo "94. "
    # echo "95. "
    # echo "96. "
    # echo "97. "
    # echo "98. "
    # echo "99. "
    # echo "100. "
    echo -e "\t"
    echo "-. 返回上级菜单"    
    echo "0. 退出脚本"
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
        # 85)
        #     docker_compose_setting ""
        #     ;;
        # 86)
        #     docker_compose_setting ""
        #     ;;
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
    
    echo "=================================================================="
    echo -e "\t\t${compose_name} docker-compose配置生成完成"
    echo -e "\n"
    echo -e "docker-compose配置所在目录为${yellow}${show_path}${reset}"
    echo -e "温馨提示:\n本脚本仅在 ubuntu22.04 环境下测试，其他环境未经验证，请\n调整配置文件后，运行${yellow}docker compose up -d ${reset}命令创建容器。"
    echo "=================================================================="
}
################################ 主程序 ################################
docker_compose_choose