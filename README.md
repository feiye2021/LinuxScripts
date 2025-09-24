# LinuxScripts

Linux自用一键脚本，集成如IP修改、Hostname修改、MosDNS安装及Ui面板安装和Singbox安装等功能，后续随使用**持续更新**，敬请关注

## 特别鸣谢

@ovpavac

@[Myhero_my](https://github.com/52shell/sing-box-mosdns-fakeip)

@Panicpanic

@[FrozenGEE](https://github.com/FrozenGEE/compose)

## AIO脚本

Linux综合脚本，包含基础环境设置、更新及部分软件安装、卸载。

**持续更新中**

### 功能简介

- IP
  - 静态IP修改
  - DHCP
- HostName
- 基础环境设置
  - Update & Upgrade
  - 安装程序依赖
  - 设置时区为Asia/Shanghai
  - 设置NTP为ntp.aliyun.com
  - 关闭53端口监听
  - 一键安装以上所有基础设置
  - 添加/删除SWAP
  - 一键开通SSH登录
- ubuntu/debian 基础命令
  - 启动服务（程序）
  - 停止服务（程序）
  - 重启服务（程序）
  - 查询服务（程序）状态
  - 重新加载配置
  - 一键停止、重加载、重启服务（程序）
  - 查看服务（程序）报错日志
  - 清屏
  - ubuntu/debian 基础命令脚本转快速启动  
- MosDNS
  - 安装Mosdns -- Οὐρανός版 （最新配置:20240930版）
  - 安装Mosdns -- PH版 （最新配置：随PH更新ing）
  - 更新Mosdns -- Οὐρανός版
  - 更新Mosdns -- PH版 （最新配置：随PH更新ing）
  - 卸载Mosdns
- PVE系统
  - 开启硬件直通
  - 虚拟机/LXC容器 解锁
  - img转系统盘
  - LXC容器调用核显
  - 关闭指定虚拟机后开启指定虚拟机
  - ubuntu/debian云镜像创建虚拟机（VM）
    - ubuntu
      - plucky (25.04)
      - oracular (24.10)
      - noble (24.04)
      - jammy (22.04)
      - focal (20.04)
      - bionic (18.04)
    - debian
      - debian 12
  - LXC容器关闭（挂载外部存储使用）
  - PVE系列脚本转快速启动
- Nginx反向代理及企业微信转发
  - Cloudflares 申请证书变量管理 **[重启失效]**
  - 新增Acme证书及Nginx配置 [带安装程序]
  - 新增Acme证书及Nginx配置
  - Nginx 配置校验及重载
  - 删除已申请/安装的 SSL 证书及相关 Nginx 配置
  - 彻底卸载 Acem、Nginx 并清理配置文件
  - 安装 ddclient 执行 DDNS
  - Nginx系列脚本转快速启动
- 智能家居系列
  - 安装FunAsr（本地语音转文字模型）**[硬盘大小需16G以上]**
  - DDNS脚本
    - DnsPod（腾讯云）
  - 自建 HTTP Server 服务 - gohttpserver
  - 自建 HTTP Server gohttpserver功能修改
    - 开启上传功能
    - 开启删除功能
    - 开启登录密码验证
    - 修改WebUI端口
    - 关闭上传功能
    - 关闭删除功能
    - 关闭登录密码验证
    - 修改分享文件所在路径
- Docker
  - 安装docker
  - 安装docker-compose
  - 设定docker日志文件大小
  - 一键安装docker、docker-compose及设定docker日志文件大小
  - 开启docker IPV6
  - 开启docker API - 2375端口
  - 卸载docker
  - 卸载docker-compose
  - 端口占用查询
  - Docker脚本转快速启动
- Docker-Compose配置生成
  - filebrower-文件管理器，荒野无灯大佬版（增强版）
  - dockercopilot-docker容器批量一键更新(除了个别)
  - adminer-数据库管理工具
  - alist-网盘聚合挂载神器
  - amilys-embyserver-emby开心版
  - amtoaer-bili-sync-rs-B站视频收藏夹同步到本地
  - apachewebdav-基于Apache的非常简单的WebDAV服务器
  - clouddrive2-挂载网盘到本地虚拟文件
  - cloudflared-web-cf可供免费的内网穿透
  - watchtower-瞭望塔，自动更新docker容器
  - cookiecloud-cookie云备份
  - ddns-go-DDNS域名解析
  - kms-server-kms激活器
  - dockge-轻量级docker管理器，带docker命令行部署转compose
  - grafana-enterprise-全面定制面板。观察所有数据
  - squoosh-在线图片压缩
  - embyserver-综合最强的媒体库(官网版)
  - filecodebox-文件快递柜，简洁易用的文件分享平台，无需注册即可匿名分享文件和文本
  - hedgedoc-多人协同在线markdown
  - homarr-龙虾导航页
  - homepage-高度可定制的应用程序仪表板导航页
  - rustdesk-aio-远程桌面
  - iptv-tool-IPTV工具箱
  - it-tools-在线it工具箱
  - iyuuplus-dev-集成webui界面、辅种、转移、下载、定时访问URL、动态域名ddns等常用功能，提供完善的插件机制
  - jellyseerr-支持PEJ的媒体库选片系统
  - jgraph-drawio-思维导图，拓扑图
  - kodbox-可道云私有云，支持协同办公
  - libretranslate-翻译
  - li-calendar-日历记事本
  - calibre-web-电子书库
  - duplicati-开源、可加密、压缩、增量备份的跨平台数据备份工具
  - embystat-emby&jf的数据统计
  - emulatorjs-在线掌机模拟器
  - firefox-火狐浏览器
  - jackett-站点索引器
  - kavita-电子书库
  - librespeed-轻量级的测速工具
  - lidarr-音乐收藏管理器
  - lychee-图册，只能导入不能扫本地
  - mariadb-海豚数据库，关系型数据库
  - overseerr-管理Radarr-Sonarr-PLEX媒体库的请求
  - piwigo-图册，只能导入不能扫本地
  - plex-扫库刮削速度飞快的私人媒体库
  - prowlarr-动漫资源搜刮器
  - qbittorrent-适合刷流下载的BT工具
  - radarr-电影搜刮器
  - sonarr-剧集搜刮器
  - transmission-适合挂机保种的BT工具
  - lovechen-embyserver-emby开心版
  - bazarr-Sonarr和Radarr的配套应用
  - lskypro-兰空图床
  - lucky-集ddns+反代+ssl申请+端口转发+其他为一体
  - memos-备忘录(可选mysql数据库)
  - minio-对象存储
  - moviepilot-PT媒体库自动化整理
  - mt-photos+ai+deepface-diynas相册最佳选择
  - mysll-ps-offline-在线PS工具photopea
  - navidrome & lyricapi-在线音乐媒体库&歌词和封面API程序
  - nginxWebUI-带webui管理的nginx
  - nyanmisaka-jellyfin-硬件转码最强的JF媒体库
  - ollama-本地运行大型语言模型框架
  - kkfileview-多种格式文件在线预览
  - pixman-IPTV直播源
  - postgresql-16-大象数据库，对象-关系数据库
  - pt-helper-PT小助手，刷流签到全自动
  - qdtoday-qd-自动化签到管理框架
  - qinglong-青龙面板
  - redis-关系型数据库
  - siyuan-note-思源笔记
  - stirling-pdf-PDF在线工具箱
  - sun-panel-导航页
  - syncthing-开源免费的全平台数据同步神器
  - synctv-和朋友一起看视频
  - tailscale-异地组网
  - vaultwarden-私人密码库
  - wiznote-为知笔记
  - tvhelper-docker-盒子助手Docker版
  - notify-通知推送系统
  - xarr-rss-辅助Sonarr实现自动化追番
  - xiaoya-alist-小雅alist，具有庞大的网盘挂载资源
  - xiaoya-tv-box-tvbox工具，且内置小雅alist
  - xunlei-迅雷
  - iptvchecker-获取IPTV直播源(含v4v6)
  - gohttpserver-HTTP文件分享服务器
  - changedetection-网页内容监控、通知
- Unbound & Redis
  - 一键安装Unbound及Redis
  - 卸载Unbound及Redis
  - 创建/更新快速检查日志脚本
  - 创建/更新快速清理 ubound 和 redis 缓存脚本

### 依赖安装程序安装的依赖有：

---

| 依赖| 依赖| 依赖| 依赖| 依赖| 依赖| 依赖| 依赖|
| ---- | ---- | --------------- | ---------- | ------------ | ---------- | ------------- | -------------- |
| curl | wget | tar             | gawk       | sed          | cron       | unzip         | nano           |
| sudo | vim  | sshfs           | net-tools  | nfs-common   | bind9-host | adduser       | libfontconfig1 |
| git  | jq | p7zip-full |  |  |  |  |                |

---

## 下载使用

```shell
wget --quiet --show-progress -O /mnt/main_install.sh https://raw.githubusercontent.com/feiye2021/LinuxScripts/main/AIO/Scripts/main_install.sh && chmod +x /mnt/main_install.sh && /mnt/main_install.sh
```

## 特别说明


> 脚本部分借鉴[Myhero_my](https://github.com/52shell/sing-box-mosdns-fakeip)大佬脚本，特别鸣谢。
> 
> 配置由ovpavac、Panicpanic两位大佬调教优化，特别鸣谢。
> 
> docker-compose部分出自[FrozenGEE](https://github.com/FrozenGEE/compose)大佬通用库，还有其他仓库，如有需要请移步大佬仓库，特别鸣谢。

